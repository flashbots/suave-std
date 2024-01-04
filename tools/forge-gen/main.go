package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"html/template"
	"os"
	"os/exec"
	"regexp"
	"strings"
)

var applyFlag bool

func main() {
	flag.BoolVar(&applyFlag, "apply", false, "write to file")
	flag.Parse()

	bytecode, err := getForgeWrapperBytecode()
	if err != nil {
		fmt.Printf("failed to get forge wrapper bytecode: %v\n", err)
		os.Exit(1)
	}

	precompileNames, err := getPrecompileNames()
	if err != nil {
		fmt.Printf("failed to get precompile names: %v\n", err)
		os.Exit(1)
	}

	if err := applyTemplate(bytecode, precompileNames); err != nil {
		fmt.Printf("failed to apply template: %v\n", err)
		os.Exit(1)
	}
}

var templateFile = `// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

import "../suavelib/Suave.sol";

interface Vm3 {
    function etch(address, bytes calldata) external;
}

library Suave2 {
    Vm3 constant vm = Vm3(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    function enableLib(address addr) public {
        // code for Wrapper
        bytes memory code =
            hex"{{.Bytecode}}";
        vm.etch(addr, code);
    }

    function enable() public {
		{{range .PrecompileNames}}
		enableLib(Suave.{{.}});
		{{- end}}
    }
}`

func applyTemplate(bytecode string, precompileNames []string) error {
	t, err := template.New("template").Parse(templateFile)
	if err != nil {
		return err
	}

	input := map[string]interface{}{
		"Bytecode":        bytecode,
		"PrecompileNames": precompileNames,
	}

	var outputRaw bytes.Buffer
	if err = t.Execute(&outputRaw, input); err != nil {
		return err
	}

	str := outputRaw.String()
	if str, err = formatSolidity(str); err != nil {
		return err
	}

	if applyFlag {
		if err := os.WriteFile("./src/forge/Wrapper2.sol", []byte(str), 0644); err != nil {
			return err
		}
	} else {
		fmt.Println(str)
	}
	return nil
}

func getForgeWrapperBytecode() (string, error) {
	abiContent, err := os.ReadFile("./out/Wrapper.sol/Wrapper.json")
	if err != nil {
		return "", err
	}

	var abiArtifact struct {
		DeployedBytecode struct {
			Object string
		}
	}
	if err := json.Unmarshal(abiContent, &abiArtifact); err != nil {
		return "", err
	}

	bytecode := abiArtifact.DeployedBytecode.Object[2:]
	return bytecode, nil
}

func getPrecompileNames() ([]string, error) {
	content, err := os.ReadFile("./src/suavelib/Suave.sol")
	if err != nil {
		return nil, err
	}

	addrRegexp := regexp.MustCompile(`constant\s+([A-Za-z_]\w*)\s+=`)

	matches := addrRegexp.FindAllStringSubmatch(string(content), -1)

	names := []string{}
	for _, match := range matches {
		if len(match) > 1 {
			name := strings.TrimSpace(match[1])
			if name == "ANYALLOWED" {
				continue
			}
			names = append(names, name)
		}
	}

	return names, nil
}

func formatSolidity(code string) (string, error) {
	// Check if "forge" command is available in PATH
	_, err := exec.LookPath("forge")
	if err != nil {
		return "", fmt.Errorf("forge command not found in PATH: %v", err)
	}

	// Command and arguments for forge fmt
	command := "forge"
	args := []string{"fmt", "--raw", "-"}

	// Create a command to run the forge fmt command
	cmd := exec.Command(command, args...)

	// Set up input from stdin
	cmd.Stdin = bytes.NewBufferString(code)

	// Set up output buffer
	var outBuf, errBuf bytes.Buffer
	cmd.Stdout = &outBuf
	cmd.Stderr = &errBuf

	// Run the command
	if err = cmd.Run(); err != nil {
		return "", fmt.Errorf("error running command: %v", err)
	}

	return outBuf.String(), nil
}

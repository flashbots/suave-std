package main

import (
	"bytes"
	"flag"
	"fmt"
	"io/fs"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
)

var (
	inputFolder string
	rootFolder  string
)

func main() {
	flag.StringVar(&rootFolder, "root", "./", "root folder of stdchecker")
	flag.Parse()
	args := flag.Args()

	if len(args) != 1 {
		log.Fatal("Usage: stdchecker <suave-std-folder>")
	}

	inputFolder = args[0]

	snippets := readTargets(inputFolder)
	writeSnippets(snippets)

	// use forge to build the snippets
	_, err := execForgeCommand([]string{
		"build",
		"--root", rootFolder,
	})
	if err != nil {
		log.Fatal(err)
	}
}

func writeSnippets(snippets [][]byte) {
	// remove the destination folder first
	if err := os.RemoveAll(filepath.Join(rootFolder, "repo-src")); err != nil {
		log.Fatal(err)
	}

	for indx, snippet := range snippets {
		dst := filepath.Join(rootFolder, fmt.Sprintf("repo-src/snippet_%d.sol", indx))

		abs := filepath.Dir(dst)
		if err := os.MkdirAll(abs, 0755); err != nil {
			log.Fatal(err)
		}

		if err := os.WriteFile(dst, []byte(snippet), 0755); err != nil {
			log.Fatal(err)
		}
	}
}

func readTargets(target string) [][]byte {
	// if the target is a file, read the content and extract the Solidity code blocks
	// if the target is a folder, read all the files in the folder and extract the Solidity code blocks
	info, err := os.Stat(target)
	if err != nil {
		log.Fatal(err)
	}

	markdownFiles := []string{}
	if info.IsDir() {
		filepath.WalkDir(target, func(path string, d fs.DirEntry, err error) error {
			if err != nil {
				log.Fatal(err)
			}
			if d.IsDir() {
				return nil
			}

			if filepath.Ext(path) != ".md" {
				return nil
			}
			markdownFiles = append(markdownFiles, path)
			return nil
		})
	} else {
		markdownFiles = append(markdownFiles, target)
	}

	// Regular expression to match Solidity code blocks
	re := regexp.MustCompile("```solidity\\s+(?s)(.*?)```")

	snippets := [][]byte{}
	for _, file := range markdownFiles {
		content, err := os.ReadFile(file)
		if err != nil {
			log.Fatal(err)
		}

		// Find all matches
		matches := re.FindAllSubmatch(content, -1)

		for _, match := range matches {
			snippet := match[1]
			if bytes.Contains(snippet, []byte("[skip-check]")) {
				// skip if the snippet contains the tag [skip-check]
				continue
			}
			snippets = append(snippets, snippet)
		}
	}

	if len(snippets) == 0 {
		log.Fatal("No Solidity code blocks found in the target")
	}
	log.Printf("Found %d Solidity code blocks", len(snippets))
	return snippets
}

func execForgeCommand(args []string) (string, error) {
	_, err := exec.LookPath("forge")
	if err != nil {
		return "", fmt.Errorf("forge command not found in PATH: %v", err)
	}

	// Create a command to run the forge command
	cmd := exec.Command("forge", args...)

	// Set up output buffer
	var outBuf, errBuf bytes.Buffer
	cmd.Stdout = &outBuf
	cmd.Stderr = &errBuf

	// Run the command
	if err := cmd.Run(); err != nil {
		return "", fmt.Errorf("error running command: %v, %s", err, errBuf.String())
	}

	return outBuf.String(), nil
}

package main

import (
	"encoding/json"
	"fmt"
	"os"
	"strings"
)

func main() {

	data, err := os.ReadFile("./out/Random.sol/Random.json")
	if err != nil {
		panic(err)
	}

	// fmt.Println(string(data))

	var artifact artifact
	if err := json.Unmarshal(data, &artifact); err != nil {
		panic(err)
	}

	artifact.Ast.Walk(func(node *astNode) {
		if node.NodeType != functionDefinitionType {
			return
		}
		if node.Documentation == nil {
			return
		}

		funcDef := functionDef{
			Name:   node.Name,
			Param:  make(map[string]string),
			Return: make(map[string]string),
		}

		lines := strings.Split(node.Documentation.Text, "\n")
		for _, line := range lines {
			line = strings.Trim(line, " ")
			var param string

			if strings.HasPrefix(line, noticePrefix) {
				line = strings.TrimPrefix(line, noticePrefix)
				funcDef.Description = line

			} else if strings.HasPrefix(line, paramPrefix) {
				line = strings.TrimPrefix(line, paramPrefix)
				param, line = getParamVal(line)
				funcDef.Param[param] = line

			} else if strings.HasPrefix(line, returnPrefix) {
				line = strings.TrimPrefix(line, returnPrefix)
				param, line = getParamVal(line)
				funcDef.Return[param] = line
			}
		}

		fmt.Println("-- funcdef --")
		fmt.Println(funcDef)
	})
}

func getParamVal(line string) (string, string) {
	indx := strings.Index(line, " ")
	return line[:indx], line[indx+1:]
}

type contractDef struct {
	Path      string
	Functions []functionDef
}

var (
	noticePrefix = "@notice "
	paramPrefix  = "@param "
	returnPrefix = "@return "
)

type functionDef struct {
	Name        string
	Description string
	Param       map[string]string
	Return      map[string]string
}

var functionDefinitionType = "FunctionDefinition"

type artifact struct {
	Ast *astNode `json:"ast"`
}

type astNode struct {
	AbsolutePath  string
	Name          string
	NodeType      string
	Nodes         []astNode
	Documentation *struct {
		Text string
	}
}

func (a *astNode) Walk(handle func(*astNode)) {
	handle(a)
	for _, node := range a.Nodes {
		node.Walk(handle)
	}
}

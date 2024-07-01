package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"html/template"
	"io/fs"
	"log"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"unicode"

	"github.com/Kunde21/markdownfmt/v3"
	"github.com/Kunde21/markdownfmt/v3/markdown"
)

var (
	suaveStdPath string
	outPath      string
)

func main() {
	flag.StringVar(&suaveStdPath, "suave-std", "./suave-std", "path to the suave std")
	flag.StringVar(&outPath, "out", "./suave-std-gen", "path to the output")
	flag.Parse()

	// read all the artifacts
	artifacts, err := readForgeArtifacts(filepath.Join(suaveStdPath, "out"))
	if err != nil {
		log.Fatal(err)
	}

	// parse the artifacts
	contractDefs := []*ContractDef{}
	for _, artifact := range artifacts {
		contractDef, err := parseArtifact(artifact)
		if err != nil {
			log.Fatal(err)
		}
		contractDefs = append(contractDefs, contractDef...)
	}

	/*
		data, err := json.Marshal(contractDefs)
		if err != nil {
			panic(err)
		}
		fmt.Println(string(data))
	*/

	log.Printf("Writing documentation to to %s", outPath)

	// apply the template and write the docs
	for _, contract := range contractDefs {
		if err := applyTemplate(contractDefs, contract); err != nil {
			log.Fatal(err)
		}
	}
}

func applyTemplate(all []*ContractDef, contract *ContractDef) error {
	curPath := filepath.Dir(contract.Path)

	funcMap := template.FuncMap{
		"desc": func(s string) string {
			// uppercase the fist letter in the string
			chars := []rune(s)

			// Check if the first character is a letter
			if len(chars) > 0 && unicode.IsLetter(chars[0]) {
				// Capitalize the first letter
				chars[0] = unicode.ToUpper(chars[0])
			}

			s = string(chars)

			// if the last character is not a period, add one
			if !strings.HasSuffix(s, ".") {
				s += "."
			}
			return s
		},
		"quote": func(s string) string {
			return fmt.Sprintf("`%s`", s)
		},
		"type": func(s *Field) string {
			if s.TypeReference == 0 {
				// basic type with quotes
				return fmt.Sprintf("`%s`", s.Type)
			}

			// find the reference type
			for _, contract := range all {
				for _, structRef := range contract.Structs {
					if structRef.ID == s.TypeReference {

						dstPath := filepath.Dir(contract.Path)
						dstFile := filepath.Base(contract.Path)

						// try to add a link to the struct
						rel, err := filepath.Rel(curPath, dstPath)
						if err != nil {
							panic(err)
						}

						anchorName := strings.ToLower(structRef.Name)

						var link string
						if rel == "." {
							// same file, just create the reference
							link = fmt.Sprintf("[%s](#%s)", structRef.Name, anchorName)
						} else {
							link = fmt.Sprintf("[%s](%s#%s)", structRef.Name, filepath.Join(rel, dstFile), anchorName)
						}

						return link
					}
				}
			}

			log.Printf("Link for type not found: %s", s.Type)
			return fmt.Sprintf("`%s`", s.Type)
		},
	}
	t, err := template.New("template").Funcs(funcMap).Parse(docsTemplate)
	if err != nil {
		return err
	}
	var outputRaw bytes.Buffer
	if err = t.Execute(&outputRaw, contract); err != nil {
		return err
	}

	output := outputRaw.String()
	output = strings.Replace(output, "&#34;", "\"", -1)

	// format output
	outputB, err := markdownfmt.Process("", []byte(output), markdown.WithSoftWraps())
	if err != nil {
		return err
	}
	output = string(outputB)
	output = strings.Replace(output, "&#39;", "'", -1)

	// get the relative path with respect to src
	relPath := strings.TrimPrefix(contract.Path, "src/")
	dstPath := filepath.Join(outPath, relPath)
	dstPath = strings.Replace(dstPath, ".sol", ".mdx", -1)

	// create any intermediate dirs
	dir := filepath.Dir(dstPath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return err
	}
	if err := os.WriteFile(dstPath, []byte(output), 0755); err != nil {
		return err
	}

	return nil
}

var docsTemplate = `
# {{.Name}}

{{desc .Description}}
{{$Path := .Path}}

## Functions

{{range .Functions}}
### [{{.Name}}](https://github.com/flashbots/suave-std/tree/main/{{$Path}}#L{{.Pos.FromLine}})

{{desc .Description}}

{{ if ne (len .Input) 0 -}}
Input:
{{range .Input}}
- {{quote .Name}} ({{type .}}): {{desc .Description}}
{{end}}
{{end}}

{{ if ne (len .Output) 0 -}}
Output:
{{range .Output}}
- {{quote .Name}} ({{type .}}): {{desc .Description}}
{{end}}
{{end}}

{{end}}

{{ if ne (len .Structs) 0 -}}
## Structs

{{range .Structs}}
### [{{.Name}}](https://github.com/flashbots/suave-std/tree/main/{{$Path}}#L{{.Pos.FromLine}})

{{desc .Description}}

{{range .Fields}}
- {{quote .Name}} ({{type .}}): {{desc .Description}}
{{- end}}
{{end}}

{{end}}
`

type ContractDef struct {
	Name        string        `json:"name"`
	Path        string        `json:"path"`
	Kind        string        `json:"kind"`
	Examples    string        `json:"examples"`
	Description string        `json:"description"`
	Structs     []StructRef   `json:"structs"`
	Functions   []FunctionDef `json:"functions"`
}

type StructRef struct {
	ID          uint64   `json:"id"`
	Name        string   `json:"name"`
	Pos         *Pos     `json:"pos"`
	Description string   `json:"description"`
	Fields      []*Field `json:"fields"`
}

type FunctionDef struct {
	Name        string   `json:"name"`
	Pos         *Pos     `json:"pos"`
	Description string   `json:"description"`
	Input       []*Field `json:"input,omitempty"`
	Output      []*Field `json:"output,omitempty"`
	IsModifier  bool     `json:"is_modifier,omitempty"`
}

type Field struct {
	Name          string `json:"name"`
	Description   string `json:"description"`
	Type          string `json:"type,omitempty"`
	TypeReference uint64 `json:"type-reference,omitempty"`
}

var (
	functionDefinitionType = "FunctionDefinition"
	contractDefinitionType = "ContractDefinition"
	modifierDefinitionType = "ModifierDefinition"
)

func readForgeArtifacts(path string) ([]*artifact, error) {
	// validate that the path exists
	if _, err := os.Stat(path); err != nil {
		return nil, err
	}

	artifacts := []*artifact{}
	err := filepath.WalkDir(path, func(path string, d fs.DirEntry, _ error) error {
		if d.IsDir() {
			return nil
		}

		// ignore if parent directory doesn't end w/ ".sol"
		parentDir := filepath.Base(filepath.Dir(path))
		if !strings.HasSuffix(parentDir, ".sol") {
			return nil
		}

		ext := filepath.Ext(d.Name())
		if ext != ".json" {
			return nil
		}

		content, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		var artifact artifact
		if err := json.Unmarshal(content, &artifact); err != nil {
			return err
		}

		// skip artifacts not in the 'src' repo
		if !strings.HasPrefix(artifact.Ast.AbsolutePath, "src/") {
			return nil
		}

		artifacts = append(artifacts, &artifact)
		return nil
	})

	return artifacts, err
}

type artifact struct {
	Ast *astNode `json:"ast"`
}

type astNode struct {
	ID            uint64
	AbsolutePath  string
	Src           string
	Name          string
	NodeType      string
	Nodes         []astNode
	ContractKind  string
	Kind          string
	Documentation *struct {
		Text string
	}
	Members               []*astNode
	TypeName              *astNode
	ReturnParameters      *astNode
	Parameters            json.RawMessage
	ReferencedDeclaration uint64
	PathNode              *astNode
}

func (a *astNode) hasDocs() bool {
	return a.Documentation != nil && a.Documentation.Text != ""
}

func (a *astNode) Walk(handle func(*astNode)) {
	handle(a)
	for _, node := range a.Nodes {
		node.Walk(handle)
	}
}

func (a *astNode) Filter(check func(*astNode) bool) []*astNode {
	res := []*astNode{}
	a.Walk(func(b *astNode) {
		bb := new(astNode)
		*bb = *b

		if check(bb) {
			res = append(res, bb)
		}
	})
	return res
}

func parseArtifact(artifact *artifact) ([]*ContractDef, error) {
	// first find the contracts that have docs attached
	contractsWithDocs := artifact.Ast.Filter(func(node *astNode) bool {
		return node.NodeType == contractDefinitionType && node.hasDocs()
	})

	sourceUnit, err := newSourceUnit(filepath.Join(suaveStdPath, artifact.Ast.AbsolutePath))
	if err != nil {
		return nil, err
	}

	contractDecls := []*ContractDef{}

	// for each contract, find the functions with comments
	for _, contract := range contractsWithDocs {
		if contract.Name == "RLPWriter" {
			continue
		}

		contractDecl := &ContractDef{
			Path:    artifact.Ast.AbsolutePath, // FIX; now only one contract per source unit
			Name:    contract.Name,
			Kind:    contract.ContractKind,
			Structs: []StructRef{},
		}

		/*
			// check if there is any example in the /examples folder
			examplePath := "examples/" + strings.TrimPrefix(artifact.Ast.AbsolutePath, "src/")
			examplePath = strings.Replace(examplePath, ".sol", ".txt", -1)

			if info, err := os.Stat(examplePath); err == nil && !info.IsDir() {
				content, err := os.ReadFile(examplePath)
				if err != nil {
					return nil, err
				}
				contractDecl.Examples = string(content)
			}
		*/

		// Decode structs
		astStructs := contract.Filter(func(node *astNode) bool {
			return node.NodeType == "StructDefinition" && node.hasDocs()
		})
		for _, s := range astStructs {
			structNat, err := parseNatSpec(s.Documentation.Text)
			if err != nil {
				return nil, err
			}

			pos, err := sourceUnit.Decode(s.Src)
			if err != nil {
				return nil, err
			}
			structRef := StructRef{
				ID:          s.ID,
				Name:        s.Name,
				Pos:         pos,
				Description: structNat.Description,
			}

			{
				// fill out the types
				fields, err := fillSpecTypes(structNat.Param, s.Members)
				if err != nil {
					return nil, fmt.Errorf("failed to parse %s struct %s: %v", contract.Name, s.Name, err)
				}
				structRef.Fields = fields
			}

			contractDecl.Structs = append(contractDecl.Structs, structRef)
		}

		// Decode contract natspec
		contractNatSpec, err := parseNatSpec(contract.Documentation.Text)
		if err != nil {
			return nil, fmt.Errorf("failed to parse natspec for contract '%s': %v", contract.Name, err)
		}
		contractDecl.Description = contractNatSpec.Description

		astFuncs := contract.Filter(func(node *astNode) bool {
			return (node.NodeType == functionDefinitionType || node.NodeType == modifierDefinitionType) && node.hasDocs()
		})

		for _, astFunc := range astFuncs {
			natSpec, err := parseNatSpec(astFunc.Documentation.Text)
			if err != nil {
				return nil, fmt.Errorf("failed to parse function natspec: contract='%s', function='%s': %v", contract.Name, astFunc.Name, err)
			}

			pos, err := sourceUnit.Decode(astFunc.Src)
			if err != nil {
				return nil, err
			}

			funcName := astFunc.Name
			if astFunc.Kind == "constructor" {
				funcName = "constructor"
			}
			funcDecl := FunctionDef{
				Name:        funcName,
				Description: natSpec.Description,
				Pos:         pos,
				IsModifier:  astFunc.NodeType == modifierDefinitionType,
			}

			// Inputs
			{
				var inputParams struct {
					Parameters []*astNode
				}
				if err := json.Unmarshal(astFunc.Parameters, &inputParams); err != nil {
					return nil, err
				}
				fields, err := fillSpecTypes(natSpec.Param, inputParams.Parameters)
				if err != nil {
					return nil, err
				}
				funcDecl.Input = fields
			}

			// Output only if not a modifier
			if astFunc.NodeType == functionDefinitionType {
				var astOutputs []*astNode
				if err := json.Unmarshal(astFunc.ReturnParameters.Parameters, &astOutputs); err != nil {
					return nil, err
				}
				fields, err := fillSpecTypes(natSpec.Return, astOutputs)
				if err != nil {
					return nil, fmt.Errorf("failed to parse %s function %s: %v", contract.Name, astFunc.Name, err)
				}
				funcDecl.Output = fields
			}

			contractDecl.Functions = append(contractDecl.Functions, funcDecl)
		}
		contractDecls = append(contractDecls, contractDecl)
	}

	return contractDecls, nil
}

func fillSpecTypes(natValues []natSpecValue, astValues []*astNode) ([]*Field, error) {
	if len(natValues) != len(astValues) {
		return nil, fmt.Errorf("incorrect size?")
	}

	fields := []*Field{}
	for indx, val := range natValues {
		astVal := astValues[indx]

		// validate that they have the same name if there is any in the ast
		if astVal.Name != "" {
			if astVal.Name != val.Name {
				return nil, fmt.Errorf("error 2")
			}
		}

		field := &Field{
			Name:        val.Name,
			Description: val.Description,
		}

		if astVal.TypeName.NodeType == "ElementaryTypeName" {
			// just append the type
			field.Type = astVal.TypeName.Name
		} else if astVal.TypeName.NodeType == "UserDefinedTypeName" {
			// find the resource reference.... it is the same!
			field.TypeReference = astVal.TypeName.ReferencedDeclaration
			field.Type = astVal.TypeName.PathNode.Name
		} else if astVal.TypeName.NodeType == "ArrayTypeName" {
			// TODO: Fix
			field.Type = astVal.TypeName.Name
		} else {
			return nil, fmt.Errorf("not found %s", astVal.TypeName.NodeType)
		}

		fields = append(fields, field)
	}

	return fields, nil
}

type natSpec struct {
	Description string
	Param       []natSpecValue
	Return      []natSpecValue
}

type natSpecValue struct {
	Name, Description string
}

func parseNatSpec(txt string) (*natSpec, error) {
	spec := &natSpec{
		Param:  []natSpecValue{},
		Return: []natSpecValue{},
	}

	lines := strings.Split(txt, "\n")
	for _, line := range lines {
		line = strings.Trim(line, " ")

		if !strings.HasPrefix(line, "@") {
			return nil, fmt.Errorf("no @ found at the beginning of natspec")
		}

		consumeNextWord := func() (string, bool) {
			whitespaceIndx := strings.Index(line, " ")
			if whitespaceIndx == -1 {
				return "", false
			}

			word := line[:whitespaceIndx]
			line = line[whitespaceIndx+1:]

			return word, true
		}

		natspecPrefix, ok := consumeNextWord()
		if !ok {
			return nil, fmt.Errorf("bad 1")
		}

		if natspecPrefix == "@notice" {
			spec.Description = line
		} else if natspecPrefix == "@param" || natspecPrefix == "@return" {
			valName, ok := consumeNextWord()
			if !ok {
				return nil, fmt.Errorf("bad 2")
			}

			val := natSpecValue{
				Name:        valName,
				Description: line,
			}
			if natspecPrefix == "@param" {
				spec.Param = append(spec.Param, val)
			} else {
				spec.Return = append(spec.Return, val)
			}
		}
	}

	return spec, nil
}

type sourceUnit struct {
	Lines []string
}

func newSourceUnit(path string) (*sourceUnit, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}

	lines := strings.Split(string(data), "\n")
	return &sourceUnit{Lines: lines}, nil
}

type Pos struct {
	FromLine uint64 `json:"from_line"`
	ToLine   uint64 `json:"to_line"`
}

func (s *sourceUnit) Decode(position string) (*Pos, error) {
	// position comes in the format <offset><length><something else?>
	parts := strings.Split(position, ":")
	if len(parts) != 3 {
		return nil, fmt.Errorf("pos format not expected %s", position)
	}

	offset, err := strconv.Atoi(parts[0])
	if err != nil {
		return nil, fmt.Errorf("failed to parse int '%s': %v", parts[0], err)
	}
	length, err := strconv.Atoi(parts[1])
	if err != nil {
		return nil, fmt.Errorf("failed to parse int '%s': %v", parts[1], err)
	}

	from := s.FindLineCol(uint64(offset))
	to := s.FindLineCol(uint64(offset + length))

	return &Pos{FromLine: from, ToLine: to}, nil
}

func (s *sourceUnit) FindLineCol(pos uint64) uint64 {
	var line, count uint64
	for line = 0; line < uint64(len(s.Lines)); line++ {
		count += uint64(len(s.Lines[line])) + 1

		if pos <= count {
			return line + 1
		}
	}
	return 0
}

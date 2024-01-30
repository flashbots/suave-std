package main

import (
	"bytes"
	"flag"
	"fmt"
	"log"
	"os"
	"os/exec"
	"regexp"
	"strings"
	"text/template"
	"text/template/parse"

	"github.com/BurntSushi/toml"
	"github.com/umbracle/ethgo/abi"
	"golang.org/x/text/cases"
	"golang.org/x/text/language"
)

type Config struct {
	ContractName string                 `toml:"contract_name"`
	Structs      map[string]structDef   `toml:"structs"`
	Funcs        map[string]functionDef `toml:"functions"`
}

type structDef struct {
	Type string `toml:"type"`
}

type functionDef struct {
	Template string   `toml:"template"`
	Inputs   []string `toml:"inputs"`
}

var (
	outputPathFlag string
	formatFlag     bool
)

func main() {
	flag.StringVar(&outputPathFlag, "output", "", "output path")
	flag.BoolVar(&formatFlag, "format", false, "whether to format the output")
	flag.Parse()

	if outputPathFlag != "" {
		// always format if we write to file
		formatFlag = true
	}

	args := flag.Args()
	if len(args) != 1 {
		log.Fatal("usage: <config.toml>")
	}

	tomlData, err := os.ReadFile(args[0])
	if err != nil {
		log.Fatal(fmt.Errorf("error reading file '%s': %v", args[0], err))
	}

	var conf Config
	if _, err := toml.Decode(string(tomlData), &conf); err != nil {
		log.Fatal(fmt.Errorf("error parsing toml file '%s': %v", args[0], err))
	}

	s := state{}
	str, err := s.Execute(&conf)
	if err != nil {
		log.Fatal(err)
	}

	if formatFlag {
		var err error
		if str, err = formatSolidity(str); err != nil {
			log.Fatal(fmt.Errorf("error formatting solidity code: %v", err))
		}
	}
	if outputPathFlag != "" {
		if err := os.WriteFile(outputPathFlag, []byte(str), 0755); err != nil {
			log.Fatal(fmt.Errorf("error writing file '%s': %v", outputPathFlag, err))
		}
	} else {
		fmt.Println(str)
	}
}

type state struct {
	config      *Config
	Structs     []string
	EncodeFuncs map[string]string
}

func (s *state) Execute(cfg *Config) (string, error) {
	s.config = cfg
	s.Structs = []string{}
	s.EncodeFuncs = map[string]string{}

	// Encode the structs
	for name, def := range cfg.Structs {
		typ := abi.MustNewType(def.Type)
		s.encodeStruct(name, typ)
	}

	// Generate the encode functions
	for name, fn := range cfg.Funcs {
		if len(fn.Inputs) == 0 {
			continue
		}

		// Take the types of all the inputs for the function and create a tuple
		// with named arguments for all the types. For example, if the function is:
		// func (a uint, b string) then the tuple will be tuple(uint a, string b).
		// We render the string and let abi.NewType parse it.
		allTypes := []string{}
		for indx, name := range fn.Inputs {
			allTypes = append(allTypes, cfg.Structs[name].Type+" "+fmt.Sprintf("obj%d", indx))
		}

		funcType, err := abi.NewType("tuple(" + strings.Join(allTypes, ",") + ")")
		if err != nil {
			return "", fmt.Errorf("invalid type: %v", err)
		}

		encodeFunc := encodeFuncState{}
		s.EncodeFuncs[name] = encodeFunc.Execute(funcType, fn.Template)
	}

	// Generate the decode functions
	for name, fn := range cfg.Funcs {
		fmt.Println(name, fn)
	}

	str := s.Render()
	return str, nil
}

var encodeContractTemplate = `// SPDX-License-Identifier: UNLICENSED
// DO NOT edit this file. Code generated by template-json.
pragma solidity ^0.8.8;

import "solady/src/utils/LibString.sol";

library {{.Config.ContractName}} {
	{{range .Structs}}
	{{.}}
	{{end}}

	{{ $funcs := .EncodeFuncs}}
	{{ range $key, $value := .Config.Funcs}}
	function {{ $key }}(
		{{range $indx, $input := $value.Inputs}}
		{{ $input }} memory obj{{ $indx }},
		{{end}}
	) internal pure returns (bytes memory) {
		bytes memory body;
		{{index $funcs $key}}
		return body;
	}
	{{end}}
}`

func (s *state) Render() string {
	t, err := template.New("template").Parse(encodeContractTemplate)
	if err != nil {
		panic(err)
	}

	inputs := map[string]interface{}{
		"Structs":     s.Structs,
		"EncodeFuncs": s.EncodeFuncs,
		"Config":      s.config,
	}

	var outputRaw bytes.Buffer
	if err = t.Execute(&outputRaw, inputs); err != nil {
		panic(err)
	}

	str := outputRaw.String()
	return str
}

var funcMap = template.FuncMap{
	"toHexString": func(typ *refType) string {
		return "LibString.toHexString(" + typ.name + ")"
	},
	"toString": func(typ *refType) string {
		return "LibString.toString(" + typ.name + ")"
	},
}

type encodeFuncState struct {
	res []*blob
}

// we store the code to be generated in a list of blob statements.
// There are two different types of blobs.
// - encodes: the JSON template to be rendered by Solidity. It will be rendered
// with the 'abi.encodePacked' function. We merge the encode statements together
// under the same blob to reduce the number of calls to 'abi.encodePacked'.
// - stmt: pure Solidity statements (i.e. if, for, etc)
type blob struct {
	encodes []string
	stmt    string
}

func (b *blob) isStmt() bool {
	return b.stmt != ""
}

func (s *encodeFuncState) result() string {
	res := []string{}

	for _, b := range s.res {
		if b.isStmt() {
			res = append(res, b.stmt)
		} else {
			res = append(res, "body = abi.encodePacked(body, "+strings.Join(b.encodes, ",")+");")
		}
	}

	return strings.Join(res, "\n")
}

func (s *encodeFuncState) addBlob(str string) {
	// merge blob in the previous entry if not an statement
	createEntry := true
	size := len(s.res)
	if size > 0 && !s.res[size-1].isStmt() {
		createEntry = false
	}
	if createEntry {
		s.res = append(s.res, &blob{
			encodes: []string{str},
		})
	} else {
		blob := s.res[size-1]
		blob.encodes = append(blob.encodes, str)
	}
}

func (s *encodeFuncState) addStmt(str string) {
	s.res = append(s.res, &blob{stmt: str})
}

var whitespaceRemoveRegexp = regexp.MustCompile(`("[^"]*")|\s+`)

// fullTrimString removes all the tabs, new lines, carriage returns
// and whitespaces that are not part of json values.
func fullTrimString(str string) string {
	str = strings.TrimSpace(str)
	str = strings.ReplaceAll(str, "\n", "")
	str = strings.ReplaceAll(str, "\t", "")
	str = strings.ReplaceAll(str, "\r", "")
	str = whitespaceRemoveRegexp.ReplaceAllString(str, "$1")

	return str
}

func (s *encodeFuncState) Execute(typ *abi.Type, templateStr string) string {
	trees, err := parse.Parse("name", templateStr, "", "", funcMap)
	if err != nil {
		panic(err)
	}
	node := trees["name"].Root

	// body
	s.walk(&refType{Type: typ, name: ""}, node)

	return s.result()
}

// Walk functions step through the major pieces of the template structure,
// generating Solidity output as they go.
func (s *encodeFuncState) walk(typ *refType, node parse.Node) {
	switch node := node.(type) {

	case *parse.IfNode:
		// if statement
		s.walkIfOrWith(typ, node.Pipe, node.List, node.ElseList)

	case *parse.RangeNode:
		// for statement
		s.walkRange(typ, node)

	case *parse.ActionNode:
		// standalone action in the template (i.e. {{.}}) intended
		// to render and encode blob.
		val := s.evalPipeline(typ, node.Pipe)
		s.addBlob(val.name)

	case *parse.ListNode:
		for _, node := range node.Nodes {
			s.walk(typ, node)
		}

	case *parse.TextNode:
		// we send a compact JSON object so be aggresive removing any tabs and new lines.
		if cleanTxt := fullTrimString(string(node.Text)); cleanTxt != "" {
			s.addBlob("'" + cleanTxt + "'")
		}

	default:
		panic(fmt.Sprintf("unknown node: %T", node))
	}
}

func (s *encodeFuncState) walkRange(typ *refType, r *parse.RangeNode) {
	// decode the pipeline to figure out which object we are working on
	// i.e. {{ range .obj.b.c }} would resolve the type of .obj.b.c
	// which must be a slice or an array
	item := s.evalPipeline(typ, r.Pipe)
	if item.Kind() != abi.KindSlice && item.Kind() != abi.KindArray {
		panic("not an array or slice")
	}

	s.addStmt(`for (uint64 i=0; i<` + item.name + `.length; i++) {`)

	// loop over the internal items of the array/slice and render the template
	// Note that we use as the refType.name the full path of the type plus the index
	// in the loop so that the items are referenced as obj[i].a
	s.walk(&refType{Type: item.Type, name: item.name + "[i]"}, r.List)

	// By default and since we know we are rendering a JSON object, we add a comma
	// after each item, except for the last one.
	s.addStmt(`if (i < ` + item.name + `.length-1) {`)
	s.addBlob("','")
	s.addStmt(`}`)

	s.addStmt(`}`)
}

func (s *encodeFuncState) walkIfOrWith(typ *refType, pipe *parse.PipeNode, list, elseList *parse.ListNode) {
	// If statements in Golang templates can render pretty complex statements.
	// However, in order to avoid the complexity and since we are only encoding
	// JSON statements I have decided to simplify the problem and only allow
	// if statements that evaluate to a boolean (== true), a uint (!= 0) or array (length != 0).
	ref := s.evalPipeline(typ, pipe)
	if ref.Type.Kind() == abi.KindUInt {
		s.addStmt(`if (` + ref.name + ` != 0) {`)
	} else if ref.Type.Kind() == abi.KindBool {
		s.addStmt(`if (` + ref.name + `) {`)
	} else if ref.Type.Kind() == abi.KindArray {
		s.addStmt(`if (` + ref.name + `.length > 0) {`)
	} else {
		panic("unknown if condition")
	}

	// body of the if statement
	s.walk(typ, list)

	if elseList == nil {
		// no else statement, just close the if
		s.addStmt(`}`)
	} else {
		// write else if statement and process process the template
		s.addStmt(`} else {`)
		s.walk(typ, elseList)
		s.addStmt(`}`)
	}
}

// findType finds a nested type (i.a [a, b]) in an ABI struct (i.e. tuple(tuple(b) a))
func findType(typ *refType, idents []string) (*refType, error) {
	for _, iden := range idents {
		if typ.Kind() != abi.KindTuple {
			return nil, fmt.Errorf("not a tuple")
		}

		found := false
		for _, elem := range typ.TupleElems() {
			if elem.Name == iden {

				// on `refType` we return as the name the full path of the type.
				// For example, tuple(a, tuple(b, c) d) will return a.b and a.c
				var fullPathName string
				if typ.name == "" {
					// the root object does not have a name
					fullPathName = elem.Name
				} else {
					fullPathName = typ.name + "." + elem.Name
				}

				typ = &refType{Type: elem.Elem, name: fullPathName}
				found = true
				break
			}
		}
		if !found {
			return nil, fmt.Errorf("field %s not found in %s", iden, typ.name)
		}
	}
	return typ, nil
}

func (s *encodeFuncState) evalPipeline(typ *refType, cmd *parse.PipeNode) *refType {
	for _, cmd := range cmd.Cmds {
		typ = s.evalCommand(typ, cmd)
	}
	return typ
}

func (s *encodeFuncState) evalArg(typ *refType, node parse.Node) *refType {
	switch obj := node.(type) {
	case *parse.FieldNode:
		return s.evalCommand(typ, &parse.CommandNode{
			Args: []parse.Node{node},
		})
	case *parse.DotNode:
		return typ
	default:
		panic(fmt.Sprintf("unknown eval arg type: %T", obj))
	}
}

func (s *encodeFuncState) evalCommand(typ *refType, cmd *parse.CommandNode) *refType {
	firstWord := cmd.Args[0]
	switch obj := firstWord.(type) {
	case *parse.FieldNode:
		// Template node to resolve a nested object {{ .obj.a.b }}
		typ, err := findType(typ, obj.Ident)
		if err != nil {
			panic(err)
		}
		return typ

	case *parse.DotNode:
		// Template node to resolve the object itself {{ . }}
		return typ

	case *parse.IdentifierNode:
		// Template node to resolve a function call {{ toHexString . }}.
		// Right now we only support function calls that take only one argument
		// which is a refType.
		fn, ok := funcMap[obj.Ident]
		if !ok {
			panic(fmt.Sprintf("function %s not found", obj.Ident))
		}

		// resolve the type of the argument (i.e {{.}}, {{.obj}}))
		typ = s.evalArg(typ, cmd.Args[1])

		eFn := fn.(func(typ *refType) string)
		return &refType{name: eFn(typ)}

	default:
		panic(fmt.Sprintf("unknown eval command type: %T", obj))
	}
}

// refType is an extension of the abi.Type object which includes
// the argument name that this type had in the tuple.
// For example: for tuple(a, tuple(b, c) d) the type of a is
// refType{name: "a", Type: ...} and the type of b is
// refType{name: "a.b", Type: ...}
type refType struct {
	name string
	*abi.Type
}

func (s *state) encodeStruct(name string, t *abi.Type) string {
	switch t.Kind() {
	case abi.KindTuple:
		attrs := []string{}
		for _, i := range t.TupleElems() {
			attrs = append(attrs, fmt.Sprintf("%s %s;", s.encodeStruct(i.Name, i.Elem), i.Name))
		}
		structName := cases.Title(language.English).String(name)

		str := fmt.Sprintf("struct %s {\n%s\n}\n", structName, strings.Join(attrs, "\n"))
		s.Structs = append(s.Structs, str)

		return structName

	case abi.KindSlice:
		return fmt.Sprintf("%s[]", s.encodeStruct(name, t.Elem()))

	case abi.KindArray:
		return fmt.Sprintf("%s[%d]", s.encodeStruct(name, t.Elem()), t.Size())

	default:
		return t.String()
	}
}

func formatSolidity(code string) (string, error) {
	return execForgeCommand([]string{"fmt", "--raw", "-"}, code)
}

func execForgeCommand(args []string, stdin string) (string, error) {
	_, err := exec.LookPath("forge")
	if err != nil {
		return "", fmt.Errorf("forge command not found in PATH: %v", err)
	}

	// Create a command to run the forge command
	cmd := exec.Command("forge", args...)

	// Set up input from stdin
	if stdin != "" {
		cmd.Stdin = bytes.NewBufferString(stdin)
	}

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

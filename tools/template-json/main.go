package main

import (
	"fmt"
	"strings"
	"text/template"
	"text/template/parse"

	"github.com/umbracle/ethgo/abi"
)

func xx() {
	rr, _ := template.New("").Parse("")
	rr.Execute(nil, nil)
}

func main() {
	rr, err := abi.NewType(typ)
	if err != nil {
		panic(err)
	}

	trees, err := parse.Parse("name", templateStr, "", "")
	if err != nil {
		panic(err)
	}
	tree := trees["name"]

	s := state{}
	s.encodeStruct("HelloStruct", rr)
	s.Walk("HelloStruct", rr, tree.Root)

	fmt.Println(s.structs[0])
	fmt.Println(s.funcs[0])
}

var typ = `tuple(
	string a, 
	string[] b,
	uint256 c
)`

var templateStr = `{
	"hello": {{.a}},
	"world": "normal",
	"vals": [{{range .b}}
		{{.}}
	{{end}}]
	{{if .c}}
		,"test": {{.c}}
	{{end}}
}
`

type state struct {
	structs []string
	funcs   []string

	// res is a helper method to render the result
	// of encoding functions
	res []*blob
}

type blob struct {
	encodes []string
	stmt    string
}

func (b *blob) isStmt() bool {
	return b.stmt != ""
}

func (s *state) result() string {
	res := []string{}

	//render the string, each statement in a separated line
	for _, b := range s.res {
		if b.isStmt() {
			res = append(res, b.stmt)
		} else {
			res = append(res, "body = abi.encodePacked(body, "+strings.Join(b.encodes, ",")+");")
		}
	}

	return strings.Join(res, "\n")
}

func (s *state) addBlob(str string) {
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

func (s *state) addStmt(str string) {
	s.res = append(s.res, &blob{stmt: str})
}

func fullTrimString(str string) string {
	str = strings.TrimSpace(str)
	str = strings.ReplaceAll(str, "\n", "")
	str = strings.ReplaceAll(str, "\t", "")
	str = strings.ReplaceAll(str, "\r", "")
	return str
}

func (s *state) Walk(structName string, typ *abi.Type, node parse.Node) {
	// creation of the function
	s.addStmt(`function encode(` + structName + ` memory obj) internal pure returns (bytes memory) {`)
	s.addStmt(`bytes memory body;`)

	// body
	s.walk(&refType{Type: typ, name: "obj"}, node)

	// end of the function
	s.addStmt(`return body;`)
	s.addStmt(`}`)

	s.funcs = append(s.funcs, s.result())
	s.res = []*blob{}
}

// Walk functions step through the major pieces of the template structure,
// generating output as they go.
func (s *state) walk(typ *refType, node parse.Node) {
	switch node := node.(type) {
	case *parse.ActionNode:
		// something like {{.name}} in the template
		val := s.evalCommand(typ, node.Pipe.Cmds[0])

		s.addBlob(val.name)

	case *parse.IfNode:
		s.walkIfOrWith(typ, node.Pipe, node.List, node.ElseList)

	case *parse.ListNode:
		for _, node := range node.Nodes {
			s.walk(typ, node)
		}

	case *parse.RangeNode:
		s.walkRange(typ, node)

	case *parse.TextNode:
		txt := fullTrimString(string(node.Text))
		if txt == "" {
			return
		}
		s.addBlob("'" + txt + "'")

	case *parse.BreakNode:
		panic("break statements not supported")

	case *parse.CommentNode:
		panic("comment blocks not supported")

	case *parse.ContinueNode:
		panic("continue statements not supported")

	case *parse.TemplateNode:
		panic("templates not supported")

	case *parse.WithNode:
		panic("C")
	default:
		panic("C")
	}
}

func (s *state) walkRange(typ *refType, r *parse.RangeNode) {
	// write range statement
	item := s.evalCommand(typ, r.Pipe.Cmds[0])
	// item must be an array to work on a range
	if item.Kind() != abi.KindSlice {
		panic("not an array")
	}

	s.addStmt(`for (uint64 i=0; i<` + item.name + `.length; i++) {`)

	// loop over the items
	s.walk(&refType{Type: item.Type, name: item.name + "[i]"}, r.List)

	// add , if not the last item
	s.addStmt(`if (i != ` + item.name + `.length-1) {`)
	s.addBlob("','")
	s.addStmt(`}`)

	s.addStmt(`}`)
}

func (s *state) walkIfOrWith(typ *refType, pipe *parse.PipeNode, list, elseList *parse.ListNode) {
	// write condition
	ref := s.evalCommand(typ, pipe.Cmds[0])
	s.addStmt(`if (` + ref.name + ` != 0) {`)

	// write body of the if statement
	s.walk(typ, list)

	if elseList == nil {
		// no if statement, just close the if
		s.addStmt(`}`)
	} else {
		// write else if statement (if any)
		s.addStmt(`} else {`)
		s.walk(typ, elseList)
		s.addStmt(`}`)
	}
}

func (s *state) evalCommand(typ *refType, cmd *parse.CommandNode) *refType {
	firstWord := cmd.Args[0]
	switch obj := firstWord.(type) {
	case *parse.FieldNode:
		name := obj.Ident[0]
		// figure out if the item is on the typ
		for _, a := range typ.TupleElems() {
			if a.Name == name {
				return &refType{Type: a.Elem, name: typ.name + "." + a.Name}
			}
		}
	case *parse.DotNode:
		return typ

	default:
		panic("not found")
	}

	panic("not found")
}

// refType is a type that is referenced by name.
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
		structName := strings.Title(name)

		str := fmt.Sprintf("struct %s {\n%s\n}\n", structName, strings.Join(attrs, "\n"))
		s.structs = append(s.structs, str)

		return fmt.Sprintf("struct%s", structName)

	case abi.KindSlice:
		return fmt.Sprintf("%s[]", s.encodeStruct(name, t.Elem()))

	case abi.KindArray:
		return fmt.Sprintf("%s[%d]", s.encodeStruct(name, t.Elem()), t.Size())

	default:
		return t.String()
	}
}

package main

import (
	"flag"
	"fmt"
	"io/fs"
	"log"
	"os"
	"path/filepath"
	"regexp"
)

func main() {
	flag.Parse()
	args := flag.Args()

	inputFolder := args[0]
	snippets := readTargets(inputFolder)

	writeSnippets(snippets)
}

func initializeRepo() {
	// write snippets
	// for indx, snippet := range snippets {
	// }
}

func writeSnippets(snippets [][]byte) {
	for indx, snippet := range snippets {
		dst := fmt.Sprintf("../../test/example/snippet_%d.sol", indx)

		abs := filepath.Dir(dst)
		if err := os.MkdirAll(abs, 0755); err != nil {
			log.Fatal(err)
		}

		if err := os.WriteFile(dst, []byte(snippet), 0755); err != nil {
			log.Fatal(err)
		}
	}
}

func writeDestFolder(name string, content []byte) {
	dst := fmt.Sprintf("../../test/example/%s", name)

	abs := filepath.Dir(dst)
	if err := os.MkdirAll(abs, 0755); err != nil {
		log.Fatal(err)
	}

	if err := os.WriteFile(dst, []byte(content), 0755); err != nil {
		log.Fatal(err)
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
			snippets = append(snippets, match[1])
		}
	}
	return snippets
}

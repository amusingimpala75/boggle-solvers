package main

import (
	"fmt"
	"os"
	"slices"
	"strings"
)

type DictEntryMap map[rune] *DictEntry

type DictEntry struct {
	children DictEntryMap
	terminal bool
}

type Dict DictEntryMap

func NewDict() Dict {
	d := make(Dict)
	for ch := 'a'; ch <= 'z'; ch++ {
		d[ch] = nil
	}
	return make(Dict)
}

func (d Dict) Put(word string) {
	runes := []rune(strings.ToUpper(word))
	// Early return for scrabble but non-boggle words
	if len(runes) < 4 {
		return
	}

	ch := runes[0]
	rest := runes[1:]

	if d[ch] == nil {
		d[ch] = NewDictEntry()
	}

	d[ch].Put(rest)
}

func (d Dict) Contains(word string) (bool, bool) {
	runes := []rune(strings.ToUpper(word))

	ch := runes[0]
	rest := runes[1:]

	if d[ch] == nil {
		return false, false
	}

	return d[ch].Contains(rest)
}

func (d Dict) Load(path string) {
	data, err := os.ReadFile(path)
	if err != nil {
		fmt.Println("error loading dictionary")
		os.Exit(1)
	}
	lines := strings.SplitSeq(string(data), "\n")

	for line := range lines {
		d.Put(line)
	}
}

func NewDictEntry() *DictEntry {
	e := new(DictEntry)
	e.terminal = false
	e.children = make(map[rune]*DictEntry)
	for ch := 'a'; ch <= 'z'; ch++ {
		e.children[ch] = nil
	}
	return e
}


func (e *DictEntry) Put(runes []rune) {
	// Return early if this is the final char
	if len(runes) == 0 {
		e.terminal = true
		return
	}

	ch := runes[0]
	rest := runes[1:]

	if e.children[ch] == nil {
		e.children[ch] = NewDictEntry()
	}

	e.children[ch].Put(rest)
}

func (e DictEntry) Contains(runes []rune) (bool, bool) {
	if len(runes) == 0 {
		return e.terminal, true
	}

	ch := runes[0]
	rest := runes[1:]

	if e.children[ch] == nil {
		return false, false
	}

	return e.children[ch].Contains(rest)
}

type Board [5][5]rune

func ReadBoard() Board {
	var b [5][5]rune

	bytes := make([]byte, 6 * 5)
	count, err := os.Stdin.Read(bytes)
	if err != nil || count != 6 * 5 {
		fmt.Println("error reading board")
		os.Exit(1)
	}
	runes := []rune(string(bytes))
	for y := range 5 {
		for x := range 5 {
			b[y][x] = runes[y * 6 + x]
		}
	}

	return b
}

func (b Board) findWords(dict Dict, out chan string) {
	for y := range 5 {
		for x := range 5 {
			positions := make([]Position, 1)
			positions[0] = Position{x, y}
			b.findWordsContinuing(dict, out, positions)
		}
	}
	close(out)
}

type Position struct {x int; y int}

func (b Board) findWordsContinuing(dict Dict, out chan string, positions []Position) {
	current := positions[len(positions) - 1]
	x := current.x
	y := current.y
	for dy := -1; dy <= 1; dy++ {
		y := y + dy
		if y < 0 || y >= 5 {
			continue
		}
		for dx := -1; dx <= 1; dx++ {
			x := x + dx
			if x < 0 || x >= 5 {
				continue
			}
			if x == current.x && y == current.y {
				continue
			}
			newpos := Position{x, y}
			if slices.Contains(positions, newpos) {
				continue
			}
			positions := append(positions, newpos)
			str := b.partialWord(positions)
			if in, prefix := dict.Contains(str); in {
				out <- str
				b.findWordsContinuing(dict, out, positions)
			} else if prefix {
				b.findWordsContinuing(dict, out, positions)
			}
		}
	}
}

func (b Board) partialWord(positions []Position) string {
	runes := make([]rune, len(positions))
	for i, pos := range positions {
		x, y := pos.x, pos.y
		runes[i] = b[y][x]
	}
	return decodeWord(runes)
}

func decodeWord(word []rune) string {
	decoded := make([]rune, 0)

	for _, ch := range word {
		runes := []rune(decodeRune(ch))
		if len(runes) == 1 {
			decoded = append(decoded, runes[0])
		} else {
			decoded = append(decoded, runes[0], runes[1])
		}
	}

	return string(decoded)
}

func decodeRune(ch rune) string {
	switch ch {
	case '1': return "AN"
	case '2': return "ER"
	case '3': return "HE"
	case '4': return "IN"
	case '5': return "QU"
	case '6': return "TH"
	default: return string(ch)
	}
}

func scoreWord(word string) int {
	switch l := len(word); l {
	case 4: return 1
	case 5: return 2
	case 6: return 3
	case 7: return 5
	case 8: return 11
	default:
		if l > 8 {
			return 11
		} else {
			return 0
		}
	}
}

func main() {
	dict := NewDict()
	dict.Load("./dictionary.txt")

	board := ReadBoard()

	fmt.Println("finding words...")
	words := make(chan string)
	go board.findWords(dict, words)

	sorted := make([]string, 0)
	score := 0
	for word := range words {
		if !slices.Contains(sorted, word) {
			sorted = append(sorted, word)
			score += scoreWord(word)
		}
	}

	slices.SortFunc(sorted, func (a string, b string) int {
		if diff := len(a) - len(b); diff != 0 {
			return diff
		}
		return strings.Compare(a, b)
	})

	for _, word := range sorted {
		fmt.Println(word)
	}

	fmt.Println("Word count:", len(sorted))
	fmt.Println("Score:", score)
}

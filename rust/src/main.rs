use std::{cmp::Ordering, collections::HashSet, fs, io};

struct SpellingNode {
    valid: bool,
    children: [Option<Box<SpellingNode>>; 26],
}

impl SpellingNode {
    fn new() -> SpellingNode {
        SpellingNode {
            valid: false,
            children: [const { None }; 26],
        }
    }
}

struct SpellingTrie {
    root: Box<SpellingNode>,
}

impl SpellingTrie {
    fn get_tail_node_for(&self, word: &str) -> Option<&Box<SpellingNode>> {
        let word = word.to_lowercase();
        let mut node = &self.root;
        for c in word.chars() {
            let idx = (c as u8) - b'a';
            let idx: usize = idx.into();

            node = match &node.children[idx] {
                Some(n) => &n,
                None => return None,
            }
        }
        return Some(node);
    }

    fn contains_prefix(&self, word: &str) -> bool {
        return self.get_tail_node_for(word).is_some();
    }

    fn contains_word(&self, word: &str) -> bool {
        if let Some(node) = self.get_tail_node_for(word) {
            node.valid
        } else {
            false
        }
    }

    fn add_word(&mut self, word: &str) {
        let word = word.to_lowercase();
        let mut node = &mut self.root;
        for c in word.chars() {
            let idx = (c as u8) - b'a';
            let idx: usize = idx.into();

            if node.children[idx].is_none() {
                node.children[idx] = Some(Box::new(SpellingNode::new()));
            }

            node = node.children[idx].as_mut().unwrap();
        }
        node.valid = true;
    }

    fn from_dictionary(path: &str) -> SpellingTrie {
        let mut ret = SpellingTrie::new();

        let contents =
            fs::read_to_string(path).expect(&format!("Could not read dictionary at {path}"));
        let lines = contents.lines();

        for line in lines {
            let lcase = line.to_lowercase();
            ret.add_word(&lcase);
        }

        ret
    }

    fn from_vec(words: Vec<&str>) -> SpellingTrie {
        let mut ret = SpellingTrie::new();

        for word in &words {
            ret.add_word(&word);
        }

        ret
    }

    fn new() -> SpellingTrie {
        SpellingTrie {
            root: Box::new(SpellingNode::new()),
        }
    }
}

#[derive(PartialEq)]
struct Point {
    x: usize,
    y: usize,
}

impl Point {
    fn new(x: usize, y: usize) -> Point {
        if x >= 5 || y >= 5 {
            panic!("Points must be in [0,4]")
        }
        Point { x, y }
    }

    fn neighbors(&self) -> Vec<Point> {
        let mut ret = Vec::<Point>::new();

        let start_x = Self::before_bounded(self.x);
        let end_x = Self::after_bounded(self.x);
        let start_y = Self::before_bounded(self.y);
        let end_y = Self::after_bounded(self.y);

        for x in start_x..=end_x {
            for y in start_y..=end_y {
                let pt = Point::new(x, y);
                if pt != *self {
                    ret.push(Point::new(x, y));
                }
            }
        }

        ret
    }

    fn before_bounded(i: usize) -> usize {
        if i == 0 {
            0
        } else {
            i - 1
        }
    }

    fn after_bounded(i: usize) -> usize {
        if i == 4 {
            4
        } else {
            i + 1
        }
    }
}

struct Board {
    // board[x][y]
    letters: [[char; 5]; 5],
}

impl Board {
    // TODO better error handling
    fn from_stdin() -> Option<Board> {
        let mut ret = Board::new();

        let stdin = io::stdin();
        let mut buf = String::new();
        for x in 0..5 {
            buf.clear();
            stdin.read_line(&mut buf).ok()?;
            let buf = buf.trim();

            if buf.chars().count() != 5 {
                return None;
            }

            for (y, c) in buf.chars().enumerate() {
                ret.letters[x][y] = c;
            }
        }

        Some(ret)
    }

    fn valid_words(&self, dict: &SpellingTrie) -> Vec<String> {
        let mut words = HashSet::<String>::new();

        for x in 0..5 {
            for y in 0..5 {
                self.check_path(&dict, &mut vec![Point::new(x, y)], &mut words);
            }
        }

        let mut words: Vec<String> = words.into_iter().collect();
        words.sort_by(|a, b| {
            let length_test = a.len().cmp(&b.len());

            if length_test == Ordering::Equal {
                return a.cmp(&b);
            }

            length_test
        });

        words
    }

    fn check_path(&self, dict: &SpellingTrie, path: &mut Vec<Point>, out: &mut HashSet<String>) {
        let word_here = self.word_at(path);
        if !dict.contains_prefix(&word_here) {
            return;
        } else if word_here.chars().count() >= 4 && dict.contains_word(&word_here) {
            out.insert(word_here);
        }

        let last = path.last().unwrap();
        for neighbor in last.neighbors() {
            if !path.contains(&neighbor) {
                path.push(neighbor);
                self.check_path(dict, path, out);
                path.pop();
            }
        }
    }

    fn word_at(&self, path: &Vec<Point>) -> String {
        let mut ret = String::new();

        for pt in path {
            let c = self.letters[pt.x][pt.y];
            match c {
                '1' => ret.push_str("AN"),
                '2' => ret.push_str("ER"),
                '3' => ret.push_str("HE"),
                '4' => ret.push_str("IN"),
                '5' => ret.push_str("QU"),
                '6' => ret.push_str("TH"),
                n => ret.push(n),
            }
        }

        ret
    }

    fn new() -> Board {
        Board {
            letters: [[' '; 5]; 5],
        }
    }

    fn score(words: Vec<String>) -> usize {
        let mut score = 0;
        for word in words {
            score += Self::score_word(word);
        }

        score
    }

    fn score_word(word: String) -> usize {
        match word.chars().count() {
            4 => 1,
            5 => 2,
            6 => 3,
            7 => 5,
            8 => 11,
            n => {
                if n > 8 {
                    11
                } else {
                    0
                }
            }
        }
    }
}

fn main() {
    let trie = SpellingTrie::from_dictionary("./dictionary.txt");

    let board = Board::from_stdin().expect("Invalid/missing board");

    let words = board.valid_words(&trie);

    for word in &words {
        println!("{word}");
    }

    println!("Word count: {}", words.len());

    let score = Board::score(words);
    println!("Score: {score}");
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn empty() {
        let trie = SpellingTrie::new();

        assert!(!trie.contains_word("hi"));
        assert!(!trie.contains_prefix("hi"));
    }

    #[test]
    fn does_contain_word() {
        let trie = SpellingTrie::from_vec(vec!["hi"]);
        assert!(trie.contains_word("hi"));
    }

    #[test]
    fn does_not_contain_word() {
        let trie = SpellingTrie::from_vec(vec!["hi"]);
        assert!(!trie.contains_word("bye"));
    }

    #[test]
    fn does_contain_prefix() {
        let trie = SpellingTrie::from_vec(vec!["hello"]);
        assert!(trie.contains_prefix("he"));
    }

    #[test]
    fn does_not_contain_prefix() {
        let trie = SpellingTrie::from_vec(vec!["hello"]);
        assert!(!trie.contains_prefix("be"));
    }

    #[test]
    fn does_contain_prefix_equals_word() {
        let trie = SpellingTrie::from_vec(vec!["he"]);
        assert!(trie.contains_prefix("he"));
    }
}

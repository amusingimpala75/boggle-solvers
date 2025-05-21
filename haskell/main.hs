import Data.Char
import Data.List
import Data.Bifunctor

data DictEntry = Terminal [(Char, DictEntry)]
               | Nonterminal [(Char, DictEntry)]
               deriving Show

type Dict = DictEntry

newtype Board = Board [[Char]]
              deriving Show

getBoard :: IO Board
getBoard = Board <$> sequence [getLine, getLine, getLine, getLine, getLine]

readDict :: String -> IO [String]
readDict = fmap lines . readFile

grouper :: String -> String -> Bool
grouper (x:xs) "" = False
grouper "" (x:xs) = False
grouper (x:xs) (y:ys) = y == x

groupByFirstChar :: [String] -> [[String]]
groupByFirstChar = groupBy grouper

tuplifyWords :: [String] -> (Char, [String])
tuplifyWords items@("":(x:xs):ys) = (x, map (drop 1) items)
tuplifyWords items@((x:xs):ys) = (x, map (drop 1) items)

makeDictEntry :: [String] -> DictEntry
makeDictEntry items
  | "" `elem` items = Terminal $ map (second makeDictEntry . tuplifyWords) $ filter (\x -> x /= [""] ) $ groupByFirstChar items
  | otherwise = Nonterminal $ map (second makeDictEntry . tuplifyWords) $ groupByFirstChar items

getDict :: [String] -> Dict
getDict words = Nonterminal $ map (second makeDictEntry . tuplifyWords) $ groupByFirstChar words

dictEntryContains :: DictEntry -> Bool -> String -> Bool
dictEntryContains (Terminal children) _ "" = True
dictEntryContains (Nonterminal _) partial "" = partial
dictEntryContains (Terminal children) partial word = dictMapContains children partial word
dictEntryContains (Nonterminal children) partial word = dictMapContains children partial word

dictMapContains :: [(Char, DictEntry)] -> Bool -> String -> Bool
dictMapContains children partial (x:xs) = let results = filter (\(char, entries) -> char == x) children in not (null results) && dictEntryContains (snd $ head results) partial xs

main = do
  board <- getBoard
  print board

  dict <- getDict <$> readDict "./dictionary.txt"
  print dict

import Data.Char
import Data.List
import Data.Bifunctor
import Data.Ord

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
dictEntryContains (Terminal _) _ "" = True
dictEntryContains (Nonterminal _) partial "" = partial
dictEntryContains (Terminal children) partial word = dictMapContains children partial word
dictEntryContains (Nonterminal children) partial word = dictMapContains children partial word

dictMapContains :: [(Char, DictEntry)] -> Bool -> String -> Bool
dictMapContains children partial (x:xs) = let results = filter (\(char, _) -> char == x) children in not (null results) && dictEntryContains (snd $ head results) partial xs

getConnected :: (Int, Int) -> [(Int, Int)]
getConnected (x, y) = filterBounds [(x + dx, y + dy) | dx <- [-1..1], dy <- [-1..1]]

filterBounds :: [(Int, Int)] -> [(Int, Int)]
filterBounds = filter (\(x, y) -> x `elem` [0..5-1] && y `elem` [0..5-1])

mapChar :: Char -> String
mapChar '1' = "AN"
mapChar '2' = "ER"
mapChar '3' = "HE"
mapChar '4' = "IN"
mapChar '5' = "QU"
mapChar '6' = "TH"
mapChar x = [x]

getCandidate :: Board -> [(Int, Int)] -> String
getCandidate (Board chars) = concatMap (\(x, y) -> mapChar $ chars!!y!!x)

getCandidates :: Dict -> Board -> [(Int, Int)] -> [String]
getCandidates dict board positions@(_:_)
  | not $ dictEntryContains dict True candidate = []
  | otherwise = candidate:concatMap (getCandidates dict board . (:positions)) neighbors
  where neighbors = filter (not . flip elem positions) $ getConnected $ head positions
        candidate = getCandidate board $ reverse positions

getWords :: Dict -> Board -> [String]
getWords dict board = concatMap (getCandidates dict board) [[(x, y)] | x <- [0..5-1], y <- [0..5-1]]

customSort :: String -> String -> Ordering
customSort "" "" = EQ
customSort (_:_) "" = GT
customSort "" (_:_) = LT
customSort a@(x:xs) b@(y:ys) = let cmp = comparing length a b in if cmp /= EQ then cmp else if x /= y then compare x y else customSort xs ys

scoreWord :: Int -> Int
scoreWord 4 = 1
scoreWord 5 = 2
scoreWord 6 = 3
scoreWord 7 = 5
scoreWord x
  | x >= 8 = 11
  | otherwise = 0

main = do
  board <- getBoard
  
  dict <- getDict <$> readDict "./dictionary.txt"

  let words = sortBy customSort $ filter (dictEntryContains dict False) $ filter (\word -> length word >= 4) $ nub $ getWords dict board
      count = length words
      score = sum $ map (scoreWord . length) words in do
    putStr $ unlines words
    putStrLn $ "Word count: " ++ show count
    putStrLn $ "Score: " ++ show score

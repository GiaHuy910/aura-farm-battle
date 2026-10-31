module Game.Random
  ( pickWeighted
  , pickUniform
  , sampleWeighted
  , shuffle
  ) where

import System.Random (StdGen, randomR)

pickWeighted :: StdGen -> [(a, Double)] -> Maybe (a, [(a, Double)], StdGen)
pickWeighted _ [] = Nothing
pickWeighted g xs
  | total <= 0 =  
      let (i, g') = randomR (0, length xs - 1) g
      in Just (fst (xs !! i), removeAt i xs, g')
  | otherwise =
      let (r, g') = randomR (0, total) g
          i       = walk r 0 (map snd xs)
      in Just (fst (xs !! i), removeAt i xs, g')
  where
    total = sum (map (max 0 . snd) xs)
    walk _ i []       = max 0 (i - 1)
    walk r i (w : ws)
      | r <= max 0 w  = i
      | null ws       = i
      | otherwise     = walk (r - max 0 w) (i + 1) ws

removeAt :: Int -> [a] -> [a]
removeAt i xs = take i xs ++ drop (i + 1) xs

pickUniform :: StdGen -> [a] -> Maybe (a, StdGen)
pickUniform _ [] = Nothing
pickUniform g xs =
  let (i, g') = randomR (0, length xs - 1) g
  in Just (xs !! i, g')

sampleWeighted :: StdGen -> Int -> [(a, Double)] -> ([a], StdGen)
sampleWeighted g n xs
  | n <= 0    = ([], g)
  | otherwise = case pickWeighted g xs of
      Nothing             -> ([], g)
      Just (x, rest, g')  ->
        let (ys, g'') = sampleWeighted g' (n - 1) rest
        in (x : ys, g'')

shuffle :: StdGen -> [a] -> ([a], StdGen)
shuffle g xs =
  let (ys, g') = sampleWeighted g (length xs) (map (\x -> (x, 1)) xs)
  in (ys, g')
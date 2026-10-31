module Game.Random
  ( pickWeighted
  , pickUniform
  , sampleWeighted
  , shuffle
  , removeAt
  ) where

import System.Random (StdGen, randomR)

pickWeighted :: StdGen -> [(a, Double)] -> Maybe (a, [(a, Double)], StdGen)
pickWeighted _ [] = Nothing
pickWeighted g xs = case positiveWeights of
  [] -> Nothing
  _  ->
    let (r, g') = randomR (0, total) g
    in case walk r positiveWeights of
         Nothing -> Nothing
         Just i  -> Just (fst (xs !! i), removeAt i xs, g')
  where
    positiveWeights = [(i, w) | (i, (_, w)) <- zip [0 ..] xs, w > 0]
    total = sum (map snd positiveWeights)
    walk _ [] = Nothing
    walk _ [(i, _)] = Just i
    walk r ((i, w) : rest)
      | r <= w    = Just i
      | otherwise = walk (r - w) rest

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
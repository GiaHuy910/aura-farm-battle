{-# LANGUAGE OverloadedStrings #-}
module Game.Strategy
  ( decideOrder
  , ownerWeight
  , cardWeight
  , tierWeight
  , pickOffer
  ) where

import qualified Data.Map.Strict as M
import           Data.Text (Text)
import           Game.Random
import           Game.Types
import           System.Random (StdGen)
import           Ws.Types (UserId)

decideOrder :: StdGen -> [UserId] -> ([UserId], StdGen)
decideOrder = shuffle

ownerWeight :: UserId -> Double
ownerWeight _ = 1

cardWeight :: Card -> Double
cardWeight c = sum (map ownerWeight (cardOwners c))

tierWeight :: Text -> Double
tierWeight _ = 1

pickOffer :: StdGen -> Int -> [(Text, Text)] -> ([Text], StdGen)
pickOffer g0 n items0 = go g0 n grouped0
  where
    grouped0 :: M.Map Text [Text]
    grouped0 = M.fromListWith (flip (++)) [(r, [i]) | (i, r) <- items0]

    go g k grouped
      | k <= 0 || M.null grouped = ([], g)
      | otherwise =
          case pickWeighted g [(r, tierWeight r) | r <- M.keys grouped] of
            Nothing -> ([], g)
            Just (tier, _, g1) ->
              case pickUniform g1 (M.findWithDefault [] tier grouped) of
                Nothing -> go g1 k (M.delete tier grouped)
                Just (item, g2) ->
                  let rest = filter (/= item) (M.findWithDefault [] tier grouped)
                      grouped' = if null rest then M.delete tier grouped
                                              else M.insert tier rest grouped
                      (more, g3) = go g2 (k - 1) grouped'
                  in (item : more, g3)
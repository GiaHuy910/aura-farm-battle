{-# LANGUAGE OverloadedStrings #-}
module Main where

import Model.Clothe (createClothe)
import Model.Skill (createSkill)
import Config.GameConfig (userBaseAura, rarityBase, userTotalAura, clotheFlatBase, skillBase, ultBase, allRarities, Rarity(..))

main :: IO ()
main = do
    putStrLn "Initialize Testing"
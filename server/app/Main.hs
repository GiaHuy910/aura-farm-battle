{-# LANGUAGE OverloadedStrings #-}
module Main where

import Data.Text (Text)
import qualified Data.Text as T

import Model.Clothe (createClothe)
import Model.Skill (createSkill, Effect(..), countSkills)
import Config.GameConfig (userBaseAura, rarityBase, userTotalAura, clotheFlatBase, skillBase, ultBase, allRarities, Rarity(..))

data SkillSeed = SkillSeed
  { seedName           :: Text
  , seedRarity         :: Text
  , seedIsUlt          :: Bool
  , seedConsumption    :: Int   
  , seedRecovery       :: Int   
  , seedEffectType     :: Text 
  , seedEffectDuration :: Int  
  }
normal :: Text -> Text -> Int -> SkillSeed
normal name r recovery = SkillSeed name r False 0 recovery "" 0

ult :: Text -> Text -> Int -> Text -> Int -> SkillSeed
ult name r consumption effType effDur =
  SkillSeed name r True consumption 0 effType effDur

skillSeeds :: [SkillSeed]
skillSeeds =
  [ 
    normal "default dance" "common" 1
  , normal "asian squat" "common" 1
  , normal "hit the griddy" "common" 1
  , normal "hit the nae nae" "common" 1
  , ult "happy dog" "common" 5 "freeze" 2
  , normal "rainbow n sunshine" "common" 1
  , normal "wise monk rage lion" "common" 1
  , normal "dabing" "common" 1

  , normal "flossing" "uncommon" 1
  , normal "orange justice" "uncommon" 1
  , ult "chill guy" "uncommon" 5 "freeze" 2
  , normal "scuba" "uncommon" 1
  , normal "piccolo" "uncommon" 1
  , normal "sonion" "uncommon" 1
  , ult "degloving" "uncommon" 5 "freeze" 2
  , normal "emo kid" "uncommon" 1

  , normal "city boy" "rare" 1
  , normal "L" "rare" 1
  , normal "the worm" "rare" 1
  , normal "nerds" "rare" 1
  , normal "tukang tari" "rare" 1
  , normal "b-b-bugging" "rare" 1
  , normal "chopass" "rare" 1
  , ult "dispose of" "rare" 5 "freeze" 2
  , ult "fire writing" "rare" 5 "freeze" 2
  , normal "dihcipline" "rare" 1

  , normal "freddy jumpscare" "epic" 1
  , normal "tea baggin" "epic" 1
  , normal "laughing stock" "epic" 1
  , normal "baller" "epic" 1
  , normal "bro really thought" "epic" 1
  , normal "pickleball man" "epic" 1
  , normal "nothing to do" "epic" 1
  , ult "rick roll" "epic" 5 "freeze" 2
  , normal "nae nae" "epic" 1
  , ult "manipulator" "epic" 5 "freeze" 2

  , ult "la peace" "legendary" 5 "freeze" 2
  , normal "diamond diamond" "legendary" 1
  , ult "sean o'pry" "legendary" 5 "freeze" 2
  , normal "lone wolf" "legendary" 1
  , normal "sharp chin boy" "legendary" 1
  , normal "mogging" "legendary" 1
  , normal "sunshine man" "legendary" 1
  , ult "36" "legendary" 5 "freeze" 2
  , normal "job application" "legendary" 1
  , normal "jak does snacks" "legendary" 1
  , normal "mewing" "legendary" 1
  , ult "broken man" "legendary" 5 "freeze" 2

  , ult "67" "mythical" 5 "freeze" 2
  , normal "super chad" "mythical" 1
  , normal "verity" "mythical" 1
  , normal "kimi no nawa" "mythical" 1
  , ult "we are Charlie Kirk" "mythical" 5 "freeze" 2
  ]

assignTypes :: Int -> [SkillSeed] -> [(Text, SkillSeed)]
assignTypes _ [] = []
assignTypes n (s : xs)
  | seedIsUlt s = ("ult", s) : assignTypes n xs
  | otherwise   = (["s1", "s2", "s3"] !! (n `mod` 3), s) : assignTypes (n + 1) xs

withIds :: [(Text, SkillSeed)] -> [(Text, Text, SkillSeed)]
withIds xs =
  [ (sType <> "_" <> T.pack (show (sameTypeBefore i sType + 1)), sType, s)
  | (i, (sType, s)) <- zip [0 ..] xs
  ]
  where
    sameTypeBefore i t = length [() | (t', _) <- take i xs, t' == t]

seedSkill :: (Text, Text, SkillSeed) -> IO ()
seedSkill (skillId, sType, s) =
  createSkill
    skillId
    (seedName s)
    sType
    (seedConsumption s)
    (seedRecovery s)
    (seedRarity s)
    Effect { effect_type = seedEffectType s
           , effect_duration = seedEffectDuration s }
    True

main :: IO ()
main = do
  existing <- countSkills
  if existing > 0
    then putStrLn ("Skills already exist (" ++ show existing ++ "), skip seeding.")
    else do
      let seeds = withIds (assignTypes 0 skillSeeds)
      mapM_ seedSkill seeds
      putStrLn ("Seeded " ++ show (length seeds) ++ " skills.")
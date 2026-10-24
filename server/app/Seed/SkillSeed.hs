{-# LANGUAGE OverloadedStrings #-}
module Seed.SkillSeed(seedSkills)where

import Data.Text (Text)

import Model.Skill (Skill(..),createSkillBatch,insertSkills, Effect(..), countSkills)

noEffect :: Effect
noEffect = Effect { effect_type = "", effect_duration = 0 }

normal :: Text -> Text -> Text -> Text -> Int -> Skill
normal sid sType name r recovery =
  createSkillBatch sid name sType 0 recovery r noEffect True

ult :: Text -> Text -> Text -> Int -> Text -> Int -> Skill
ult sid name r consumption effType effDur =
  createSkillBatch sid name "ult" consumption 0 r
    (Effect { effect_type = effType, effect_duration = effDur }) True

allSkills :: [Skill]
allSkills =
  [
  normal "s1_1" "s1" "default dance" "common" 1
  ,normal "s2_1" "s2" "asian squat" "common" 1
  ,normal "s3_1" "s3" "hit the griddy" "common" 1
  ,normal "s1_2" "s1" "hit the nae nae" "common" 1
  ,ult "ult_1" "happy dog" "common" 5 "" 0
  ,normal "s2_2" "s2" "rainbow n sunshine" "common" 1
  ,normal "s3_2" "s3" "wise monk rage lion" "common" 1
  ,normal "s1_3" "s1" "dabing" "common" 1

  ,normal "s2_3" "s2" "flossing" "uncommon" 1
  ,normal "s3_3" "s3" "orange justice" "uncommon" 1
  ,ult "ult_2" "chill guy" "uncommon" 5 "" 0
  ,normal "s1_4" "s1" "scuba" "uncommon" 1
  ,normal "s2_4" "s2" "piccolo" "uncommon" 1
  ,normal "s3_4" "s3" "sonion" "uncommon" 1
  ,ult "ult_3" "degloving" "uncommon" 5 "" 0
  ,normal "s1_5" "s1" "emo kid" "uncommon" 1

  ,normal "s2_5" "s2" "city boy" "rare" 1
  ,normal "s3_5" "s3" "L" "rare" 1
  ,normal "s1_6" "s1" "the worm" "rare" 1
  ,normal "s2_6" "s2" "nerds" "rare" 1
  ,normal "s3_6" "s3" "tukang tari" "rare" 1
  ,normal "s1_7" "s1" "b-b-bugging" "rare" 1
  ,normal "s2_7" "s2" "chopass" "rare" 1
  ,ult "ult_4" "dispose of" "rare" 5 "" 0
  ,ult "ult_5" "fire writing" "rare" 5 "" 0
  ,normal "s3_7" "s3" "dihcipline" "rare" 1

  ,normal "s1_8" "s1" "freddy jumpscare" "epic" 1
  ,normal "s2_8" "s2" "tea baggin" "epic" 1
  ,normal "s3_8" "s3" "laughing stock" "epic" 1
  ,normal "s1_9" "s1" "baller" "epic" 1
  ,normal "s2_9" "s2" "bro really thought" "epic" 1
  ,normal "s3_9" "s3" "pickleball man" "epic" 1
  ,normal "s1_10" "s1" "nothing to do" "epic" 1
  ,ult "ult_6" "rick roll" "epic" 5 "" 0
  ,normal "s2_10" "s2" "nae nae" "epic" 1
  ,ult "ult_7" "manipulator" "epic" 5 "" 0

  ,ult "ult_8" "la peace" "legendary" 5 "freeze" 2
  ,normal "s3_10" "s3" "diamond diamond" "legendary" 1
  ,ult "ult_9" "sean o'pry" "legendary" 5 "freeze" 2
  ,normal "s1_11" "s1" "lone wolf" "legendary" 1
  ,normal "s2_11" "s2" "sharp chin boy" "legendary" 1
  ,normal "s3_11" "s3" "mogging" "legendary" 1
  ,normal "s1_12" "s1" "sunshine man" "legendary" 1
  ,ult "ult_10" "36" "legendary" 5 "freeze" 2
  ,normal "s2_12" "s2" "job application" "legendary" 1
  ,normal "s3_12" "s3" "jak does snacks" "legendary" 1
  ,normal "s1_13" "s1" "mewing" "legendary" 1
  ,ult "ult_11" "broken man" "legendary" 5 "freeze" 2

  ,ult "ult_12" "67" "mythical" 5 "freeze" 2
  ,normal "s2_13" "s2" "super chad" "mythical" 1
  ,normal "s3_13" "s3" "verity" "mythical" 1
  ,normal "s1_14" "s1" "kimi no nawa" "mythical" 1
  ,ult "ult_13" "we are Charlie Kirk" "mythical" 5 "freeze" 2
  ]

seedSkills :: IO ()
seedSkills = do
  existing <- countSkills
  if existing > 0
    then putStrLn ("Skills already exist (" ++ show existing ++ "), skip seeding.")
    else do
      insertSkills allSkills
      putStrLn "Seeded 53 skills."
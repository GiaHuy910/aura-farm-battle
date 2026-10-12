{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE DeriveGeneric #-}

module Model.Skill
    (
    Skill(..)
    , getSkillsPool
    , getSkillsByIds
    , docToSkill
    , skillToDoc
    , createSkill
    ) where

import GHC.Generics (Generic)
import Data.Aeson (ToJSON)
import Database.MongoDB
import Data.Maybe (fromMaybe)
import Data.Text (Text)

import Config.Database (runDB)
import Config.GameConfig (Rarity(..) ,skillBase, ultBase, textToRarity)

data Effect = Effect {
  effect_type :: Text,
  effect_duration :: Int
}deriving (Show, Eq, Generic)
instance ToJSON Effect

data Skill = Skill
  { skill_id   :: Text
  , skill_type :: Text
  , skill_name :: Text
  , energy_consumption :: Int
  , energy_recovery :: Int
  , aura_multiplier :: Double
  , rarity     :: Text
  , effect :: Effect   
  , in_pool    :: Bool
  } deriving (Show, Generic)

instance ToJSON Skill

docToSkill :: Document -> Skill
docToSkill doc = Skill
  { skill_id   = fromMaybe "" (doc !? "skill_id")
  , skill_type = fromMaybe "" (doc !? "skill_type")
  , skill_name = fromMaybe "" (doc !? "skill_name")
  , rarity     = fromMaybe "common" (doc !? "rarity")
  , in_pool    = fromMaybe False (doc !? "in_pool")
  , energy_consumption = fromMaybe 0 (doc !? "energy_consumption")
  , energy_recovery = fromMaybe 0 (doc !? "energy_recovery")
  , aura_multiplier = fromMaybe 1.0 (doc !? "aura_multiplier")
  , effect = case doc !? "effect" of
      Just (Doc o) -> Effect {
          effect_type = fromMaybe "" (o !? "effect_type"),
          effect_duration = fromMaybe 0 (o !? "effect_duration")
        }
      _ -> Effect {
          effect_type = "",
          effect_duration = 0
        }
  }

skillToDoc :: Skill -> Document
skillToDoc s =
  [ "skill_id"   =: skill_id s
  , "skill_type" =: skill_type s
  , "skill_name" =: skill_name s
  , "rarity"     =: rarity s
  , "in_pool"    =: in_pool s
  , "energy_consumption" =: energy_consumption s
  , "energy_recovery" =: energy_recovery s
  , "aura_multiplier" =: aura_multiplier s
  , "effect" =: effectToDoc (effect s)
  ]

getSkillBaseValue :: Text -> Rarity -> Double
getSkillBaseValue "ult" rarity = ultBase rarity     
getSkillBaseValue _     rarity = skillBase rarity

createSkill :: Text -> Text -> Text -> Int -> Int -> Text -> Effect -> Bool -> IO ()
createSkill skillId skillName skillType energyConsumption energyRecovery rarity effect inPool = do
    let rarityEnum = textToRarity rarity
    let calculatedMultiplier = getSkillBaseValue skillType rarityEnum 
    let newSkill = Skill{skill_id = skillId, skill_name = skillName, skill_type = skillType, energy_consumption = energyConsumption, energy_recovery = energyRecovery, aura_multiplier = calculatedMultiplier, rarity = rarity, effect = effect, in_pool = inPool}
    runDB $ insert_ "skills" (skillToDoc newSkill)

effectToDoc :: Effect -> Document
effectToDoc e =
  [ "effect_type" =: effect_type e
  , "effect_duration" =: effect_duration e
  ]

getSkillsPool :: IO [Skill]
getSkillsPool = runDB $ do
    docs <- find ((select ["in_pool" =: True] "skills") {project = ["in_pool" =: (0 :: Int),"skill_type" =: (0::Int)]}) >>= rest
    return (map docToSkill docs)

getSkillsByIds :: [Text] -> IO [Skill]
getSkillsByIds ids = runDB $ do
    docs <- find ((select ["skill_id" =: ["$in" =: ids]] "skills") {project = ["in_pool" =: (0:: Int),"skill_type" =: (0::Int)]}) >>= rest
    return (map docToSkill docs)
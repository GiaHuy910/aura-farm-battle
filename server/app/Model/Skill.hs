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
    , effectToDoc
    , getSkillBaseValue
    , createSkill
    , createSkillBatch
    , insertSkills
    , countSkills
    , Effect(..)
    , textToRarity
    ) where

import GHC.Generics (Generic)
import Data.Aeson (ToJSON)
import Database.MongoDB
import Data.Maybe (fromMaybe)
import Data.Text (Text)

import Config.Database (runDB)
import Config.GameConfig (skillBase, ultBase,Rarity(..))

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

textToRarity :: Text -> Rarity
textToRarity t = case t of
  "uncommon"  -> UncommonBase
  "rare"      -> RareBase
  "epic"      -> EpicBase
  "legendary" -> LegendaryBase
  "mythical"  -> MythicalBase
  _           -> CommonBase 

countSkills :: IO Int
countSkills = runDB $ count (select [] "skills")

getSkillBaseValue :: Text -> Rarity -> Double
getSkillBaseValue "ult" rar = ultBase rar     
getSkillBaseValue _     rar = skillBase rar

createSkill :: Text -> Text -> Text -> Int -> Int -> Text -> Effect -> Bool -> IO ()
createSkill skillId skillName skillType energyConsumption energyRecovery rar eft inPool = do
    let calculatedMultiplier = getSkillBaseValue skillType (textToRarity rar)
    let newSkill = Skill{skill_id = skillId, skill_name = skillName, skill_type = skillType, energy_consumption = energyConsumption, energy_recovery = energyRecovery, aura_multiplier = calculatedMultiplier, rarity = rar, effect = eft, in_pool = inPool}
    runDB $ insert_ "skills" (skillToDoc newSkill)

createSkillBatch :: Text -> Text -> Text -> Int -> Int -> Text -> Effect -> Bool -> Skill
createSkillBatch skillId skillName skillType energyConsumption energyRecovery rar eft inPool =
    Skill{skill_id = skillId, skill_name = skillName, skill_type = skillType, energy_consumption = energyConsumption, energy_recovery = energyRecovery, aura_multiplier = getSkillBaseValue skillType (textToRarity rar), rarity = rar, effect = eft, in_pool = inPool}

insertSkills :: [Skill] -> IO ()
insertSkills ss = runDB $ insertMany_ "skills" (map skillToDoc ss)

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
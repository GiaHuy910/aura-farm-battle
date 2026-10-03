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
    ) where

import GHC.Generics (Generic)
import Data.Aeson (ToJSON)
import Database.MongoDB
import Data.Maybe (fromMaybe)
import Data.Text (Text)

data Skill = Skill
  { skill_id   :: Text
  , skill_type :: Text
  , skill_name :: Text
  , rarity     :: Text   
  , in_pool    :: Bool
  } deriving (Show, Generic)

instance ToJSON Skill

runDB :: Action IO a -> IO a
runDB action = do
    pipe <- connect (host "127.0.0.1")
    result <- access pipe master "aura-farm-battle" action
    close pipe
    return result

docToSkill :: Document -> Skill
docToSkill doc = Skill
  { skill_id   = fromMaybe "" (doc !? "skill_id")
  , skill_type = fromMaybe "" (doc !? "skill_type")
  , skill_name = fromMaybe "" (doc !? "skill_name")
  , rarity     = fromMaybe "common" (doc !? "rarity")
  , in_pool    = fromMaybe False (doc !? "in_pool")
  }

skillToDoc :: Skill -> Document
skillToDoc s =
  [ "skill_id"   =: skill_id s
  , "skill_type" =: skill_type s
  , "skill_name" =: skill_name s
  , "rarity"     =: rarity s
  , "in_pool"    =: in_pool s
  ]

getSkillsPool :: IO [Skill]
getSkillsPool = runDB $ do
    docs <- find (select ["in_pool" =: True] "skills") >>= rest
    return (map docToSkill docs)

getSkillsByIds :: [Text] -> IO [Skill]
getSkillsByIds ids = runDB $ do
    docs <- find (select ["skill_id" =: ["$in" =: ids]] "skills") >>= rest
    return (map docToSkill docs)
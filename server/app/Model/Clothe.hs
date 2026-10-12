{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE DeriveGeneric #-}

module Model.Clothe
    (
    Clothe(..)
    , getClothesPool
    , getClothesByIds
    , docToClothe
    , clotheToDoc
    , createClothe
    ) where

import GHC.Generics (Generic)
import Data.Aeson (ToJSON)
import Database.MongoDB
import Data.Maybe (fromMaybe)
import Data.Text (Text)
import Config.Database (runDB)

data Clothe = Clothe
  { clothe_id   :: Text
  , clothe_type :: Text
  , clothe_name :: Text
  , aura_bonus :: Int
  , rarity      :: Text   
  , in_pool     :: Bool
  } deriving (Show, Generic)

instance ToJSON Clothe

docToClothe :: Document -> Clothe
docToClothe doc = Clothe
  { clothe_id   = fromMaybe "" (doc !? "clothe_id")
  , clothe_type = fromMaybe "" (doc !? "clothe_type")
  , clothe_name = fromMaybe "" (doc !? "clothe_name")
  , aura_bonus  = fromMaybe 0 (doc !? "aura_bonus")
  , rarity      = fromMaybe "common" (doc !? "rarity")
  , in_pool     = fromMaybe False (doc !? "in_pool")
  }

clotheToDoc :: Clothe -> Document
clotheToDoc c =
  [ "clothe_id"   =: clothe_id c
  , "clothe_type" =: clothe_type c
  , "clothe_name" =: clothe_name c
  , "aura_bonus"  =: aura_bonus c
  , "rarity"      =: rarity c
  , "in_pool"     =: in_pool c
  ]

createClothe :: Text -> Text -> Text -> Int -> Text -> Bool -> IO ()
createClothe clothe_id clothe_type clothe_name aura_bonus rarity in_pool = do
    -- Automatically understand that these inside {..} are the fields of the Clothe data type
    let newClothe = Clothe{..}
    runDB $ insert_ "clothes" (clotheToDoc newClothe)

getClothesPool :: IO [Clothe]
getClothesPool = runDB $ do
    docs <- find ((select ["in_pool" =: True] "clothes") {project = ["in_pool" =: (0 :: Int),"clothe_type" =: (0 :: Int)]}) >>= rest
    return (map docToClothe docs)

getClothesByIds :: [Text] -> IO [Clothe]
getClothesByIds ids = runDB $ do
    docs <- find ((select ["clothe_id" =: ["$in" =: ids]] "clothes") {project = ["in_pool" =: (0:: Int),"clothe_type" =: (0 :: Int)]}) >>= rest
    return (map docToClothe docs)
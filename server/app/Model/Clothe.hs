{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE DeriveGeneric #-}

module Model.Clothe
    (
    Clothe(..)
    , getClothesPool
    , getClothesByIds
    , docToClothe
    , clotheToDoc
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
  , rarity      :: Text   
  , in_pool     :: Bool
  } deriving (Show, Generic)

instance ToJSON Clothe


docToClothe :: Document -> Clothe
docToClothe doc = Clothe
  { clothe_id   = fromMaybe "" (doc !? "clothe_id")
  , clothe_type = fromMaybe "" (doc !? "clothe_type")
  , clothe_name = fromMaybe "" (doc !? "clothe_name")
  , rarity      = fromMaybe "common" (doc !? "rarity")
  , in_pool     = fromMaybe False (doc !? "in_pool")
  }

clotheToDoc :: Clothe -> Document
clotheToDoc c =
  [ "clothe_id"   =: clothe_id c
  , "clothe_type" =: clothe_type c
  , "clothe_name" =: clothe_name c
  , "rarity"      =: rarity c
  , "in_pool"     =: in_pool c
  ]

getClothesPool :: IO [Clothe]
getClothesPool = runDB $ do
    docs <- find ((select ["in_pool" =: True] "clothes") {project = ["clothe_id" =: (1 :: Int), "rarity" =: (1 ::Int)]}) >>= rest
    return (map docToClothe docs)

getClothesByIds :: [Text] -> IO [Clothe]
getClothesByIds ids = runDB $ do
    docs <- find ((select ["clothe_id" =: ["$in" =: ids]] "clothes") {project = ["clothe_id" =: (1:: Int), "rarity" =: (1 :: Int)]}) >>= rest
    return (map docToClothe docs)
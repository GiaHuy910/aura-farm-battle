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
    , createClothe
    , createClotheBatch
    , insertClothes
    , countClothes
    ) where

import GHC.Generics (Generic)
import Data.Aeson (ToJSON)
import Database.MongoDB
import Data.Maybe (fromMaybe)
import Data.Text (Text)
import Config.Database (runDB)
import Config.GameConfig (clotheFlatBase,userBaseAura, Rarity(..))

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

textToRarity :: Text -> Rarity
textToRarity t = case t of
  "uncommon"  -> UncommonBase
  "rare"      -> RareBase
  "epic"      -> EpicBase
  "legendary" -> LegendaryBase
  "mythical"  -> MythicalBase
  _           -> CommonBase 

countClothes :: IO Int
countClothes = runDB $ count (select [] "clothes")

createClothe :: Text -> Text -> Text -> Text -> Bool -> IO ()
createClothe clotheId clotheType clotheName clotheRarity inPool = do
    let calculatedAuraBonus = clotheFlatBase userBaseAura (textToRarity clotheRarity)
    let newClothe = Clothe{
        clothe_id = clotheId,
        clothe_type = clotheType,
        clothe_name = clotheName,
        aura_bonus = calculatedAuraBonus,
        rarity = clotheRarity,
        in_pool = inPool
    }
    runDB $ insert_ "clothes" (clotheToDoc newClothe)

createClotheBatch :: Text -> Text -> Text -> Text -> Bool -> Clothe
createClotheBatch clotheId clotheType clotheName clotheRarity inPool = 
    Clothe{
        clothe_id = clotheId,
        clothe_type = clotheType,
        clothe_name = clotheName,
        aura_bonus = clotheFlatBase userBaseAura (textToRarity clotheRarity),
        rarity = clotheRarity,
        in_pool = inPool
    }

insertClothes :: [Clothe] -> IO ()
insertClothes cs = runDB $ insertMany_ "clothes" (map clotheToDoc cs)

getClothesPool :: IO [Clothe]
getClothesPool = runDB $ do
    docs <- find ((select ["in_pool" =: True] "clothes") {project = ["in_pool" =: (0 :: Int),"clothe_type" =: (0 :: Int)]}) >>= rest
    return (map docToClothe docs)

getClothesByIds :: [Text] -> IO [Clothe]
getClothesByIds ids = runDB $ do
    docs <- find ((select ["clothe_id" =: ["$in" =: ids]] "clothes") {project = ["in_pool" =: (0:: Int),"clothe_type" =: (0 :: Int)]}) >>= rest
    return (map docToClothe docs)
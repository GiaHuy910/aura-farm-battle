{-# LANGUAGE OverloadedStrings #-}

module Game.Config
  ( maxRounds
  , roundSecs
  , interRoundSecs
  , energyMax
  , energyPerRound
  , handSize
  , ticketReward
  , offerSkillCount
  , offerClotheCount
  , rewardSecs
  , auraCap
  , defaultItems
  , isDefaultItem
  , ItemKind (..)
  , itemKind
  , slotOf
  ) where

import           Data.Text (Text)
import qualified Data.Text as T

maxRounds :: Int
maxRounds = 10

roundSecs :: Int
roundSecs = 20

interRoundSecs :: Int
interRoundSecs = 3

energyMax :: Int
energyMax = 7

energyPerRound :: Int
energyPerRound = 1

handSize :: Int
handSize = 4

ticketReward :: Int
ticketReward = 20

offerSkillCount :: Int
offerSkillCount = 3

offerClotheCount :: Int
offerClotheCount = 3

rewardSecs :: Int
rewardSecs = 15

auraCap :: Int
auraCap = 1000000000000000

defaultItems :: [Text]
defaultItems = ["acc_1", "shirt_1", "shoes_1", "s1_1", "s2_1", "s3_1", "ult_1"]

isDefaultItem :: Text -> Bool
isDefaultItem = (`elem` defaultItems)

data ItemKind = KindSkill | KindClothe
  deriving (Eq, Show)

itemKind :: Text -> Maybe ItemKind
itemKind i
  | any (`T.isPrefixOf` i) ["s1_", "s2_", "s3_", "ult_"]    = Just KindSkill
  | any (`T.isPrefixOf` i) ["acc_", "shirt_", "shoes_"]     = Just KindClothe
  | otherwise                                               = Nothing

slotOf :: Text -> Maybe (Text, Text)
slotOf i
  | "s1_"    `T.isPrefixOf` i = Just ("equipped_s1",    "s1_1")
  | "s2_"    `T.isPrefixOf` i = Just ("equipped_s2",    "s2_1")
  | "s3_"    `T.isPrefixOf` i = Just ("equipped_s3",    "s3_1")
  | "ult_"   `T.isPrefixOf` i = Just ("equipped_ult",   "ult_1")
  | "acc_"   `T.isPrefixOf` i = Just ("equipped_acc",   "acc_1")
  | "shirt_" `T.isPrefixOf` i = Just ("equipped_shirt", "shirt_1")
  | "shoes_" `T.isPrefixOf` i = Just ("equipped_shoes", "shoes_1")
  | otherwise                 = Nothing
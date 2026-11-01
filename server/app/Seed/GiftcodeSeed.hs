{-# LANGUAGE OverloadedStrings #-}

module Seed.GiftcodeSeed (seedGiftcodes) where

import           Config.Database (runDB)
import           Data.Text (Text)
import           Database.MongoDB

import           Model.Giftcode (ensureGiftcodeIndexes)

seedGiftcodes :: IO ()
seedGiftcodes = do
  ensureGiftcodeIndexes
  runDB $ do
    existing <- findOne (select ["code" =: ("AURAFARMTIME" :: Text)] "giftcodes")
    case existing of
      Just _ -> pure ()
      Nothing -> insert_ "giftcodes"
        [ "code" =: ("AURAFARMTIME" :: Text)
        , "rewards" =: Doc
            [ "tickets" =: (200 :: Int)
            , "skills" =: ([] :: [Text])
            , "clothes" =: ([] :: [Text])
            ]
        , "max_uses" =: (Null :: Value)
        , "used_count" =: (0 :: Int)
        , "expires_at" =: (Null :: Value)
        , "active" =: True
        ]

{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}

module Model.Giftcode
  ( Giftcode (..)
  , GiftcodeRewards (..)
  , normalizeGiftcodeCode
  , ensureGiftcodeIndexes
  , findGiftcode
  , insertRedemption
  , deleteRedemption
  , claimSlot
  ) where

import           Control.Exception (throwIO, try)
import           Data.Maybe (fromMaybe)
import           Data.Text (Text)
import qualified Data.Text as T
import           Data.Time (UTCTime, getCurrentTime)
import           Database.MongoDB

import           Config.Database (runDB)

data GiftcodeRewards = GiftcodeRewards
  { rewardTickets :: Int
  , rewardSkills  :: [Text]
  , rewardClothes :: [Text]
  } deriving (Eq, Show)

data Giftcode = Giftcode
  { giftcodeCode      :: Text
  , giftcodeRewards   :: GiftcodeRewards
  , giftcodeMaxUses   :: Maybe Int
  , giftcodeUsedCount :: Int
  , giftcodeExpiresAt :: Maybe UTCTime
  , giftcodeActive    :: Bool
  } deriving (Show)

normalizeGiftcodeCode :: Text -> Text
normalizeGiftcodeCode = T.toUpper . T.strip

ensureGiftcodeIndexes :: IO ()
ensureGiftcodeIndexes = runDB $ do
  ensureIndex ((index "giftcodes" ["code" =: (1 :: Int)])
    { iName = "giftcode_code_unique", iUnique = True })
  ensureIndex ((index "giftcode_redemptions"
    ["code" =: (1 :: Int), "user_id" =: (1 :: Int)])
    { iName = "giftcode_user_unique", iUnique = True })

findGiftcode :: Text -> IO (Maybe Giftcode)
findGiftcode code = runDB $ do
  document <- findOne (select ["code" =: code] "giftcodes")
  pure (fmap docToGiftcode document)

insertRedemption :: Text -> Text -> IO Bool
insertRedemption code uid = do
  now <- getCurrentTime
  result <- try $ runDB $ insert_ "giftcode_redemptions"
    [ "code" =: code
    , "user_id" =: uid
    , "redeemed_at" =: now
    ]
  case result of
    Right _ -> pure True
    Left failure
      | isDuplicateKey failure -> pure False
      | otherwise -> throwIO failure

deleteRedemption :: Text -> Text -> IO ()
deleteRedemption code uid = runDB $
  deleteOne (select ["code" =: code, "user_id" =: uid] "giftcode_redemptions")

claimSlot :: Giftcode -> IO Bool
claimSlot giftcode = do
  now <- getCurrentTime
  let baseFilter =
        [ "code" =: giftcodeCode giftcode
        , "active" =: True
        ]
      useFilter = case giftcodeMaxUses giftcode of
        Just maxUses -> ["used_count" =: ["$lt" =: maxUses]]
        Nothing -> []
      expiryFilter = case giftcodeExpiresAt giftcode of
        Just _ -> ["expires_at" =: ["$gt" =: now]]
        Nothing -> []
  result <- runDB $ findAndModify
    (select (baseFilter ++ useFilter ++ expiryFilter) "giftcodes")
    ["$inc" =: ["used_count" =: (1 :: Int)]]
  pure (either (const False) (const True) result)

docToGiftcode :: Document -> Giftcode
docToGiftcode document = Giftcode
  { giftcodeCode = fromMaybe "" (document !? "code")
  , giftcodeRewards = case document !? "rewards" of
      Just (Doc rewards) -> GiftcodeRewards
        { rewardTickets = fromMaybe 0 (rewards !? "tickets")
        , rewardSkills = fromMaybe [] (rewards !? "skills")
        , rewardClothes = fromMaybe [] (rewards !? "clothes")
        }
      _ -> GiftcodeRewards 0 [] []
  , giftcodeMaxUses = document !? "max_uses"
  , giftcodeUsedCount = fromMaybe 0 (document !? "used_count")
  , giftcodeExpiresAt = document !? "expires_at"
  , giftcodeActive = fromMaybe False (document !? "active")
  }

isDuplicateKey :: Failure -> Bool
isDuplicateKey failure = case failure of
  WriteFailure _ 11000 _ -> True
  QueryFailure 11000 _ -> True
  _ -> False

{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE DisambiguateRecordFields #-}

module Model.GachaHistory
  ( GachaHistory(..)
  , saveGachaHistory
  , getGachaHistory
  ) where

import Prelude hiding (lookup)
import Data.Aeson
import Data.Bson
import Database.MongoDB (sort, limit, insertMany_, find, select, rest)
import Data.Text (Text)
import qualified Data.Text as T
import Data.Time.Clock (UTCTime, getCurrentTime)
import GHC.Generics
import Text.Read (readMaybe)
import Data.Maybe (fromMaybe)

import Config.Database (runDB)

-- 1. Struct Entity
data GachaHistory = GachaHistory
    { _id       :: Text
    , user_id   :: Text
    , item_id   :: Text
    , item_type :: Text
    , createdAt :: UTCTime
    } deriving (Show, Generic)

instance ToJSON GachaHistory where
  toJSON h = object
    [ "_id"       .= _id h
    , "user_id"   .= user_id h
    , "item_id"   .= item_id h
    , "item_type" .= item_type h
    , "createdAt" .= createdAt h
    ]

-- 2. Lưu lịch sử
saveGachaHistory :: Text -> Text -> [Text] -> IO ()
saveGachaHistory uid itemType itemIds = do
    now <- getCurrentTime
    let docs = map (\iId ->
            [ "user_id"   =: uid
            , "item_id"   =: iId
            , "item_type" =: itemType
            , "createdAt" =: now
            ]) itemIds
    runDB $ insertMany_ "gacha_histories" docs

-- 3. Query phân trang
getGachaHistory :: Text -> Text -> Int -> Text -> IO [GachaHistory]
getGachaHistory uid itemType limitVal cursor = runDB $ do
    let baseQuery = [ "user_id" =: uid, "item_type" =: itemType ]

    let queryFilter = if T.null cursor
            then baseQuery
            else case readMaybe (T.unpack cursor) :: Maybe ObjectId of
                    Just oid -> baseQuery ++ [ "_id" =: [ "$lt" =: oid ] ]
                    Nothing  -> baseQuery

    cursorObj <- find (select queryFilter "gacha_histories")
                    { sort = ["_id" =: (-1 :: Int)]
                    , limit = fromIntegral limitVal
                    }
    docs <- rest cursorObj
    return $ map docToGachaHistory docs

-- 4. Mapper
docToGachaHistory :: Document -> GachaHistory
docToGachaHistory doc = GachaHistory
    { _id       = maybe "" (T.pack . show) (lookup "_id" doc :: Maybe ObjectId)
    , user_id   = typedLook "user_id"
    , item_id   = typedLook "item_id"
    , item_type = typedLook "item_type"
    , createdAt = fromMaybe (read "1970-01-01 00:00:00 UTC") (lookup "createdAt" doc :: Maybe UTCTime)
    }
  where
    typedLook k = fromMaybe "" (lookup k doc)
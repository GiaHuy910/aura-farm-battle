{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedRecordDot #-}

module Controllers.GachaHistoryController
  ( GachaHistoryResponse(..)
  , Pagination(..)
  , getGachaHistoryHandler
  ) where

import Control.Monad.IO.Class (liftIO)
import Data.Aeson
import Data.Text (Text)
import GHC.Generics
import Servant

import Controllers.AuthController (withAuthenticatedUser)
import Model.User (User(..))
import Model.GachaHistory
    ( GachaHistory(..)
    , getGachaHistory
    , validHistoryCursor
    )

data Pagination = Pagination
    { limit      :: Int
    , nextCursor :: Text
    } deriving (Show, Generic)

instance ToJSON Pagination

data GachaHistoryResponse = GachaHistoryResponse
    { gacha_history_list :: [GachaHistory]
    , pagination         :: Pagination
    } deriving (Show, Generic)

instance ToJSON GachaHistoryResponse

getGachaHistoryHandler
    :: Maybe String
    -> Int
    -> Text
    -> Text
    -> Handler GachaHistoryResponse
getGachaHistoryHandler cookie limitVal cursorVal itemTypeVal = withAuthenticatedUser cookie $ \u -> do
    if limitVal < 1 || limitVal > 100
        then throwError err400 { errBody = "invalid_limit" }
        else pure ()
    if itemTypeVal /= "skill" && itemTypeVal /= "clothe"
        then throwError err400 { errBody = "invalid_item_type" }
        else pure ()
    if not (validHistoryCursor cursorVal)
        then throwError err400 { errBody = "invalid_cursor" }
        else pure ()

    let uid = u.user_id
    histories <- liftIO $ getGachaHistory uid itemTypeVal limitVal cursorVal

    let nextCursorVal = if null histories
                            then ""
                            else _id (last histories)

    return $ GachaHistoryResponse
        { gacha_history_list = histories
        , pagination = Pagination
            { limit = limitVal
            , nextCursor = nextCursorVal
            }
        }
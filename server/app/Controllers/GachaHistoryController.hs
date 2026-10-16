{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators #-}

module Controllers.GachaHistoryController
  ( GachaHistoryAPI
  , getGachaHistoryHandler
  ) where

import Control.Monad.IO.Class (liftIO)
import Data.Maybe (fromMaybe)
import Data.Text (Text)
import Servant

import Controllers.AuthController (withAuthenticatedUser)
import Model.User (User(..))
import Model.GachaHistory
    ( GachaHistoryResponse(..)
    , Pagination(..)
    , GachaHistory(history_id)
    , getGachaHistory
    )

-- 1. Định nghĩa Endpoint API
type GachaHistoryAPI = "gacha-history"
    :> Header "Cookie" String
    :> QueryParam "limit" Int
    :> QueryParam "cursor" Text
    :> QueryParam "item_type" Text
    :> Get '[JSON] GachaHistoryResponse

-- 2. Logic xử lý Request
getGachaHistoryHandler :: Maybe String -> Maybe Int -> Maybe Text -> Maybe Text -> Handler GachaHistoryResponse
getGachaHistoryHandler cookie mLimit mCursor mItemType = withAuthenticatedUser cookie $ \u -> do
    let limitVal = fromMaybe 6 mLimit
        cursorVal = fromMaybe "" mCursor
        itemTypeVal = fromMaybe "clothe" mItemType
        uid = user_id u

    histories <- liftIO $ getGachaHistory uid itemTypeVal limitVal cursorVal

    let nextCursorVal = if null histories
                            then ""
                            else history_id (last histories)

    return $ GachaHistoryResponse
        { gacha_history_list = histories
        , pagination = Pagination
            { limit = limitVal
            , nextCursor = nextCursorVal
            }
        }
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}

module Model.Session
    (
    Session(..)
    , createSession
    , getUserBySession
    , deleteSession
    ) where

import Database.MongoDB
import Data.Maybe (fromMaybe)
import Data.UUID.V4 (nextRandom)
import Data.UUID (toString)
import Control.Monad.IO.Class (liftIO)
import Data.Text (Text, pack)
import Data.Time.Clock ( UTCTime, getCurrentTime, addUTCTime)
import Config.Database (runDB)

-- Đã đổi username thành user_id
data Session = Session
  { session_id :: Text
  , user_id    :: Text
  , expiresAt :: UTCTime
  } deriving (Show)

sessionToDoc :: Session -> Document
sessionToDoc s =
  [ "session_id" =: session_id (s :: Session)
  , "user_id"    =: user_id (s :: Session)
  , "expiresAt" =: expiresAt (s :: Session)
  ]

-- Tạo session dựa trên user_id thay vì username
createSession :: Text -> Int -> IO Text
createSession uId age = do
    uuid <- liftIO nextRandom
    now <- liftIO getCurrentTime
    let duration = fromIntegral age
        expires_at = addUTCTime duration now
    let sID = pack (toString uuid)
    let newSession = Session { session_id = sID, user_id = uId, expiresAt = expires_at }
    runDB $ insert_ "sessions" (sessionToDoc newSession)
    return sID

-- Chỉ cần query 1 lần là lấy được user_id, không cần quét bảng user nữa
getUserBySession :: Text -> IO (Maybe Text)
getUserBySession sID = runDB $ do
    maybeSessionDoc <- findOne ((select ["session_id" =: sID] "sessions") { project = ["user_id" =: (1 :: Int)] })
    case maybeSessionDoc of
        Nothing   -> return Nothing
        Just sDoc -> return (Just $ fromMaybe "" (sDoc !? "user_id"))

-- Xóa session khi logout
deleteSession :: Text -> IO ()
deleteSession sID = runDB $ do
    deleteOne (select ["session_id" =: sID] "sessions")
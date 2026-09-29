{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}

module Model.Session where

import Database.MongoDB
import Data.Maybe (fromMaybe)
import Data.UUID.V4 (nextRandom)
import Data.UUID (toString)
import Control.Monad.IO.Class (liftIO)
import Data.Text (Text, pack)

-- Đã đổi username thành user_id
data Session = Session
  { session_id :: Text
  , user_id    :: Text 
  } deriving (Show)

runDB :: Action IO a -> IO a
runDB action = do
    pipe <- connect (host "127.0.0.1")
    result <- access pipe master "aura-farm-battle" action
    close pipe
    return result

sessionToDoc :: Session -> Document
sessionToDoc s =
  [ "session_id" =: session_id (s :: Session)
  , "user_id"    =: user_id (s :: Session)
  ]

-- Tạo session dựa trên user_id thay vì username
createSession :: Text -> IO Text
createSession uId = do
    uuid <- liftIO nextRandom
    let sID = pack (toString uuid)
    let newSession = Session { session_id = sID, user_id = uId }
    runDB $ insert_ "sessions" (sessionToDoc newSession)
    return sID

-- Chỉ cần query 1 lần là lấy được user_id, không cần quét bảng user nữa
getUserBySession :: Text -> IO (Maybe Text)
getUserBySession sID = runDB $ do
    maybeSessionDoc <- findOne (select ["session_id" =: sID] "sessions")
    case maybeSessionDoc of
        Nothing   -> return Nothing
        Just sDoc -> return (Just $ fromMaybe "" (sDoc !? "user_id"))

-- Xóa session khi logout
deleteSession :: Text -> IO ()
deleteSession sID = runDB $ do
    deleteOne (select ["session_id" =: sID] "sessions")
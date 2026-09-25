{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}
module Game_database.Session where

import Database.MongoDB
import Data.Maybe (fromMaybe)
import Data.UUID.V4 (nextRandom)
import Data.UUID (toString)
import Control.Monad.IO.Class (liftIO)
import Data.Text (Text, pack)

data Session = Session
  { session_id :: Text
  , username   :: Text
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
  , "username"   =: username (s :: Session)
  ]

-- Tạo session từ username truyền vào
createSession :: Text -> IO Text
createSession uName = do
    uuid <- liftIO nextRandom
    let sID = pack (toString uuid)
    let newSession = Session { session_id = sID, username = uName }
    runDB $ insert_ "sessions" (sessionToDoc newSession)
    return sID

-- Tìm username từ session_id
getUserBySession :: Text -> IO (Maybe Text)
getUserBySession sID = runDB $ do
    maybeDoc <- findOne (select ["session_id" =: sID] "sessions")
    case maybeDoc of
        Nothing  -> return Nothing
        Just doc -> return (Just $ fromMaybe "" (doc !? "username"))

-- Xóa session khi logout
deleteSession :: Text -> IO ()
deleteSession sID = runDB $ do
    deleteOne (select ["session_id" =: sID] "sessions")
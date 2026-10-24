{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}

module Model.Rooms
    (
    Room(..)
    , getRooms
    , getRoomById
    , createRoom
    , deleteRoom
    , deleteRoomById
    , JoinResult(..)
    , joinRoomById
    , addMember
    , removeMember
    , setRoomStatus
    , validateRoomName
    , ValidationError(..)
    ) where

import Database.MongoDB
import Data.Maybe (fromMaybe)
import Data.UUID.V4 (nextRandom)
import Data.UUID (toString)
import Control.Monad.IO.Class (liftIO)
import Data.Text (Text, pack)

import Config.Database (runDB)
import Config.GameConfig(maxRoomName)

data Room = Room
  {room_id :: Text
  ,room_name  :: Text
  , room_password  :: Text
  , owner_id   :: Text
  , user_ids   :: [Text]
  , occupancy :: Int
  , is_private :: Bool
  , status :: Text
  } deriving (Show)

getRooms :: IO [Room]
getRooms = runDB $ do
    docs <- find ((select [] "room") { project = ["room_password" =: (0 :: Int)] }) >>= rest
    return (map docToRoom docs)

getRoomById :: Text -> IO (Maybe Room)
getRoomById rid = runDB $ do
    mDoc <- findOne (select ["room_id" =: rid] "room")
    return (fmap docToRoom mDoc)

docToRoom :: Document -> Room
docToRoom doc = Room
  { room_id = fromMaybe "" (doc !? "room_id")
  , room_name  = fromMaybe ""    (doc !? "room_name")
  , room_password  = fromMaybe ""    (doc !? "room_password")
  , owner_id   = fromMaybe ""    (doc !? "owner_id")
  , user_ids   = fromMaybe []    (doc !? "user_ids")
  , occupancy = fromMaybe 0     (doc !? "occupancy")
  , is_private = fromMaybe False (doc !? "is_private")
  , status = fromMaybe "waiting" (doc !? "status")
  }

roomToDoc :: Room -> Document
roomToDoc r =
  [ "room_id" =: room_id r
  , "room_name" =: room_name r
  , "room_password"  =: room_password r
  , "owner_id"   =: owner_id r
  , "user_ids"    =: user_ids r
  , "occupancy" =: occupancy r
  , "is_private" =: is_private r
  , "status" =: status r
  ]

data ValidationError=RoomNameEmpty | RoomNameTooLong deriving (Show, Eq)

validateRoomName :: String -> Either ValidationError ()
validateRoomName name
  | null name = Left RoomNameEmpty
  | length name > maxRoomName = Left RoomNameTooLong
  | otherwise = Right ()

createRoom :: Room -> IO Room
createRoom newRoom = runDB $ do
    uuid <- liftIO nextRandom
    let validUsers = take 2 (user_ids newRoom)
    if null validUsers
        then error "Phòng phải có ít nhất 1 người (chủ phòng)"
    else do
        let realOccupancy = length (user_ids newRoom)
        let valiatedRoom = newRoom { room_id = pack (toString uuid), occupancy = realOccupancy }
        insert_ "room" (roomToDoc valiatedRoom)
        return valiatedRoom

deleteRoom :: Text -> Text -> IO ()
deleteRoom rId reqOwnerID = runDB $ do
    deleteOne (select ["room_id" =: rId, "owner_id" =: reqOwnerID] "room")

deleteRoomById :: Text -> IO ()
deleteRoomById rid = runDB $ deleteOne (select ["room_id" =: rid] "room")

setRoomStatus :: Text -> Text -> IO ()
setRoomStatus rid st = runDB $
    modify (select ["room_id" =: rid] "room") ["$set" =: ["status" =: st]]

data JoinResult = JoinOk | RoomNotFound | WrongPassword | RoomUnavailable
  deriving (Show, Eq)

addMember :: Text -> Text -> IO Bool
addMember rid uid = runDB $ do
    res <- findAndModify
        (select [ "room_id"   =: rid
                , "status"    =: ("waiting" :: Text)
                , "occupancy" =: ["$lt" =: (2 :: Int)]
                , "user_ids"  =: ["$ne" =: uid]
                ] "room")
        [ "$push" =: ["user_ids" =: uid]
        , "$inc"  =: ["occupancy" =: (1 :: Int)]
        ]
    return (either (const False) (const True) res)

removeMember :: Text -> Text -> IO ()
removeMember rid uid = runDB $
    modify (select ["room_id" =: rid, "user_ids" =: uid] "room")
        [ "$pull" =: ["user_ids" =: uid]
        , "$inc"  =: ["occupancy" =: (-1 :: Int)]
        ]

joinRoomById :: Text -> Text -> Text -> IO JoinResult
joinRoomById rid pass uid = do
    mRoom <- getRoomById rid
    case mRoom of
        Nothing -> return RoomNotFound
        Just room
            | is_private room && room_password room /= pass -> return WrongPassword
            | otherwise -> do
                ok <- addMember rid uid
                return (if ok then JoinOk else RoomUnavailable)
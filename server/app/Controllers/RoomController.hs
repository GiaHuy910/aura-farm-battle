{-# LANGUAGE DataKinds     #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}
module Controllers.RoomController where

import Control.Monad.IO.Class
import Data.Aeson hiding (Success)
import Data.Text (Text, pack, unpack)
import qualified Data.Text as T
import GHC.Generics
import Servant
-- Import từ các module Database của bạn
import Game_database.Rooms (Room(..), getRooms, createRoom, deleteRoom)

-- Room Requests/Responses
data CreateRoomRequest = CreateRoomRequest
  { roomNameRequest :: Text
  , passwordRequest :: Text
  , ownerIDRequest  :: Text
  , isPrivateRequest :: Bool
  } deriving (Show, Generic)

instance FromJSON CreateRoomRequest where
  parseJSON = genericParseJSON $ defaultOptions
    { fieldLabelModifier = \field ->
        case field of
          "roomNameRequest"   -> "room_name"
          "passwordRequest"   -> "room_password"
          "ownerIDRequest"    -> "owner_id"
          "isPrivateRequest"  -> "is_private"
          _                   -> field
    }

data RoomDetail = RoomDetail
  { resRoomID   :: Text
  , resRoomName  :: Text
  , resIsPrivate :: Bool
  } deriving (Show, Generic)

instance ToJSON RoomDetail   where
  toJSON = genericToJSON $ defaultOptions
    { fieldLabelModifier = \field ->
        case field of
          "resRoomID"   -> "room_id"
          "resRoomName" -> "room_name"
          "resIsPrivate" -> "is_private"
          _                   -> field
    }

data CreateRoomResponse = CreateRoomResponse
  { status :: Text
  , room   :: RoomDetail
  } deriving (Show, Generic)

instance ToJSON CreateRoomResponse

data RoomResponse = RoomResponse
  { roomIDResponse   :: Text
  , roomNameResponse  :: Text
  , occupancyResponse :: Int
  , isPrivateResponse :: Bool
  } deriving (Show, Generic)

instance ToJSON RoomResponse where
  toJSON = genericToJSON $ defaultOptions
    { fieldLabelModifier = \field ->
        case field of
          "roomIDResponse"   -> "room_id"
          "roomNameResponse" -> "room_name"
          "occupancyResponse"-> "occupancy"
          "isPrivateResponse"-> "is_private"
          _                  -> field
     }

getRoomsHandler :: Handler [RoomResponse]
getRoomsHandler = do
  rooms <- liftIO getRooms
  return (map roomToResponse rooms)
  
roomToResponse :: Room -> RoomResponse
roomToResponse room =
  RoomResponse
    { roomNameResponse = room_name room
    , occupancyResponse = occupancy room
    , isPrivateResponse = is_private room
    }

createRoomHandler :: CreateRoomRequest -> Handler RoomResponse
createRoomHandler req = do
  let newRoom =
        Room
          { room_id = ""
          , room_name = roomNameRequest req
          , room_password = passwordRequest req
          , owner_id = ownerIDRequest req
          , user_ids = [ownerIDRequest req]
          -----------------------------------------------------------
          -- nhớ cái vụ này, coi làm sao nha , occupancy đó
          -----------------------------------------------------------
          , occupancy = 1
          , is_private = isPrivateRequest req
          }
  createdRoom <- liftIO (createRoom newRoom)
  let rDetail = RoomDetail
        { resRoomID = room_id createdRoom
        , resRoomName = room_name createdRoom
        , resIsPrivate = is_private createdRoom
        }
  return $ CreateRoomResponse
    { status = "success"
    , room = rDetail
    }

deleteRoomHandler :: String -> String -> Handler NoContent
deleteRoomHandler roomNameValue ownerIDValue = do
  liftIO (deleteRoom (pack roomNameValue) (pack ownerIDValue))
  return NoContent
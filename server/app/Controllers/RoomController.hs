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
import Game_database.Session (getUserBySession)

-- Room Requests/Responses
data CreateRoomRequest = CreateRoomRequest
  { roomNameRequest  :: Text
  , passwordRequest  :: Text
  -- ĐÃ XÓA ownerIDRequest TẠI ĐÂY
  , isPrivateRequest :: Bool
  } deriving (Show, Generic)

instance FromJSON CreateRoomRequest where
  parseJSON = genericParseJSON $ defaultOptions
    { fieldLabelModifier = \field ->
        case field of
        "roomNameRequest"   -> "room_name"
        "passwordRequest"   -> "room_password"
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

createRoomHandler :: Maybe String -> CreateRoomRequest -> Handler CreateRoomResponse
createRoomHandler mCookieHeader req = do
  -- Bước 1: Parse Header Cookie để lấy session_id
  case mCookieHeader >>= parseSessionId of
    Nothing -> throwError err401 { errBody = "Vui lòng đăng nhập để tạo phòng!" }
    Just sID -> do
      
      -- Bước 2: Dùng session_id gọi DB lấy user_id (như đã cập nhật ở task trước)
      mUserId <- liftIO $ getUserBySession sID
      case mUserId of
        Nothing -> throwError err401 { errBody = "Phiên đăng nhập không hợp lệ hoặc đã hết hạn!" }
        Just uid -> do
          
          -- Bước 3: Dùng uid (user_id) làm owner_id để tạo phòng
          let newRoom =
                Room
                  { room_id       = "" 
                  , room_name     = roomNameRequest req
                  , room_password = passwordRequest req
                  , owner_id      = uid              -- Lấy từ DB
                  , user_ids      = [uid]            -- Lấy từ DB
                  , occupancy     = 1
                  , is_private    = isPrivateRequest req
                  }
          
          createdRoom <- liftIO (createRoom newRoom)
          
          -- Bước 4: Trả về kết quả
          let rDetail = RoomDetail
                { resRoomId    = room_id createdRoom
                , resRoomName  = room_name createdRoom
                , resIsPrivate = is_private createdRoom
                }
                
          return $ CreateRoomResponse
                { status = "success"
                , room   = rDetail
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

parseSessionId :: String -> Maybe Text
parseSessionId cookieHeader =
  let pairs = map (break (== '=')) $ wordsWhen (== ';') cookieHeader
      trim = reverse . dropWhile (== ' ') . reverse . dropWhile (== ' ')
  in case lookup "session_id" [(trim k, drop 1 (trim v)) | (k, v) <- pairs] of
       Just val -> Just (pack val)
       Nothing  -> Nothing
  where
    wordsWhen p s = case dropWhile p s of
                      "" -> []
                      s' -> let (w, s'') = break p s' in w : wordsWhen p s'
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedRecordDot #-}
{- HLINT ignore "Use newtype instead of data" -}

module Controllers.RoomController
  (
    createRoomHandler,
    getRoomsHandler,
    joinRoomHandler,
    leaveRoomHandler,
    CreateRoomRequest(..),
    CreateRoomResponse(..),
    RoomSummary(..),
    JoinRoomRequest(..),
    LeaveRoomRequest(..),
    StatusResponse(..),
  ) where

import Control.Monad.IO.Class (liftIO)
import Data.Aeson (FromJSON, ToJSON)
import Data.Text (Text, pack)
import GHC.Generics (Generic)
import Model.User (User(..))
import Servant

import Model.Rooms (Room(..), getRooms, createRoom, deleteRoom, joinRoom)
import Controllers.AuthController (withAuthenticatedUser)

-- ============================================================================
-- 1. REQUEST & RESPONSE MODELS (Khớp chính xác 100% với Spec JSON)
-- ============================================================================

-- POST /room/create
data CreateRoomRequest = CreateRoomRequest
  { room_name  :: Text
  , password   :: Text
  , is_private :: Bool
  } deriving (Show, Generic)
instance FromJSON CreateRoomRequest

data CreatedRoomDetail = CreatedRoomDetail
  { room_id   :: Text
  , room_name :: Text
  , owner_id  :: Text
  } deriving (Show, Generic)
instance ToJSON CreatedRoomDetail

data CreateRoomResponse = CreateRoomResponse
  { status :: Text
  , room   :: CreatedRoomDetail
  } deriving (Show, Generic)
instance ToJSON CreateRoomResponse

-- GET /room/getRooms
data RoomSummary = RoomSummary
  { room_name  :: Text
  , room_id    :: Text
  , occupation :: Text  -- Định dạng chuỗi "1/2" theo đúng spec
  } deriving (Show, Generic)
instance ToJSON RoomSummary

-- POST /room/joinRoom
data JoinRoomRequest = JoinRoomRequest
  { room_id  :: Text
  , password :: Text
  } deriving (Show, Generic)
instance FromJSON JoinRoomRequest

-- DELETE /room/leave
data LeaveRoomRequest = LeaveRoomRequest
  { room_id :: Text
  } deriving (Show, Generic)
instance FromJSON LeaveRoomRequest

-- Common Status Response {"status": "success" | "failure"}
data StatusResponse = StatusResponse
  { status :: Text
  } deriving (Show, Generic)
instance ToJSON StatusResponse


-- ============================================================================
-- 2. HANDLERS (Xử lý các endpoint phòng)
-- ============================================================================

-- POST /room/create
createRoomHandler :: Maybe String -> CreateRoomRequest -> Handler CreateRoomResponse
createRoomHandler cookie req = do
  -- Gọi withAuthenticatedUser và đẩy toàn bộ logic xuống dưới
  withAuthenticatedUser cookie $ \u -> do
    
    let uid = u.user_id -- Lấy trực tiếp user_id từ object u
    
    let newRoom = Room
          { room_id       = "" 
          , room_name     = req.room_name
          , room_password = req.password
          , owner_id      = uid    -- Gán uid lấy từ cookie
          , user_ids      = [uid]  -- Gán uid lấy từ cookie
          , occupancy     = 1
          , is_private    = req.is_private
          }
          
    created <- liftIO $ createRoom newRoom
    
    let rDetail = CreatedRoomDetail
          { room_id   = created.room_id
          , room_name = created.room_name
          , owner_id  = created.owner_id
          }
          
    return $ CreateRoomResponse "success" rDetail

-- GET /room/getRooms
getRoomsHandler :: Handler [RoomSummary]
getRoomsHandler = do
  rooms <- liftIO getRooms
  return $ map toSummary rooms
  where
    toSummary (Room rid rname _ _ _ occ _) = RoomSummary
      { room_name  = rname
      , room_id    = rid
      , occupation = pack (show occ ++ "/2") -- Chuyển occupancy Int -> "1/2"
      }

-- POST /room/joinRoom
joinRoomHandler :: Maybe String -> JoinRoomRequest -> Handler StatusResponse
joinRoomHandler cookie req = do
  withAuthenticatedUser cookie $ \u -> do
    let uid = u.user_id -- Lấy trực tiếp user_id từ object u
    -- Gọi hàm joinRoom từ Model.Rooms
    success <- liftIO $ joinRoom req.room_id req.password uid
    if success
      then return $ StatusResponse "success"
      else return $ StatusResponse "failure"

-- DELETE /room/leave
leaveRoomHandler :: Maybe String -> LeaveRoomRequest -> Handler StatusResponse
leaveRoomHandler cookie req = do
  -- Thực hiện xóa/rời phòng theo room_id và userId
  withAuthenticatedUser cookie $ \u -> do
    let uid = u.user_id
    liftIO $ deleteRoom req.room_id uid
    return $ StatusResponse "success" 

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
    JoinRoomResponse(..),
    LeaveRoomRequest(..),
    StatusResponse(..),
    RoomPagination(..),
    RoomsResponse(..),
  ) where

import Control.Monad.IO.Class (liftIO)
import Data.Aeson (FromJSON, ToJSON)
import Data.Text (Text, pack)
import qualified Data.Text as T
import GHC.Generics (Generic)
import Model.User (User(..))
import Servant

import Model.Rooms (Room(..),ValidationError(..),validateRoomName, getRooms, createRoom, getRoomById, joinRoomById, JoinResult(..))
import Controllers.AuthController (withAuthenticatedUser)
import Service.WsService (notifyPlayerJoined, handleLeave)
import Ws.Env (Env)

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
  , status :: Text
  } deriving (Show, Generic)
instance ToJSON CreatedRoomDetail

data CreateRoomResponse = CreateRoomResponse
  { status :: Text
  , room   :: CreatedRoomDetail
  } deriving (Show, Generic)
instance ToJSON CreateRoomResponse

-- POST /room/create
createRoomHandler :: Maybe String -> CreateRoomRequest -> Handler CreateRoomResponse
createRoomHandler cookie req = do
  withAuthenticatedUser cookie $ \u -> do
    case validateRoomName (T.unpack req.room_name) of
      Left RoomNameEmpty 
        -> throwError err400
          { errBody = "Room name cannot be empty" }
      Left RoomNameTooLong 
        -> throwError err400
          { errBody = "Room name is too long" }
      Right () -> do
        let uid = u.user_id
        let newRoom = Room
              { room_id       = ""
              , room_name     = req.room_name
              , room_password = req.password
              , owner_id      = uid
              , user_ids      = [uid]
              , occupancy     = 1
              , is_private    = req.is_private
              , status        = "waiting"
              }
        created <- liftIO $ createRoom newRoom
        let rDetail = CreatedRoomDetail
              { room_id   = created.room_id
              , room_name = created.room_name
              , owner_id  = created.owner_id
              , status    = created.status
              }
        return $ CreateRoomResponse "success" rDetail

-- GET /room/getRooms
data RoomSummary = RoomSummary
  { room_name  :: Text
  , room_id    :: Text
  , occupation :: Text  
  , is_private :: Bool
  , status     :: Text
  } deriving (Show, Generic)
instance ToJSON RoomSummary

data RoomPagination = RoomPagination
  { limit      :: Int
  , nextCursor :: Text
  } deriving (Show, Generic)
instance ToJSON RoomPagination

data RoomsResponse = RoomsResponse
  { rooms      :: [RoomSummary]
  , pagination :: RoomPagination
  } deriving (Show, Generic)
instance ToJSON RoomsResponse

-- GET /room/getRooms
getRoomsHandler :: Int -> Text -> Handler RoomsResponse
getRoomsHandler requestedLimit cursor = do
  let pageLimit = max 1 (min 20 requestedLimit)
  fetchedRooms <- liftIO $ getRooms (pageLimit + 1) cursor
  let pageRooms = take pageLimit fetchedRooms
      hasNextPage = length fetchedRooms > pageLimit
      pageCursor = case reverse pageRooms of
        Room rid _ _ _ _ _ _ _ : _ | hasNextPage -> rid
        _ -> ""
  return RoomsResponse
    { rooms = map toSummary pageRooms
    , pagination = RoomPagination
        { limit = pageLimit
        , nextCursor = pageCursor
        }
    }
  where
    toSummary (Room rid rname _ _ _ occ private rstatus) = RoomSummary
      { room_name  = rname
      , room_id    = rid
      , occupation = pack (show occ ++ "/2")
      , is_private = private
      , status     = rstatus
      }

-- POST /room/engagement 
data JoinRoomRequest = JoinRoomRequest
  { room_id  :: Text      
  , password :: Text
  } deriving (Show, Generic)
instance FromJSON JoinRoomRequest

data JoinRoomResponse= JoinRoomResponse
  {
    status::Text,
    room_id::Text
  }deriving (Show, Generic)
instance ToJSON JoinRoomResponse 
joinRoomHandler :: Env -> Maybe String -> JoinRoomRequest -> Handler JoinRoomResponse
joinRoomHandler env cookie req = do
  withAuthenticatedUser cookie $ \u -> do
    let uid = u.user_id
    result <- liftIO $ joinRoomById req.room_id req.password uid
    case result of
      JoinOk -> do
        liftIO $ notifyPlayerJoined env req.room_id uid
        return $ JoinRoomResponse "success" req.room_id
      _ -> return $ JoinRoomResponse "failure" ""

-- POST /room/leave
data LeaveRoomRequest = LeaveRoomRequest
  { room_id :: Text
  } deriving (Show, Generic)
instance FromJSON LeaveRoomRequest

leaveRoomHandler :: Env -> Maybe String -> LeaveRoomRequest -> Handler StatusResponse
leaveRoomHandler env cookie req =
  withAuthenticatedUser cookie $ \u -> do
    let uid = u.user_id
        rid = req.room_id
    mRoom <- liftIO $ getRoomById rid
    case mRoom of
      Just r | uid `elem` r.user_ids -> do
        liftIO $ handleLeave env rid uid   
        return $ StatusResponse "success"
      _ -> return $ StatusResponse "failure"

data StatusResponse = StatusResponse
  { status :: Text
  } deriving (Show, Generic)
instance ToJSON StatusResponse
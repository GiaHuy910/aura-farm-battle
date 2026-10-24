{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE OverloadedRecordDot #-}
module Ws.MongoStore (mongoStore) where

import           Control.Monad (forM_)
import           Data.List (find)
import           Data.Text (Text)
import           Model.Rooms (Room (..), addMember, deleteRoomById, getRoomById, removeMember, setRoomStatus)
import           Model.Session (getUserBySession)
import           Model.User (User (..), getUserById)
import           Ws.Types

toRoomInfo :: Room -> RoomInfo
toRoomInfo r = RoomInfo
  { riId     = r.room_id
  , riOwner  = r.owner_id
  , riGuest  = find (/= r.owner_id) r.user_ids
  , riStatus = parseStatus r.status
  }

parseStatus :: Text -> Status
parseStatus "playing"  = Playing
parseStatus "finished" = Finished
parseStatus _          = Waiting

mongoStore :: RoomStore
mongoStore = RoomStore
  { rsGetRoom = \rid -> fmap toRoomInfo <$> getRoomById rid
  , rsAddGuest = addMember
  , rsRemoveGuest = \rid -> do
      mRoom <- getRoomById rid
      forM_ mRoom $ \r ->
        forM_ (riGuest (toRoomInfo r)) (removeMember rid)
  , rsDeleteRoom = deleteRoomById
  , rsSetStatus = \rid s -> setRoomStatus rid (statusText s)
  , rsUserBySession = getUserBySession
  , rsUserProfile = \uid -> do
      mu <- getUserById uid
      pure $ case mu of
        Nothing -> PlayerProfile uid [] 0
        Just u  -> PlayerProfile u.username [u.equipped_acc, u.equipped_shirt, u.equipped_shoes] u.total_aura
  }
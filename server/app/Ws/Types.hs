{-# LANGUAGE OverloadedStrings #-}
module Ws.Types
  ( RoomId
  , UserId
  , Status (..)
  , statusText
  , RoomInfo (..)
  , isMember
  , RoomStore (..)
  , PlayerProfile (..)
  ) where

import Data.Text (Text)

type RoomId = Text
type UserId = Text

data Status = Waiting | Playing | Finished
  deriving (Eq, Show)

statusText :: Status -> Text
statusText Waiting  = "waiting"
statusText Playing  = "playing"
statusText Finished = "finished"

data RoomInfo = RoomInfo
  { riId     :: RoomId
  , riOwner  :: UserId
  , riGuest  :: Maybe UserId
  , riStatus :: Status
  }

isMember :: UserId -> RoomInfo -> Bool
isMember u r = u == riOwner r || riGuest r == Just u

data PlayerProfile = PlayerProfile
  { ppName    :: Text
  , ppClothes :: [Text]  
  , ppAura    :: Int    
  }

data RoomStore = RoomStore
  { rsGetRoom       :: RoomId -> IO (Maybe RoomInfo)
  , rsAddGuest      :: RoomId -> UserId -> IO Bool   
  , rsRemoveGuest   :: RoomId -> IO ()
  , rsDeleteRoom    :: RoomId -> IO ()
  , rsSetStatus     :: RoomId -> Status -> IO ()
  , rsUserBySession :: Text -> IO (Maybe UserId)   
  , rsUserProfile   :: UserId -> IO PlayerProfile   
  }
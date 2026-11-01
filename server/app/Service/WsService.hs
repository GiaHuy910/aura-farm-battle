{-# LANGUAGE OverloadedStrings #-}

module Service.WsService
  ( notifyPlayerJoined
  , joinRoom
  , handleLeave
  , startGame
  , onDisconnect
  ) where

import           Control.Concurrent (forkIO, threadDelay)
import           Control.Monad (forM_, unless, when)
import           Data.Aeson (object, (.=))
import           Data.Maybe (isJust)
import           Game.Registry (Phase (..), RoomGame (..), dropIfEnded, getGame)
import           Service.BattleService (forfeitMatch, startBattle) 
import           Service.RematchService (resetToLobby)            
import           Ws.Env
import qualified Ws.Hub as Hub
import           Ws.Message
import           Ws.Types

notifyPlayerJoined :: Env -> RoomId -> UserId -> IO ()
notifyPlayerJoined env rid uid = do
  p <- playerValue (envStore env) uid False
  Hub.broadcast (envHub env) rid (msg "room.player_joined" (object ["guest" .= p]))

joinRoom :: Env -> RoomId -> UserId -> IO Bool
joinRoom env rid uid = do
  ok <- rsAddGuest (envStore env) rid uid
  when ok (notifyPlayerJoined env rid uid)
  pure ok

handleLeave :: Env -> RoomId -> UserId -> IO ()
handleLeave env rid uid = do
  mRoom <- rsGetRoom st rid
  forM_ mRoom $ \room -> do
    when (riStatus room == Playing && isMember uid room) $
      forfeitMatch env room uid                         -- NEW
    if uid == riOwner room
      then if riStatus room /= Waiting
        then do
          Hub.broadcast hub rid
            (msg "room.player_offline" (object ["userId" .= uid]))
          Hub.closeUser hub rid uid
        else do
          rsDeleteRoom st rid
          dropIfEnded (envRegistry env) rid
          Hub.broadcast hub rid (msg "room.closed" (object []))
          Hub.closeRoom hub rid
      else when (riGuest room == Just uid) $ do
        rsRemoveGuest st rid
        Hub.closeUser hub rid uid
        Hub.broadcast hub rid (msg "room.player_left" (object ["userId" .= uid]))
        when (riStatus room /= Waiting) $ do
          mg <- getGame (envRegistry env) rid
          case mg of
            Just g | rgPhase g /= PhaseEnded -> pure ()
            _                                -> resetToLobby env rid
          deleteIfAbandoned env rid
  where
    st  = envStore env
    hub = envHub env

startGame :: Env -> RoomId -> UserId -> IO ()
startGame env rid uid = do
  mRoom <- rsGetRoom (envStore env) rid
  forM_ mRoom $ \room ->
    when (riStatus room == Waiting && uid == riOwner room && isJust (riGuest room)) $ do
      forM_ (riGuest room) $ \guest -> startBattle env rid uid guest

onDisconnect :: Env -> RoomId -> UserId -> Int -> IO ()
onDisconnect env rid uid cid = do
  wasCurrent <- Hub.unregisterIfCurrent (envHub env) rid uid cid
  when wasCurrent $ do
    Hub.broadcast (envHub env) rid (msg "room.player_offline" (object ["userId" .= uid]))
    tid <- forkIO $ do
      threadDelay (envGraceSecs env * 1000000)
      onGraceExpired env rid uid
    Hub.setTimer (envHub env) rid uid tid

onGraceExpired :: Env -> RoomId -> UserId -> IO ()
onGraceExpired env rid uid = do
  Hub.dropTimer (envHub env) rid uid
  online <- Hub.isOnline (envHub env) rid uid
  unless online $ do
    mRoom <- rsGetRoom (envStore env) rid
    forM_ mRoom $ \room -> case riStatus room of
      Playing -> forfeitMatch env room uid         
      _       -> handleLeave env rid uid      

    deleteIfAbandoned env rid

deleteIfAbandoned :: Env -> RoomId -> IO ()
deleteIfAbandoned env rid = do
  online  <- Hub.onlineUsers (envHub env) rid
  pending <- Hub.hasTimer (envHub env) rid
  when (null online && not pending) $ do
    rsDeleteRoom (envStore env) rid
    dropIfEnded (envRegistry env) rid              
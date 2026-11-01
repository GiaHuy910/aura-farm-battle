{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE OverloadedStrings #-}

module Ws.Hub
  ( Hub
  , Conn (..)
  , newHub
  , register
  , unregisterIfCurrent
  , onlineUsers
  , isOnline
  , broadcast
  , sendTo
  , sendToUser
  , claimChatSlot
  , closeConn
  , closeUser
  , closeRoom
  , setTimer
  , cancelTimer
  , dropTimer
  , hasTimer
  ) where

import           Control.Concurrent (ThreadId, killThread)
import           Control.Concurrent.STM
import           Control.Exception (SomeException, catch)
import           Control.Monad (forM_)
import qualified Data.ByteString.Lazy as BL
import qualified Data.Map.Strict as M
import           Data.Text (Text)
import           Data.Time (UTCTime, addUTCTime, diffUTCTime)
import qualified Network.WebSockets as WS
import           Ws.Types (RoomId, UserId)

data Conn = Conn
  { connId :: Int
  , connWs :: WS.Connection
  }

data Hub = Hub
  { hubConns  :: TVar (M.Map RoomId (M.Map UserId Conn))
  , hubTimers :: TVar (M.Map (RoomId, UserId) ThreadId) 
  , hubChatTimes :: TVar (M.Map UserId UTCTime)
  }

newHub :: IO Hub
newHub = Hub <$> newTVarIO M.empty <*> newTVarIO M.empty <*> newTVarIO M.empty

quiet :: IO () -> IO ()
quiet io = io `catch` \(_ :: SomeException) -> pure ()

sendTo :: Conn -> BL.ByteString -> IO ()
sendTo c p = quiet (WS.sendTextData (connWs c) p)

closeConn :: Conn -> IO ()
closeConn c = quiet (WS.sendClose (connWs c) ("bye" :: Text))

register :: Hub -> RoomId -> UserId -> Conn -> IO (Maybe Conn)
register hub rid uid c = do
  old <- atomically $ do
    m <- readTVar (hubConns hub)
    let roomMap = M.findWithDefault M.empty rid m
    writeTVar (hubConns hub) (M.insert rid (M.insert uid c roomMap) m)
    pure (M.lookup uid roomMap)
  cancelTimer hub rid uid
  pure old

unregisterIfCurrent :: Hub -> RoomId -> UserId -> Int -> IO Bool
unregisterIfCurrent hub rid uid cid = atomically $ do
  m <- readTVar (hubConns hub)
  case M.lookup rid m >>= M.lookup uid of
    Just c | connId c == cid -> do
      writeTVar (hubConns hub) (M.filter (not . M.null) (M.adjust (M.delete uid) rid m))
      pure True
    _ -> pure False

roomConns :: Hub -> RoomId -> IO [Conn]
roomConns hub rid = maybe [] M.elems . M.lookup rid <$> readTVarIO (hubConns hub)

onlineUsers :: Hub -> RoomId -> IO [UserId]
onlineUsers hub rid = maybe [] M.keys . M.lookup rid <$> readTVarIO (hubConns hub)

isOnline :: Hub -> RoomId -> UserId -> IO Bool
isOnline hub rid uid = elem uid <$> onlineUsers hub rid

broadcast :: Hub -> RoomId -> BL.ByteString -> IO ()
broadcast hub rid p = roomConns hub rid >>= mapM_ (`sendTo` p)

sendToUser :: Hub -> RoomId -> UserId -> BL.ByteString -> IO ()
sendToUser hub rid uid p = do
  m <- readTVarIO (hubConns hub)
  forM_ (M.lookup rid m >>= M.lookup uid) (`sendTo` p)

claimChatSlot :: Hub -> UserId -> UTCTime -> IO (Maybe Int)
claimChatSlot hub uid now = atomically $ do
  times <- readTVar (hubChatTimes hub)
  let activeTimes = M.filter (\sentAt -> diffUTCTime now sentAt < 15) times
  case M.lookup uid activeTimes of
    Just sentAt -> do
      writeTVar (hubChatTimes hub) activeTimes
      let remainingMs :: Int
          remainingMs = ceiling (diffUTCTime (addUTCTime 15 sentAt) now * 1000)
      pure (Just (max 1 remainingMs))
    Nothing -> do
      writeTVar (hubChatTimes hub) (M.insert uid now activeTimes)
      pure Nothing

closeUser :: Hub -> RoomId -> UserId -> IO ()
closeUser hub rid uid = do
  mc <- atomically $ do
    m <- readTVar (hubConns hub)
    writeTVar (hubConns hub) (M.filter (not . M.null) (M.adjust (M.delete uid) rid m))
    pure (M.lookup rid m >>= M.lookup uid)
  forM_ mc closeConn

closeRoom :: Hub -> RoomId -> IO ()
closeRoom hub rid = do
  cs <- atomically $ do
    m <- readTVar (hubConns hub)
    writeTVar (hubConns hub) (M.delete rid m)
    pure (maybe [] M.elems (M.lookup rid m))
  mapM_ closeConn cs

setTimer :: Hub -> RoomId -> UserId -> ThreadId -> IO ()
setTimer hub rid uid tid =
  atomically $ modifyTVar' (hubTimers hub) (M.insert (rid, uid) tid)

dropTimer :: Hub -> RoomId -> UserId -> IO ()
dropTimer hub rid uid =
  atomically $ modifyTVar' (hubTimers hub) (M.delete (rid, uid))

hasTimer :: Hub -> RoomId -> IO Bool
hasTimer hub rid = any ((== rid) . fst) . M.keys <$> readTVarIO (hubTimers hub)

cancelTimer :: Hub -> RoomId -> UserId -> IO ()
cancelTimer hub rid uid = do
  mt <- atomically $ do
    m <- readTVar (hubTimers hub)
    writeTVar (hubTimers hub) (M.delete (rid, uid) m)
    pure (M.lookup (rid, uid) m)
  forM_ mt killThread
{-# LANGUAGE OverloadedStrings #-}

module Config.Database (runDB) where

import Control.Concurrent.MVar (MVar, modifyMVar, newMVar)
import System.IO.Unsafe (unsafePerformIO)

import Database.MongoDB (Action, Pipe, access, connect, host, isClosed, master)

{-# NOINLINE pipeVar #-}
pipeVar :: MVar (Maybe Pipe)
pipeVar = unsafePerformIO (newMVar Nothing)

getPipe :: IO Pipe
getPipe = modifyMVar pipeVar $ \mp -> do
  usable <- case mp of
    Nothing -> pure Nothing
    Just p  -> do
      closed <- isClosed p
      pure (if closed then Nothing else Just p)
  p <- maybe (connect (host "127.0.0.1")) pure usable
  pure (Just p, p)

-- used to be a deadlock issue here with close
runDB :: Action IO a -> IO a
runDB action = do
  pipe <- getPipe
  access pipe master "aura-farm-battle" action
{-# LANGUAGE OverloadedStrings #-}

module Service.RematchService
  ( enterEnded
  , playAgain
  , resetToLobby
  ) where

import           Control.Monad (forM_, when)
import           Data.Aeson (object, (.=))
import           Data.List (nub)
import           Data.Maybe (isNothing)
import           Game.Registry
import           Service.RoomView (sendRoomStateToAll)
import           Ws.Env
import qualified Ws.Hub as Hub
import           Ws.Message
import           Ws.Types

enterEnded :: Env -> RoomId -> IO ()
enterEnded env rid = do
  updateGame (envRegistry env) rid (\g -> g { rgPhase = PhaseEnded, rgAgain = [] })
  mRoom <- rsGetRoom (envStore env) rid
  case mRoom of
    Nothing -> deleteGame (envRegistry env) rid    
    Just room
      | isNothing (riGuest room) -> resetToLobby env rid 
      | otherwise ->
          Hub.broadcast (envHub env) rid (msg "match.ended" (object ["ready" .= ([] :: [UserId])]))

playAgain :: Env -> RoomId -> UserId -> IO ()
playAgain env rid uid = do
  mRoom <- rsGetRoom (envStore env) rid
  forM_ mRoom $ \room -> when (isMember uid room) $ do
    r <- modifyGame (envRegistry env) rid $ \g ->
      if rgPhase g /= PhaseEnded
        then (g, Nothing)
        else let again = nub (rgAgain g ++ [uid]) in (g { rgAgain = again }, Just again)
    case r of
      Just (Just again) -> do
        Hub.broadcast (envHub env) rid (msg "rematch.status" (object ["ready" .= again]))
        let members = riOwner room : maybe [] pure (riGuest room)
        when (length members == 2 && all (`elem` again) members) $
          resetToLobby env rid
      _ -> pure ()

resetToLobby :: Env -> RoomId -> IO ()
resetToLobby env rid = do
  deleteGame (envRegistry env) rid
  rsSetStatus (envStore env) rid Waiting
  Hub.broadcast (envHub env) rid (msg "room.reset" (object []))
  sendRoomStateToAll env rid
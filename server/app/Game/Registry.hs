{-# LANGUAGE OverloadedStrings #-}

module Game.Registry
  ( Phase (..)
  , RoomGame (..)
  , Registry
  , newRegistry
  , getGame
  , putGame
  , deleteGame
  , modifyGame
  , updateGame
  , dropIfEnded
  ) where

import           Control.Concurrent.STM
import qualified Data.Map.Strict as M
import           Data.Aeson (Value)
import           Data.Text (Text)
import           Data.Time (UTCTime)
import           Game.Types
import           Ws.Types (RoomId, UserId)

data Phase
  = PhaseBattle  
  | PhaseReward  
  | PhaseEnded
  deriving (Eq, Show)

data RoomGame = RoomGame
  { rgPhase    :: Phase
  , rgBattle   :: Battle
  , rgOpen     :: Bool         
  , rgMatchId  :: Maybe Text
  , rgWinner   :: Maybe UserId
  , rgLoser    :: Maybe UserId
  , rgFinished :: Maybe Value            
  , rgOffer    :: Maybe (Value, UTCTime) 
  , rgResult   :: Maybe Value         
  , rgAgain    :: [UserId]             
  , rgEffectsDone :: [UserId]
  }

newtype Registry = Registry (TVar (M.Map RoomId RoomGame))

newRegistry :: IO Registry
newRegistry = Registry <$> newTVarIO M.empty

getGame :: Registry -> RoomId -> IO (Maybe RoomGame)
getGame (Registry v) rid = M.lookup rid <$> readTVarIO v

putGame :: Registry -> RoomId -> RoomGame -> IO ()
putGame (Registry v) rid g = atomically (modifyTVar' v (M.insert rid g))

deleteGame :: Registry -> RoomId -> IO ()
deleteGame (Registry v) rid = atomically (modifyTVar' v (M.delete rid))

modifyGame :: Registry -> RoomId -> (RoomGame -> (RoomGame, a)) -> IO (Maybe a)
modifyGame (Registry v) rid f = atomically $ do
  m <- readTVar v
  case M.lookup rid m of
    Nothing -> pure Nothing
    Just g  -> do
      let (g', a) = f g
      writeTVar v (M.insert rid g' m)
      pure (Just a)

updateGame :: Registry -> RoomId -> (RoomGame -> RoomGame) -> IO ()
updateGame reg rid f = () <$ modifyGame reg rid (\g -> (f g, ()))

dropIfEnded :: Registry -> RoomId -> IO ()
dropIfEnded (Registry v) rid = atomically $ modifyTVar' v $ \m ->
  case M.lookup rid m of
    Just g | rgPhase g == PhaseEnded -> M.delete rid m
    _                                -> m
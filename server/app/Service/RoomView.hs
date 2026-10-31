{-# LANGUAGE OverloadedStrings #-}

module Service.RoomView
  ( roomStateFor
  , sendRoomState
  , sendRoomStateToAll
  ) where

import           Control.Monad (forM_, when)
import           Data.Aeson (Value (..), object, toJSON, (.=))
import           Data.Maybe (isNothing)
import           Data.Time (UTCTime, diffUTCTime, getCurrentTime)
import           Game.Registry
import           Game.Types (Battle (..))
import           Game.View
import           Ws.Env
import qualified Ws.Hub as Hub
import           Ws.Message
import           Ws.Types

roomStateFor :: Env -> RoomId -> UserId -> IO (Maybe Value)
roomStateFor env rid uid = do
  mRoom <- rsGetRoom st rid
  case mRoom of
    Nothing    -> pure Nothing
    Just room0 -> do
      mg <- getGame (envRegistry env) rid

      when (riStatus room0 /= Waiting && isNothing mg) $
        rsSetStatus st rid Waiting
      let room = if riStatus room0 /= Waiting && isNothing mg
                   then room0 { riStatus = Waiting } else room0
      online <- Hub.onlineUsers (envHub env) rid
      let isOn u = u `elem` online
      owner <- playerValue st (riOwner room) (isOn (riOwner room))
      guest <- traverse (\g -> playerValue st g (isOn g)) (riGuest room)
      now   <- getCurrentTime
      pure $ Just $ object
        [ "status" .= statusText (riStatus room)
        , "owner"  .= owner
        , "guest"  .= guest
        , "game"   .= fmap (gameValue uid now) mg
        ]
  where
    st = envStore env

gameValue :: UserId -> UTCTime -> RoomGame -> Value
gameValue uid now g = object
  [ "phase"    .= phaseText (rgPhase g)
  , "battle"   .= battleViewFor uid b roundLeft
  , "finished" .= rgFinished g
  , "offer"    .= fmap offerWithTime (rgOffer g)
  , "result"   .= rgResult g
  , "rematch"  .= rgAgain g
  ]
  where
    b = rgBattle g
    roundLeft | rgOpen g  = bDeadline b >>= Just . msUntil now
              | otherwise = Nothing
    offerWithTime (v, dl) = withField "timeLeftMs" (toJSON (msUntil now dl)) v

msUntil :: UTCTime -> UTCTime -> Int
msUntil now dl = max 0 (round (diffUTCTime dl now * 1000))

phaseText :: Phase -> String
phaseText PhaseBattle = "battle"
phaseText PhaseReward = "reward"
phaseText PhaseEnded  = "ended"

sendRoomState :: Env -> RoomId -> UserId -> IO ()
sendRoomState env rid uid = do
  mv <- roomStateFor env rid uid
  forM_ mv $ \v -> Hub.sendToUser (envHub env) rid uid (msg "room.state" v)

sendRoomStateToAll :: Env -> RoomId -> IO ()
sendRoomStateToAll env rid = do
  users <- Hub.onlineUsers (envHub env) rid
  forM_ users (sendRoomState env rid)
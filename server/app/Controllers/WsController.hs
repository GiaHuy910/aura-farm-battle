{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Controllers.WsController (wsHandler) where

import           Control.Exception (catch, finally)
import           Control.Monad (forM_)
import           Control.Monad.IO.Class (liftIO)
import           Data.Aeson (decode, object, (.=))
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BL
import qualified Data.Text.Encoding as TE
import qualified Data.Text.Encoding.Error as TEE
import           Data.Unique (hashUnique, newUnique)
import qualified Network.WebSockets as WS
import           Servant (Handler)
import           Service.WsService
import           Web.Cookie (parseCookies)
import           Ws.Env
import qualified Ws.Hub as Hub
import           Ws.Message
import           Ws.Types

wsHandler :: Env -> RoomId -> WS.PendingConnection -> Handler ()
wsHandler env rid pending = liftIO $ do
  let hdrs = WS.requestHeaders (WS.pendingRequest pending)
  if not (originAllowed env (lookup "Origin" hdrs))
    then WS.rejectRequest pending "bad origin"       
    else do
      mUid <- userFromCookie env (lookup "Cookie" hdrs) 
      case mUid of
        Nothing  -> WS.rejectRequest pending "unauthorized"
        Just uid -> do
          mRoom <- rsGetRoom (envStore env) rid
          case mRoom of
            Just room | isMember uid room -> runSession env rid uid pending
            _                             -> WS.rejectRequest pending "not a member"

runSession :: Env -> RoomId -> UserId -> WS.PendingConnection -> IO ()
runSession env rid uid pending = do
  conn <- WS.acceptRequest pending
  cid  <- hashUnique <$> newUnique
  let me = Hub.Conn cid conn

  old <- Hub.register hub rid uid me                 
  forM_ old $ \c -> do                              
    Hub.sendTo c (msg "room.kicked" (object []))
    Hub.closeConn c

  sendSnapshot env rid me                           
  Hub.broadcast hub rid (msg "room.player_online" (object ["userId" .= uid]))

  (WS.withPingThread conn 20 (pure ())
      (receiveLoop env rid uid conn `catch` \(_ :: WS.ConnectionException) -> pure ()))
    `finally` onDisconnect env rid uid cid         
  where
    hub = envHub env

sendSnapshot :: Env -> RoomId -> Hub.Conn -> IO ()
sendSnapshot env rid conn = do
  mRoom <- rsGetRoom st rid
  forM_ mRoom $ \room -> do
    online <- Hub.onlineUsers (envHub env) rid
    let isOn u = u `elem` online
    owner <- playerValue st (riOwner room) (isOn (riOwner room))
    guest <- traverse (\g -> playerValue st g (isOn g)) (riGuest room)
    Hub.sendTo conn $ msg "room.state" $ object
      [ "status" .= statusText (riStatus room)
      , "owner"  .= owner
      , "guest"  .= guest                     
      ]
  where
    st = envStore env

receiveLoop :: Env -> RoomId -> UserId -> WS.Connection -> IO ()
receiveLoop env rid uid conn = loop
  where
    loop = do
      raw <- WS.receiveData conn :: IO BL.ByteString
      case decode raw of
        Just (ClientMsg "room.leave" _) -> handleLeave env rid uid  
        Just m  -> dispatch env rid uid m >> loop
        Nothing -> loop                                            

dispatch :: Env -> RoomId -> UserId -> ClientMsg -> IO ()
dispatch env rid uid (ClientMsg t _) = do
  mRoom <- rsGetRoom (envStore env) rid
  forM_ mRoom $ \room -> case (riStatus room, t) of
    (Waiting, "room.start")  -> startGame env rid uid
    (Playing, "game.action") -> putStrLn "TODO: kiểm tra lượt, tính damage ở server, broadcast game.state_update"
    _                        -> pure ()

originAllowed :: Env -> Maybe BS.ByteString -> Bool
originAllowed env = maybe False (`elem` envAllowedOrigins env)

userFromCookie :: Env -> Maybe BS.ByteString -> IO (Maybe UserId)
userFromCookie env mHdr =
  case mHdr >>= \h -> lookup "session_id" (parseCookies h) of
    Nothing  -> pure Nothing
    Just sid -> rsUserBySession (envStore env) (TE.decodeUtf8With TEE.lenientDecode sid)
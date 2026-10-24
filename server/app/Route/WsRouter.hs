{-# LANGUAGE DataKinds     #-}
{-# LANGUAGE TypeOperators #-}

module Route.WsRouter (WsRouter) where

import Servant
import Servant.API.WebSocket (WebSocketPending)
import Ws.Types (RoomId)

type WsRouter = "ws" :> "rooms" :> Capture "roomId" RoomId :> WebSocketPending
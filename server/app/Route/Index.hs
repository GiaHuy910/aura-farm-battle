{-# LANGUAGE TypeOperators #-}
module Route.Index(Router) where

import Servant

import Route.RoomRouter( RoomRouter)
import Route.AuthRouter( AuthRouter)
import Route.UserRouter( UserRouter)
import Route.PoolRouter( PoolRouter)
import Route.GachaHistoryRouter( GachaHistoryRouter)
import Route.GiftcodeRouter( GiftcodeRouter)
import Route.WsRouter(WsRouter)

type Router =
         AuthRouter
    :<|> RoomRouter
    :<|> UserRouter
    :<|> PoolRouter
    :<|> GachaHistoryRouter
    :<|> GiftcodeRouter
    :<|> WsRouter
{-# LANGUAGE TypeOperators #-}
module Route.Index where
import Route.RoomRouter( RoomRouter)
import Route.AuthRouter( AuthRouter)
import Servant
type Router =
         AuthRouter
    :<|> RoomRouter
   
{-# LANGUAGE TypeOperators #-}
module Route.Index(Router) where
import Route.RoomRouter( RoomRouter)
import Route.AuthRouter( AuthRouter)
import Route.UserRouter( UserRouter)
import Servant
type Router =
         AuthRouter
    :<|> RoomRouter
    :<|> UserRouter
   
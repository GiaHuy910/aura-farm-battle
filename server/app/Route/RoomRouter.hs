{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
module Route.RoomRouter
    (
     RoomRouter
    )where 

import Controllers.RoomController
    ( CreateRoomRequest(..)
    , CreateRoomResponse(..)
    , JoinRoomRequest(..)
    , JoinRoomResponse(..)
    , LeaveRoomRequest(..)
    , RoomsResponse
    , StatusResponse(..)
    )
import Data.Text (Text)
import Servant

type RoomRouter =
       "room"
           :> QueryParam' '[Required, Strict] "limit" Int
           :> QueryParam' '[Required, Strict] "cursor" Text
           :> Get '[JSON] RoomsResponse

    :<|> "room"
           :> Header "Cookie" String
           :> ReqBody '[JSON] CreateRoomRequest
           :> Post '[JSON] CreateRoomResponse

    :<|> "room" :> "engagement"
                :> Header "Cookie" String
                :> ReqBody '[JSON] JoinRoomRequest
                :> Post '[JSON] JoinRoomResponse

    :<|> "room" :> "leave"
            :> Header "Cookie" String
            :> ReqBody '[JSON] LeaveRoomRequest
            :> Post '[JSON] StatusResponse

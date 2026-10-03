{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
module Route.RoomRouter
    (
     RoomRouter
    )where 

import Controllers.RoomController( RoomSummary(..), CreateRoomRequest(..), CreateRoomResponse(..), LeaveRoomRequest(..), StatusResponse(..), JoinRoomRequest(..))
import Servant

type RoomRouter =
       "room"
           :> Get '[JSON] [RoomSummary]

    :<|> "room"
           :> Header "Cookie" String
           :> ReqBody '[JSON] CreateRoomRequest
           :> Post '[JSON] CreateRoomResponse

    :<|> "room" :> "engagement"
                :> Header "Cookie" String
                :> ReqBody '[JSON] JoinRoomRequest
                :> Post '[JSON] StatusResponse

    :<|> "room" :> "leave"
            :> Header "Cookie" String
            :> ReqBody '[JSON] LeaveRoomRequest
            :> Post '[JSON] StatusResponse

{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
module Route.RoomRouter
    (
     RoomRouter
    )where 

import Controllers.RoomController( RoomSummary(..), CreateRoomRequest(..), CreateRoomResponse(..), LeaveRoomRequest(..), StatusResponse(..))
import Servant

type RoomRouter =
       "room" :> "getRooms"
           :> Get '[JSON] [RoomSummary]

  :<|> "room" :> "createRoom"
           :> Header "Cookie" String
           :> ReqBody '[JSON] CreateRoomRequest
           :> Post '[JSON] CreateRoomResponse

  :<|> "room" :> "leave"
            :> ReqBody '[JSON] LeaveRoomRequest
            :> Post '[JSON] StatusResponse
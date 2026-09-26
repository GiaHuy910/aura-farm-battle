{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
module Route.RoomRouter where 

import Controllers.RoomController( RoomResponse, CreateRoomRequest)
import Servant

type RoomRouter =
       "room" :> "getRooms"
           :> Get '[JSON] [RoomResponse]

  :<|> "room" :> "create"
           :> ReqBody '[JSON] CreateRoomRequest
           :> Post '[JSON] CreateRoomResponse

  :<|> "room"
           :> Capture "roomName" String
           :> Capture "ownerID" String
           :> Delete '[JSON] NoContent
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
module Route.RoomRouter where 

import Controllers.RoomController( RoomSummary, CreateRoomRequest)
import Servant

type RoomRouter =
       "room" :> "getRooms"
           :> Get '[JSON] [RoomSummary]

  :<|> "room" :> "create"
           :> Header "Cookie" String
           :> ReqBody '[JSON] CreateRoomRequest
           :> Post '[JSON] CreateRoomResponse

  :<|> "room"
           :> Capture "roomName" String
           :> Capture "ownerID" String
           :> Delete '[JSON] NoContent

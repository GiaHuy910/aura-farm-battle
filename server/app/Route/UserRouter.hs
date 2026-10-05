{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
module Route.UserRouter(UserRouter) where

import Controllers.UserController (EquippedSkillsResponse(..), EquippedClothesResponse(..), TicketsResponse(..), OwnedItemsResponse(..))
import Servant

type UserRouter =
    "user" :> "equipped-skills"
           :> Header "Cookie" String
           :> Get '[JSON] EquippedSkillsResponse 
    :<|>"user" :> "equipped-clothes"
           :> Header "Cookie" String
           :> Get '[JSON] EquippedClothesResponse  
    :<|>"user" :> "tickets"
           :> Header "Cookie" String
           :> Get '[JSON] TicketsResponse  
    :<|>"user" :> "owned-items"
               :> Header "Cookie" String
               :> Get '[JSON] OwnedItemsResponse
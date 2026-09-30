{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
module Route.UserController where

import Controller.UserController (EquippedSkillsResponse, OwnedSkillsResponse, EquippedClothesResponse, OwnedClothesResponse, TicketsResponse, AvatarResponse )
import Servant

type UserController =
    "user" :> "equipped-skills"
           :> Header "Cookie" String
           :> Get '[JSON] EquippedSkillsResponse 
    "user" :> "owned-skills"
           :> Header "Cookie" String
           :> Get '[JSON] OwnedSkillsResponse 
    "user" :> "equipped-clothes"
           :> Header "Cookie" String
           :> Get '[JSON] EquippedClothesResponse 
    "user" :> "owned-clothes"
           :> Header "Cookie" String
           :> Get '[JSON] OwnedClothesResponse  
    "user" :> "tickets"
           :> Header "Cookie" String
           :> Get '[JSON] TicketsResponse  
    "user" :> "avatar"
           :> Header "Cookie" String
           :> Get '[JSON] AvatarResponse  
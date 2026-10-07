{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
module Route.UserRouter(UserRouter) where

import Controllers.UserController (EquippedSkillsResponse(..), EquippedClothesResponse(..), TicketsResponse(..), OwnedItemsResponse(..), GachaRequest(..), GachaResponse(..), EquipRequest(..), EquipResponse(..))
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
    :<|>"user" :> "gacha"
               :> Header "Cookie" String
               :> ReqBody '[JSON] GachaRequest
               :> Post '[JSON] GachaResponse
    :<|>"user" :> "equip-item"
               :> Header "Cookie" String
               :> ReqBody '[JSON] EquipRequest
               :> Post '[JSON] EquipResponse
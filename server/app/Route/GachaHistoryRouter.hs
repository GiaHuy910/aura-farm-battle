{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
module Route.GachaHistoryRouter (GachaHistoryRouter)  
where

import Servant
import Data.Text (Text)
import Model.GachaHistory (GachaHistoryResponse)

type GachaHistoryRouter = "gacha-history" 
        :> Header "Cookie" String 
        :> QueryParam "limit" Int 
        :> QueryParam "cursor" Text 
        :> QueryParam "item_type" Text
        :> Get '[JSON] GachaHistoryResponse
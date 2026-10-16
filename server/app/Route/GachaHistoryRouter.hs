{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

module Route.GachaHistoryRouter (GachaHistoryRouter) where

import Servant
import Data.Text (Text)
import Controllers.GachaHistoryController (GachaHistoryResponse)

type GachaHistoryRouter = "gacha-history" 
        :> Header "Cookie" String 
        :> QueryParam' '[Required, Strict] "limit" Int 
        :> QueryParam' '[Required, Strict] "cursor" Text 
        :> QueryParam' '[Required, Strict] "item_type" Text
        :> Get '[JSON] GachaHistoryResponse
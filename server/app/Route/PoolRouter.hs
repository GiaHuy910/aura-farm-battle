{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE OverloadedStrings #-}

module Route.PoolRouter (PoolRouter) where

import Servant
import Controllers.PoolController (PoolResponse(..))
import Controllers.PoolController (getPoolHandler) -- Nhớ import handler

type PoolRouter =
    "pool"
        :> Header "Cookie" String
        :> Get '[JSON] PoolResponse
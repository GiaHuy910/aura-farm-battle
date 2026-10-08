{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE OverloadedStrings #-}

module Route.PoolRouter (PoolRouter) where

import Servant
import Controllers.PoolController( PoolResponse(..) ) -- Nhớ import handler

type PoolRouter =
    "pool"
        :> Get '[JSON] PoolResponse
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE DeriveGeneric #-}
{- HLINT ignore "Use newtype instead of data" -}
module Controllers.PoolController 
(getPoolHandler,
PoolResponse(..),
PoolData(..)
)where


import GHC.Generics
import Data.Aeson (ToJSON)
import Control.Monad.IO.Class (liftIO)
import Servant

import Model.Clothe (Clothe, getClothesPool)
import Model.Skill (Skill, getSkillsPool)
import Controllers.AuthController (withAuthenticatedUser)

data PoolData = PoolData
    {
        clothe :: [Clothe]
        , skill :: [Skill]
    } deriving(Show, Generic)
instance ToJSON PoolData

data PoolResponse = PoolResponse
    {
        pool :: PoolData
    } deriving(Show, Generic)
instance ToJSON PoolResponse

getPoolHandler :: Maybe String -> Handler PoolResponse
getPoolHandler cookie = withAuthenticatedUser cookie $ \_ -> do
    clothes <- liftIO getClothesPool
    skills <- liftIO getSkillsPool
    let poolData = PoolData clothes skills
    return $ PoolResponse poolData
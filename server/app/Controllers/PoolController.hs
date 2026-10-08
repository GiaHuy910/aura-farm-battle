{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedRecordDot #-}
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
import Data.Text (Text)

import Model.Clothe (Clothe(..), getClothesPool)
import Model.Skill (Skill(..), getSkillsPool)
import Controllers.AuthController (withAuthenticatedUser)

data PoolData = PoolData
    {
        item_id  :: Text
        , rarity :: Text
    } deriving(Show, Generic)
instance ToJSON PoolData

data PoolResponse = PoolResponse
    {
        clothe :: [PoolData]
        , skill :: [PoolData]
    } deriving(Show, Generic)
instance ToJSON PoolResponse

getPoolHandler :: Handler PoolResponse
getPoolHandler = do
    rawClothes <- liftIO getClothesPool
    rawSkills <- liftIO getSkillsPool

    let cleanClothes = map clothesToPoolData rawClothes
        cleanSkills = map skillsToPoolData rawSkills
    return $ PoolResponse
        {
        clothe = cleanClothes
    ,   skill = cleanSkills
    }

clothesToPoolData :: Clothe -> PoolData
clothesToPoolData c = PoolData
    {
        item_id = c.clothe_id
    ,   rarity = c.rarity
    }

skillsToPoolData :: Skill -> PoolData
skillsToPoolData s = PoolData
    {
        item_id = s.skill_id
    ,   rarity = s.rarity
    }
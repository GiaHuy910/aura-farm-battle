{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE DuplicateRecordFields #-}
module Controllers.PoolController where

import GHC.Generics (Generic)
import Data.Aeson (ToJSON)
import Data.Text (Text)
import Servant
import Model.Clothe (Clothe(..), getClothesPool)
import Model.Skill (Skill(..), Effect(..), getSkillsPool)
import Control.Monad.IO.Class (liftIO)

data ClothePoolItem = ClothePoolItem
  { clothe_id   :: Text
  , clothe_name :: Text
  , rarity      :: Text
  , aura_bonus  :: Int
  } deriving (Show, Generic)
instance ToJSON ClothePoolItem

data SkillPoolItem = SkillPoolItem
  { skill_id            :: Text
  , skill_name          :: Text
  , energy_consumption  :: Int
  , energy_recovery     :: Int
  , aura_multiplier     :: Double
  , rarity              :: Text
  , effect              :: Effect 
  } deriving (Show, Generic)
instance ToJSON SkillPoolItem

data PoolResponse = PoolResponse
  { clothe :: [ClothePoolItem]
  , skill  :: [SkillPoolItem]
  } deriving (Show, Generic)
instance ToJSON PoolResponse

clotheToItem :: Clothe -> ClothePoolItem
clotheToItem c = ClothePoolItem
  { clothe_id   = c.clothe_id
  , clothe_name = c.clothe_name
  , rarity      = c.rarity
  , aura_bonus  = c.aura_bonus
  }

skillToItem :: Skill -> SkillPoolItem
skillToItem s = SkillPoolItem
  { skill_id            = s.skill_id
  , skill_name          = s.skill_name
  , energy_consumption  = s.energy_consumption
  , energy_recovery     = s.energy_recovery
  , aura_multiplier     = s.aura_multiplier
  , rarity              = s.rarity
  , effect              = s.effect
  }

getPoolHandler :: Handler PoolResponse
getPoolHandler = do
    rawClothes <- liftIO getClothesPool
    rawSkills  <- liftIO getSkillsPool
    
    return $ PoolResponse
      { clothe = Prelude.map clotheToItem rawClothes
      , skill  = Prelude.map skillToItem rawSkills
      }
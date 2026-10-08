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
import Model.Skill (Skill(..), getSkillsPool)
import Control.Monad.IO.Class (liftIO)

-- DTO cho từng món Clothe trong Pool
data ClothePoolItem = ClothePoolItem
  { clothe_id   :: Text
  , clothe_name :: Text
  , rarity      :: Text
  } deriving (Show, Generic)
instance ToJSON ClothePoolItem

-- DTO cho từng món Skill trong Pool
data SkillPoolItem = SkillPoolItem
  { skill_id   :: Text
  , skill_name :: Text
  , rarity     :: Text
  } deriving (Show, Generic)
instance ToJSON SkillPoolItem

-- Struct Response chính cho API GET /pool
data PoolResponse = PoolResponse
  { clothe :: [ClothePoolItem]
  , skill  :: [SkillPoolItem]
  } deriving (Show, Generic)
instance ToJSON PoolResponse

-- Mapper cho Clothe
clotheToItem :: Clothe -> ClothePoolItem
clotheToItem c = ClothePoolItem
  { clothe_id   = c.clothe_id
  , clothe_name = c.clothe_name
  , rarity      = c.rarity
  }

-- Mapper cho Skill
skillToItem :: Skill -> SkillPoolItem
skillToItem s = SkillPoolItem
  { skill_id   = s.skill_id
  , skill_name = s.skill_name
  , rarity     = s.rarity
  }

-- Handler xử lý
getPoolHandler :: Maybe String -> Handler PoolResponse
getPoolHandler _cookie = do
    rawClothes <- liftIO getClothesPool
    rawSkills  <- liftIO getSkillsPool
    
    return $ PoolResponse
      { clothe = Prelude.map clotheToItem rawClothes
      , skill  = Prelude.map skillToItem rawSkills
      }
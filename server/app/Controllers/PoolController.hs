module Controllers.PoolController where

import GHC.Generics (Generic)
import Data.Aeson (ToJSON)
import Data.Text (Text)
import Servant
import Model.Clothe (Clothe(..), getClothesPool)
import Model.Skill (Skill(..), getSkillsPool)

-- 1. Struct dữ liệu từng Item trong Pool
data PoolData = PoolData
  { item_id   :: Text
  , item_name :: Text
  } deriving (Show, Generic)

instance ToJSON PoolData

-- 2. Struct Response trả về (dùng số ít `clothe` và `skill` )
data PoolResponse = PoolResponse
  { clothe :: [PoolData]
  , skill  :: [PoolData]
  } deriving (Show, Generic)

instance ToJSON PoolResponse

-- 3. Các hàm Map dữ liệu
clothesToPoolData :: Clothe -> PoolData
clothesToPoolData c = PoolData
  { item_id   = c.clothe_id
  , item_name = c.clothe_name
  }

skillsToPoolData :: Skill -> PoolData
skillsToPoolData s = PoolData
  { item_id   = s.skill_id
  , item_name = s.skill_name
  }

-- 4. Handler API
getPoolHandler :: Maybe String -> Handler PoolResponse
getPoolHandler _cookie = do
    rawClothes <- liftIO getClothesPool
    rawSkills  <- liftIO getSkillsPool
    
    let cleanClothes = Prelude.map clothesToPoolData rawClothes
        cleanSkills  = Prelude.map skillsToPoolData rawSkills
        
    return $ PoolResponse
      { clothe = cleanClothes
      , skill  = cleanSkills
      }
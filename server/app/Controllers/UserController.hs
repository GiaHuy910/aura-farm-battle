{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedRecordDot #-}
{- HLINT ignore "Use newtype instead of data" -}

module Controllers.UserController
  ( getTicketsHandler
  , getAvatarHandler
  , getEquippedSkillsHandler
  , getOwnedSkillsHandler
  , getEquippedClothesHandler
  , getOwnedClothesHandler
  , getGachaHandler
  , gachaX1Handler
  , gachaX10Handler
  , gachaSkillX1Handler
  , gachaSkillX10Handler
  , TicketsResponse(..)
  , AvatarResponse(..)
    , EquippedSkillsResponse(..)
    , OwnedSkillsResponse(..)
    , EquippedClothesResponse(..)
    , OwnedClothesResponse(..)
    , GachaResponse(..)
  ) where

import Control.Monad (replicateM)
import Control.Monad.IO.Class
import Data.Aeson hiding (Result(..))
import Data.Text (Text)
import GHC.Generics
import Servant
import System.Random (randomRIO)

import Model.User ( User(..), ItemType(..), deductTickets, addGachaItems )
import Model.Clothe (Clothe(..), getClothesPool)
import Model.Skill (Skill(..), getSkillsPool)
import qualified Model.Clothe as Clothe
import qualified Model.Skill as Skill
import Controllers.AuthController (withAuthenticatedUser)

-- ============================================================================
-- 1. RESPONSE MODELS (Khớp 100% với tên Key trong API Spec)
-- ============================================================================

-- GET user/tickets -> {"tickets": 100}
data TicketsResponse = TicketsResponse { tickets :: Int } deriving (Show, Generic)
instance ToJSON TicketsResponse

-- GET user/avatar -> {"avatar": ""}
data AvatarResponse = AvatarResponse { avatar :: Text } deriving (Show, Generic)
instance ToJSON AvatarResponse

-- GET user/equipped_skills -> {"equipped_skills": ["na_1", "s1_1", "s2_1", "ult_1"]}
data EquippedSkillsResponse = EquippedSkillsResponse { equipped_skills :: [Text] } deriving (Show, Generic)
instance ToJSON EquippedSkillsResponse

-- GET user/owned_skills -> {"owned_skills": ["na_1", "s1_1", ...]}
data OwnedSkillsResponse = OwnedSkillsResponse { owned_skills :: [Text] } deriving (Show, Generic)
instance ToJSON OwnedSkillsResponse

-- GET user/equipped_clothes -> {"equipped_clothes": ["accessory_1", "shirt_1", "shoes_1"]}
data EquippedClothesResponse = EquippedClothesResponse { equipped_clothes :: [Text] } deriving (Show, Generic)
instance ToJSON EquippedClothesResponse

-- GET user/owned_clothes -> {"owned_clothes": ["accessory_1", "shirt_1", ...]}
data OwnedClothesResponse = OwnedClothesResponse { owned_clothes :: [Text] } deriving (Show, Generic)
instance ToJSON OwnedClothesResponse

data GachaResponse = GachaResponse
  { status :: String
  , items  :: [Text]
  } deriving (Show, Generic)
instance ToJSON GachaResponse


-- ============================================================================
-- 2. HANDLERS (Đã đổi tên đồng bộ với API)
-- ============================================================================

-- GET user/tickets
getTicketsHandler :: Maybe String -> Handler TicketsResponse
getTicketsHandler cookie = withAuthenticatedUser cookie $ \u -> return $ TicketsResponse u.tickets

-- GET user/avatar
getAvatarHandler :: Maybe String -> Handler AvatarResponse
getAvatarHandler cookie = withAuthenticatedUser cookie $ \u -> return $ AvatarResponse u.avatar

-- GET user/equipped_skills
getEquippedSkillsHandler :: Maybe String -> Handler EquippedSkillsResponse
getEquippedSkillsHandler cookie = withAuthenticatedUser cookie $ \u -> 
    return $ EquippedSkillsResponse [u.equipped_na, u.equipped_s1, u.equipped_s2, u.equipped_ult]

-- GET user/owned_skills
getOwnedSkillsHandler :: Maybe String -> Handler OwnedSkillsResponse
getOwnedSkillsHandler cookie = withAuthenticatedUser cookie $ \u -> return $ OwnedSkillsResponse u.owned_skills

-- GET user/equipped_clothes
getEquippedClothesHandler :: Maybe String -> Handler EquippedClothesResponse
getEquippedClothesHandler cookie = withAuthenticatedUser cookie $ \u -> 
    return $ EquippedClothesResponse [u.equipped_accessory, u.equipped_shirt, u.equipped_shoes]

-- GET user/owned_clothes
getOwnedClothesHandler :: Maybe String -> Handler OwnedClothesResponse
getOwnedClothesHandler cookie = withAuthenticatedUser cookie $ \u -> return $ OwnedClothesResponse u.owned_clothes


-- ============================================================================
-- 3. HỆ THỐNG GACHA
-- ============================================================================

getWeight :: Text -> Int
getWeight "Mythical"  = 1
getWeight "Legendary" = 3
getWeight "Epic"      = 10
getWeight "Rare"      = 17
getWeight "Uncommon"  = 20
getWeight _           = 50

pickItem :: Int -> [a] -> (a -> Text) -> (a -> Text) -> [Int] -> Text
pickItem _ [item] getId _ _ = getId item
pickItem randVal (item:items) getId getRarity (w:ws)
    | randVal <= w = getId item
    | otherwise    = pickItem (randVal - w) items getId getRarity ws
pickItem _ [] _ _ _ = ""

getRandomItemWithRate :: [a] -> (a -> Text) -> (a -> Text) -> IO Text
getRandomItemWithRate pool getId getRarity = do
    let weights = map (getWeight . getRarity) pool
    let totalWeight = sum weights
    randVal <- randomRIO (1, totalWeight)
    return $ pickItem randVal pool getId getRarity weights

runGachaCore :: Int -> ItemType -> IO [a] -> (a -> Text) -> (a -> Text) -> Maybe String -> Handler GachaResponse
runGachaCore count category getPool getId getRarity cookie = withAuthenticatedUser cookie $ \u -> do
    let uid = u.user_id
    success <- liftIO $ deductTickets uid count
    if not success
        then throwError err400 { errBody = "Không đủ vé để quay!" }
        else do
            pool <- liftIO getPool
            if null pool
                then throwError err500 { errBody = "Pool rỗng!" }
                else do
                    rolledIDs <- liftIO $ replicateM count (getRandomItemWithRate pool getId getRarity)
                    liftIO $ addGachaItems uid category rolledIDs
                    return $ GachaResponse "success" rolledIDs

gachaX1Handler, gachaX10Handler :: Maybe String -> Handler GachaResponse
gachaX1Handler = runGachaCore 1  ClotheType getClothesPool clothe_id Clothe.rarity
gachaX10Handler = runGachaCore 10 ClotheType getClothesPool clothe_id Clothe.rarity

gachaSkillX1Handler, gachaSkillX10Handler :: Maybe String -> Handler GachaResponse
gachaSkillX1Handler  = runGachaCore 1  SkillType getSkillsPool skill_id Skill.rarity
gachaSkillX10Handler = runGachaCore 10 SkillType getSkillsPool skill_id Skill.rarity
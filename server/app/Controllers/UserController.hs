{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedRecordDot #-}
{- HLINT ignore "Use newtype instead of data" -}

module Controllers.UserController
  ( getTicketsHandler
  , getEquippedSkillsHandler
  , getOwnedSkillsHandler
  , getEquippedClothesHandler
  , getOwnedClothesHandler
  , getOwnedItemsHandler
  , getGachaHandler
  , TicketsResponse(..)
    , EquippedSkillsResponse(..)
    , OwnedSkillsResponse(..)
    , EquippedClothesResponse(..)
    , OwnedItemsResponse(..)
    , OwnedClothesResponse(..)
    , GachaRequest(..)
    , GachaResponse(..)
  ) where

import Control.Monad (replicateM)
import Control.Monad.IO.Class
import Data.Aeson hiding (Result(..))
import Data.Text (Text)
import GHC.Generics
import Servant
import System.Random (randomRIO)

import Model.User ( User(..), ItemType(..), deductTickets, addGachaItems, updatePity )
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


-- GET user/equipped_skills -> {"equipped_skills": ["na_1", "s1_1", "s2_1", "ult_1"]}
data EquippedSkillsResponse = EquippedSkillsResponse { equipped_skills :: [Text] } deriving (Show, Generic)
instance ToJSON EquippedSkillsResponse

-- GET user/owned_skills -> {"owned_skills": ["na_1", "s1_1", ...]}
data OwnedSkillsResponse = OwnedSkillsResponse { owned_skills :: [Text] } deriving (Show, Generic)
instance ToJSON OwnedSkillsResponse

-- GET user/equipped_clothes -> {"equipped_clothes": ["acc_1", "shirt_1", "shoes_1"]}
data EquippedClothesResponse = EquippedClothesResponse { equipped_clothes :: [Text] } deriving (Show, Generic)
instance ToJSON EquippedClothesResponse

-- GET user/owned_clothes -> {"owned_clothes": ["acc_1", "shirt_1", ...]}
data OwnedClothesResponse = OwnedClothesResponse { owned_clothes :: [Text] } deriving (Show, Generic)
instance ToJSON OwnedClothesResponse

data OwnedItemsResponse = OwnedItemsResponse
    {
        owned_skills :: [Text],
        owned_clothes :: [Text]
    }
                        deriving (Show, Generic)
instance ToJSON OwnedItemsResponse

data GachaResponse = GachaResponse
  { status :: Text
  , message :: Text
  , added_items  :: Maybe [Text]
  } deriving (Show, Generic)
instance ToJSON GachaResponse

data GachaRequest = GachaRequest
    {
        wish :: Text
    ,   wish_type :: Text
    } deriving (Show, Generic)
instance FromJSON GachaRequest


-- ============================================================================
-- 2. HANDLERS (Đã đổi tên đồng bộ với API)
-- ============================================================================

-- GET user/tickets
getTicketsHandler :: Maybe String -> Handler TicketsResponse
getTicketsHandler cookie = withAuthenticatedUser cookie $ \u -> return $ TicketsResponse u.tickets


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
    return $ EquippedClothesResponse [u.equipped_acc, u.equipped_shirt, u.equipped_shoes]

-- GET user/owned_clothes
getOwnedClothesHandler :: Maybe String -> Handler OwnedClothesResponse
getOwnedClothesHandler cookie = withAuthenticatedUser cookie $ \u -> return $ OwnedClothesResponse u.owned_clothes

getOwnedItemsHandler :: Maybe String -> Handler OwnedItemsResponse
getOwnedItemsHandler cookie = withAuthenticatedUser cookie $ \u -> do
    return $ OwnedItemsResponse { owned_skills = u.owned_skills, owned_clothes = u.owned_clothes }



-- ============================================================================
-- 3. HỆ THỐNG GACHA
-- ============================================================================

getWeight :: Text -> Int
getWeight "Mythical"  = 1     --pity 0
getWeight "Legendary" = 4     --pity 50s
getWeight "Epic"      = 10
getWeight "Rare"      = 20
getWeight "Uncommon"  = 30
getWeight _           = 50

pickItem :: Int -> [a] -> (a -> Text) -> [Int] -> a
pickItem _ [item] _ _ = item
pickItem randVal (item:restItems) getRarity (w:ws)
    | randVal <= w = item
    | otherwise    = pickItem (randVal - w) restItems getRarity ws
pickItem _ _ _ _ = error "Pool empty"

rollSingle :: Int -> [a] -> (a -> Text) -> (a -> Text) -> IO (Text, Int)
rollSingle currentPity pool getId getRarity = do
    if currentPity >= 100
        then do
            let legPool = filter (\x -> getRarity x == "Legendary") pool
            idx <- randomRIO (0, length legPool - 1)
            let item = legPool !! idx
            return (getId item, 0)
        else do
            let weights = map (getWeight . getRarity) pool
            let totalWeight = sum weights
            randVal <- randomRIO (1, totalWeight)
            let item = pickItem randVal pool getRarity weights
            
            if getRarity item == "Legendary"
                then return (getId item, 0)
                else return (getId item, currentPity + 1)

rollMultiple :: Int -> Int -> [a] -> (a -> Text) -> (a -> Text) -> IO ([Text], Int)
rollMultiple 0 currentPity _ _ _ = return ([], currentPity)
rollMultiple n currentPity pool getId getRarity = do
    (itemId, nextPity) <- rollSingle currentPity pool getId getRarity
    (restIds, finalPity) <- rollMultiple (n - 1) nextPity pool getId getRarity
    return (itemId : restIds, finalPity)

-- Handler chính xử lý gộp
getGachaHandler :: Maybe String -> GachaRequest -> Handler GachaResponse
getGachaHandler cookie req = withAuthenticatedUser cookie $ \u -> do
    let uid = u.user_id
    
    -- 1. Xác định số lượng vé cần trừ
    let (count, isValidCount) = case req.wish of
                                  "x1"  -> (1, True)
                                  "x10" -> (10, True)
                                  _     -> (0, False)
                                  
    if not isValidCount
        then return $ GachaResponse "failure" "Quantity not valid" Nothing
        else do
            -- 2. Trừ vé
            success <- liftIO $ deductTickets uid count
            if not success
                then return $ GachaResponse "failure" "Too Poor huhu" Nothing -- Báo lỗi y hệt spec
                else do
                    -- 3. Phân nhánh xử lý theo loại gacha
                    case req.wish_type of
                        "clothes" -> processGacha count ClotheType getClothesPool clothe_id Clothe.rarity (\user -> user.pity_clothe_leg) "pity_clothe_leg" uid u
                        "skills"  -> processGacha count SkillType getSkillsPool skill_id Skill.rarity (\user -> user.pity_skill_leg) "pity_skill_leg" uid u
                        _         -> return $ GachaResponse "failure" "Wish Type not valid" Nothing

-- Hàm con chạy logic random và cập nhật Data
processGacha :: Int -> ItemType -> IO [a] -> (a -> Text) -> (a -> Text) -> (User -> Int) -> Text -> Text -> User -> Handler GachaResponse
processGacha count category getPool getId getRarity getPityFunc pityField uid u = do
    pool <- liftIO getPool
    if null pool
        then return $ GachaResponse "failure" "Nothing in Pool" Nothing
        else do
            let currentPity = getPityFunc u
            (rolledIDs, finalPity) <- liftIO $ rollMultiple count currentPity pool getId getRarity
            
            liftIO $ addGachaItems uid category rolledIDs
            liftIO $ updatePity uid pityField finalPity
            
            return $ GachaResponse "success" "Success" (Just rolledIDs)
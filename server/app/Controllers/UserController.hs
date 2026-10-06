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
  , gachaX1Handler
  , gachaX10Handler
  , gachaSkillX1Handler
  , gachaSkillX10Handler
  , TicketsResponse(..)
    , EquippedSkillsResponse(..)
    , OwnedSkillsResponse(..)
    , EquippedClothesResponse(..)
    , OwnedItemsResponse(..)
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
pickItem _ _ _ _ = error "Pool emty"

-- Lõi random 1 lần: Kiểm tra pity, nếu chạm 100 thì ép ra Legendary, ra xong reset về 0
rollSingle :: Int -> [a] -> (a -> Text) -> (a -> Text) -> IO (Text, Int)
rollSingle currentPity pool getId getRarity = do
    if currentPity >= 100
        then do
            -- Pity max: Lọc ra toàn bộ đồ Legendary và bốc ngẫu nhiên 1 món
            let legPool = filter (\x -> getRarity x == "Legendary") pool
            idx <- randomRIO (0, length legPool - 1)
            let item = legPool !! idx
            return (getId item, 0) -- Nổ bảo hiểm -> Reset pity về 0
        else do
            -- Chưa đủ Pity: Roll theo rate bình thường
            let weights = map (getWeight . getRarity) pool
            let totalWeight = sum weights
            randVal <- randomRIO (1, totalWeight)
            let item = pickItem randVal pool getRarity weights
            
            if getRarity item == "Legendary"
                then return (getId item, 0) -- Hên nổ sớm -> Reset pity
                else return (getId item, currentPity + 1) -- Đen đủi -> Tích thêm 1 pity

-- Đệ quy thực hiện N lần quay (Dùng chung cho cả x1 và x10)
rollMultiple :: Int -> Int -> [a] -> (a -> Text) -> (a -> Text) -> IO ([Text], Int)
rollMultiple 0 currentPity _ _ _ = return ([], currentPity)
rollMultiple n currentPity pool getId getRarity = do
    (itemId, nextPity) <- rollSingle currentPity pool getId getRarity
    (restIds, finalPity) <- rollMultiple (n - 1) nextPity pool getId getRarity
    return (itemId : restIds, finalPity)

runGachaCore :: Int -> ItemType -> IO [a] -> (a -> Text) -> (a -> Text) -> (User -> Int) -> Text -> Maybe String -> Handler GachaResponse
runGachaCore count category getPool getId getRarity getPityFunc pityField cookie = withAuthenticatedUser cookie $ \u -> do
    let uid = u.user_id
    success <- liftIO $ deductTickets uid count
    if not success
        then throwError err400 { errBody = "Không đủ vé để quay!" }
        else do
            pool <- liftIO getPool
            if null pool
                then throwError err500 { errBody = "Pool rỗng!" }
                else do
                    let currentPity = getPityFunc u -- Lấy pity hiện tại
                    
                    -- Chạy random x1 hoặc x10, lấy về mảng ID và Pity chốt cuối cùng
                    (rolledIDs, finalPity) <- liftIO $ rollMultiple count currentPity pool getId getRarity
                    
                    -- Cập nhật đồng loạt đồ gacha và Pity mới vào DB
                    liftIO $ addGachaItems uid category rolledIDs
                    liftIO $ updatePity uid pityField finalPity
                    
                    return $ GachaResponse "success" rolledIDs

-- Cập nhật lại 4 Handler truyền đúng trường pity tương ứng:
gachaX1Handler, gachaX10Handler :: Maybe String -> Handler GachaResponse
gachaX1Handler  = runGachaCore 1  ClotheType getClothesPool clothe_id Clothe.rarity (\u -> u.pity_clothe_leg) "pity_clothe_leg"
gachaX10Handler = runGachaCore 10 ClotheType getClothesPool clothe_id Clothe.rarity (\u -> u.pity_clothe_leg) "pity_clothe_leg"

gachaSkillX1Handler, gachaSkillX10Handler :: Maybe String -> Handler GachaResponse
gachaSkillX1Handler  = runGachaCore 1  SkillType getSkillsPool skill_id Skill.rarity (\u -> u.pity_skill_leg) "pity_skill_leg"
gachaSkillX10Handler = runGachaCore 10 SkillType getSkillsPool skill_id Skill.rarity (\u -> u.pity_skill_leg) "pity_skill_leg"


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
  , getEquipItemHandler
  , TicketsResponse(..)
    , EquippedSkillsResponse(..)
    , OwnedSkillsResponse(..)
    , EquippedClothesResponse(..)
    , OwnedItemsResponse(..)
    , OwnedClothesResponse(..)
    , GachaRequest(..)
    , GachaResponse(..)
    , EquipRequest(..)
    , EquipResponse(..)
  ) where

import Control.Monad.IO.Class
import Data.Aeson hiding (Result(..))
import Data.Text (Text)
import qualified Data.Text as T
import GHC.Generics
import Servant
import System.Random (randomRIO)

import Model.User ( User(..), ItemType(..), deductTickets, addGachaItems, updatePity, updateEquippedItem)
import Model.Clothe (Clothe(..), getClothesPool)
import Model.Skill (Skill(..), getSkillsPool)
import qualified Model.Clothe as Clothe
import qualified Model.Skill as Skill
import Controllers.AuthController (withAuthenticatedUser)
import Model.GachaHistory (saveGachaHistory)


-- GET user/tickets -> {"tickets": 100}
data TicketsResponse = TicketsResponse { tickets :: Int } deriving (Show, Generic)
instance ToJSON TicketsResponse
getTicketsHandler :: Maybe String -> Handler TicketsResponse
getTicketsHandler cookie = withAuthenticatedUser cookie $ \u -> return $ TicketsResponse u.tickets


-- GET user/owned_skills -> {"owned_skills": ["na_1", "s1_1", ...]}
data OwnedSkillsResponse = OwnedSkillsResponse { owned_skills :: [Text] } deriving (Show, Generic)
instance ToJSON OwnedSkillsResponse
getOwnedSkillsHandler :: Maybe String -> Handler OwnedSkillsResponse
getOwnedSkillsHandler cookie = withAuthenticatedUser cookie $ \u -> return $ OwnedSkillsResponse u.owned_skills


-- GET user/owned_clothes -> {"owned_clothes": ["acc_1", "shirt_1", ...]}
data OwnedClothesResponse = OwnedClothesResponse { owned_clothes :: [Text] } deriving (Show, Generic)
instance ToJSON OwnedClothesResponse
getOwnedClothesHandler :: Maybe String -> Handler OwnedClothesResponse
getOwnedClothesHandler cookie = withAuthenticatedUser cookie $ \u -> return $ OwnedClothesResponse u.owned_clothes


data OwnedItemsResponse = OwnedItemsResponse{ owned_skills :: [Text], owned_clothes :: [Text] } deriving (Show, Generic)
instance ToJSON OwnedItemsResponse
getOwnedItemsHandler :: Maybe String -> Handler OwnedItemsResponse
getOwnedItemsHandler cookie = withAuthenticatedUser cookie $ \u -> do
    return $ OwnedItemsResponse { owned_skills = u.owned_skills, owned_clothes = u.owned_clothes }

-- GET user/equipped_clothes -> {"equipped_clothes": ["acc_1", "shirt_1", "shoes_1"]}
data EquippedClothesResponse = EquippedClothesResponse { equipped_clothes :: [Text] } deriving (Show, Generic)
instance ToJSON EquippedClothesResponse
getEquippedClothesHandler :: Maybe String -> Handler EquippedClothesResponse
getEquippedClothesHandler cookie = withAuthenticatedUser cookie $ \u ->
    return $ EquippedClothesResponse [u.equipped_acc, u.equipped_shirt, u.equipped_shoes]


-- GET user/equipped_skills -> {"equipped_skills": ["na_1", "s1_1", "s2_1", "ult_1"]}
data EquippedSkillsResponse = EquippedSkillsResponse { equipped_skills :: [Text] } deriving (Show, Generic)
instance ToJSON EquippedSkillsResponse
getEquippedSkillsHandler :: Maybe String -> Handler EquippedSkillsResponse
getEquippedSkillsHandler cookie = withAuthenticatedUser cookie $ \u ->
    return $ EquippedSkillsResponse [u.equipped_s1, u.equipped_s2, u.equipped_s3, u.equipped_ult]



data EquipRequest = EquipRequest{equip_item :: Text} deriving (Show, Generic)
instance FromJSON EquipRequest
data EquipResponse = EquipResponse{status :: Text,message :: Text,equipped_item :: Text} deriving (Show, Generic)
instance ToJSON EquipResponse
getEquipItemHandler :: Maybe String -> EquipRequest -> Handler EquipResponse
getEquipItemHandler cookie req = withAuthenticatedUser cookie $ \u -> do
    let targetItem = req.equip_item
        uid = u.user_id

    case categorizeItem targetItem of
        Nothing ->
            throwError err400 { errBody = "invalid_item" }

        Just (category, dbField) -> do
            let isOwned = case category of
                    SkillType  -> targetItem `elem` u.owned_skills
                    ClotheType -> targetItem `elem` u.owned_clothes

            if not isOwned
                then throwError err403 { errBody = "item_not_owned" }
                else do
                    liftIO $ updateEquippedItem
                                uid
                                dbField
                                targetItem
                                category
                                (base_aura u)
                                (equipped_acc u)
                                (equipped_shirt u)
                                (equipped_shoes u)
                    return $ EquipResponse "success" "Trang bị thành công!" targetItem

data GachaRequest = GachaRequest{wish :: Text, wish_type :: Text } deriving (Show, Generic)
instance FromJSON GachaRequest
data GachaResponse = GachaResponse{ status :: Text, message :: Text, added_items  :: Maybe [Text], remaining_tickets :: Maybe Int} deriving (Show, Generic)
instance ToJSON GachaResponse
getGachaHandler :: Maybe String -> GachaRequest -> Handler GachaResponse
getGachaHandler cookie req = withAuthenticatedUser cookie $ \u -> do
    let uid = u.user_id
        count = case req.wish of
          "x1" -> Just 1
          "x10" -> Just 10
          _ -> Nothing
    case count of
      Nothing -> throwError err400 { errBody = "invalid_quantity" }
      Just amount -> case req.wish_type of
        "clothes" -> do
          pool <- liftIO getClothesPool
          runGacha amount ClotheType pool clothe_id Clothe.rarity
            (\user -> user.pity_clothe_leg) "pity_clothe_leg" uid u
        "skills" -> do
          pool <- liftIO getSkillsPool
          runGacha amount SkillType pool skill_id Skill.rarity
            (\user -> user.pity_skill_leg) "pity_skill_leg" uid u
        _ -> throwError err400 { errBody = "invalid_wish_type" }

rarityWeights :: [(Text, Double)]
rarityWeights =
    [ ("mythical", 0.5)   -- 0.5%
    , ("legendary", 1.5)  -- 1.5%
    , ("epic", 8.0)      -- 8.0%
    , ("rare", 15.0)      -- 15.0%
    , ("uncommon", 30.0)  -- 30.0%
    , ("common", 45.0)    -- 45.0%
    ]

pickRarity :: Double -> [(Text, Double)] -> Text
pickRarity _ [(r, _)] = r
pickRarity randVal ((r, w):rest)
    | randVal <= w = r
    | otherwise    = pickRarity (randVal - w) rest
pickRarity _ [] = "common"

rollSingle :: Int -> [a] -> (a -> Text) -> (a -> Text) -> IO (Text, Int)
rollSingle currentPity pool getId getRarity = do
    if currentPity >= 25
        then do
            let legPool = filter (\x -> getRarity x == "legendary") pool
            idx <- randomRIO (0, length legPool - 1)
            let item = legPool !! idx
            return (getId item, 0)
        else do
            let totalWeight = sum (map snd rarityWeights)
            randVal <- randomRIO (0.0 :: Double, totalWeight)
            let selectedRarity = pickRarity randVal rarityWeights

            let filteredPool = filter (\x -> getRarity x == selectedRarity) pool

            let actualPool = if null filteredPool then pool else filteredPool

            idx <- randomRIO (0, length actualPool - 1)
            let item = actualPool !! idx

            if getRarity item == "legendary"
                then return (getId item, 0)
                else return (getId item, currentPity + 1)

rollMultiple :: Int -> Int -> [a] -> (a -> Text) -> (a -> Text) -> IO ([Text], Int)
rollMultiple 0 currentPity _ _ _ = return ([], currentPity)
rollMultiple n currentPity pool getId getRarity = do
    (itemId, nextPity) <- rollSingle currentPity pool getId getRarity
    (restIds, finalPity) <- rollMultiple (n - 1) nextPity pool getId getRarity
    return (itemId : restIds, finalPity)

runGacha :: Int -> ItemType -> [a] -> (a -> Text) -> (a -> Text) -> (User -> Int) -> Text -> Text -> User -> Handler GachaResponse
runGacha count category pool getId getRarity getPityFunc pityField uid u = do
    if null pool
        then throwError err503 { errBody = "empty_pool" }
        else do
            mRemaining <- liftIO $ deductTickets uid count
            case mRemaining of
              Nothing -> throwError err409 { errBody = "insufficient_tickets" }
              Just remainingTickets -> do
                let currentPity = getPityFunc u
                (rolledIDs, finalPity) <- liftIO $ rollMultiple count currentPity pool getId getRarity

                liftIO $ addGachaItems uid category rolledIDs
                liftIO $ updatePity uid pityField finalPity

                let itemTypeStr = case category of
                                    ClotheType -> "clothe"
                                    SkillType  -> "skill"
                liftIO $ saveGachaHistory uid itemTypeStr rolledIDs

                return $ GachaResponse "success" "Success" (Just rolledIDs) (Just remainingTickets)

categorizeItem :: Text -> Maybe (ItemType, Text)
categorizeItem item
  | "s1_"    `T.isPrefixOf` item = Just (SkillType, "equipped_s1")
  | "s2_"    `T.isPrefixOf` item = Just (SkillType, "equipped_s2")
  | "s3_"    `T.isPrefixOf` item = Just (SkillType, "equipped_s3")
  | "ult_"   `T.isPrefixOf` item = Just (SkillType, "equipped_ult")
  | "acc_"   `T.isPrefixOf` item = Just (ClotheType, "equipped_acc")
  | "shirt_" `T.isPrefixOf` item = Just (ClotheType, "equipped_shirt")
  | "shoes_" `T.isPrefixOf` item = Just (ClotheType, "equipped_shoes")
  | "shoe_"  `T.isPrefixOf` item = Just (ClotheType, "equipped_shoes")
  | otherwise                    = Nothing
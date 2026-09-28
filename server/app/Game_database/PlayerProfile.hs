{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE DeriveGeneric #-}

module Game_database.PlayerProfile where

import GHC.Generics (Generic)
import Data.Aeson (ToJSON)
import Database.MongoDB
import Data.Maybe (fromMaybe)
import Control.Monad.IO.Class (liftIO)
import Data.Text (Text)

-- ==========================================
-- 1. CẤU TRÚC DỮ LIỆU
-- ==========================================
data PlayerProfile = PlayerProfile
  { user_id       :: Text
  , tickets       :: Int
  , avatar        :: Text
  , na            :: Text
  , s1            :: Text
  , s2            :: Text
  , ult           :: Text
  , accessory     :: Text
  , shirt         :: Text
  , shoes         :: Text
  , owned_clothes :: [Text]
  , owned_skills  :: [Text]
  } deriving (Show, Generic)

instance ToJSON PlayerProfile

runDB :: Action IO a -> IO a
runDB action = do
    pipe <- connect (host "127.0.0.1")
    result <- access pipe master "aura-farm-battle" action
    close pipe
    return result

-- ==========================================
-- 2. HÀM CHUYỂN ĐỔI BSON <-> HASKELL
-- ==========================================
docToProfile :: Document -> PlayerProfile
docToProfile doc = PlayerProfile
  { user_id       = fromMaybe "" (doc !? "user_id")
  , tickets       = fromMaybe 0  (doc !? "tickets")
  , avatar        = fromMaybe "" (doc !? "avatar") -- Rỗng tức là null/chưa có
  , na            = fromMaybe "na_1" (doc !? "na")
  , s1            = fromMaybe "s1_1" (doc !? "s1")
  , s2            = fromMaybe "s2_1" (doc !? "s2")
  , ult           = fromMaybe "ult_1" (doc !? "ult")
  , accessory     = fromMaybe "asc_1" (doc !? "accessory")
  , shirt         = fromMaybe "shirt_1" (doc !? "shirt")
  , shoes         = fromMaybe "shoes_1" (doc !? "shoes")
  , owned_clothes = fromMaybe ["asc_1", "shirt_1", "shoes_1"] (doc !? "owned_clothes")
  , owned_skills  = fromMaybe ["na_1", "s1_1", "s2_1", "ult_1"] (doc !? "owned_skills")
  }

profileToDoc :: PlayerProfile -> Document
profileToDoc p =
  [ "user_id"       =: user_id p
  , "tickets"       =: tickets p
  , "avatar"        =: avatar p
  , "na"            =: na p
  , "s1"            =: s1 p
  , "s2"            =: s2 p
  , "ult"           =: ult p
  , "accessory"     =: accessory p
  , "shirt"         =: shirt p
  , "shoes"         =: shoes p
  , "owned_clothes" =: owned_clothes p
  , "owned_skills"  =: owned_skills p
  ]

-- ==========================================
-- 3. CÁC HÀM TƯƠNG TÁC DATABASE
-- ==========================================

-- Gọi hàm này khi đăng ký thành công ở User.hs
createDefaultProfile :: Text -> IO ()
createDefaultProfile uid = runDB $ do
    let defaultProfile = PlayerProfile
          { user_id       = uid, tickets = 100, avatar = ""
          , na = "na_1", s1 = "s1_1", s2 = "s2_1", ult = "ult_1"
          , accessory = "asc_1", shirt = "shirt_1", shoes = "shoes_1"
          , owned_clothes = ["asc_1", "shirt_1", "shoes_1"]
          , owned_skills  = ["na_1", "s1_1", "s2_1", "ult_1"]
          }
    insert_ "player_profile" (profileToDoc defaultProfile)

-- Hàm kéo toàn bộ profile
getProfileByUserId :: Text -> IO (Maybe PlayerProfile)
getProfileByUserId uid = runDB $ do
    maybeDoc <- findOne (select ["user_id" =: uid] "player_profile")
    return (fmap docToProfile maybeDoc)

-- Hàm kiểm tra và trừ vé
deductTickets :: Text -> Int -> IO Bool
deductTickets uid amount = runDB $ do
    maybeDoc <- findOne (select ["user_id" =: uid] "player_profile")
    case maybeDoc of
        Nothing -> return False
        Just doc -> do
            let currentTickets = fromMaybe 0 (doc !? "tickets")
            if currentTickets >= amount
                then do
                    modify (select ["user_id" =: uid] "player_profile")
                           ["$inc" =: ["tickets" =: (-amount)]]
                    return True
                else return False

-- Hàm nhét đồ (áo/quần/kỹ năng) vào kho đồ sau khi quay gacha
addGachaItems :: Text -> Text -> [Text] -> IO ()
addGachaItems uid itemCategory newItems = runDB $ do
    let targetArray = if itemCategory == "clothes" then "owned_clothes" else "owned_skills"
    modify (select ["user_id" =: uid] "player_profile")
           ["$addToSet" =: [targetArray =: ["$each" =: newItems]]]
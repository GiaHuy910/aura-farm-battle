{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE DeriveGeneric #-}

module Game_database.GameItem where

import GHC.Generics (Generic)
import Data.Aeson (ToJSON)
import Database.MongoDB
import Data.Maybe (fromMaybe)
import Control.Monad.IO.Class (liftIO)
import Data.Text (Text)

-- ==========================================
-- CẤU TRÚC DỮ LIỆU ITEM GỐC
-- ==========================================
data GameItem = GameItem
  { item_id      :: Text
  , item_category:: Text  -- Phân loại: "clothes", "skill"
  , item_type    :: Text  -- Chi tiết hơn: "shirt", "shoes", "accessory", "na", "ult"
  , item_name    :: Text
  , rarity       :: Int   -- Độ hiếm (ví dụ: 1 sao, 2 sao, 3 sao...)
  } deriving (Show, Generic)

instance ToJSON GameItem

runDB :: Action IO a -> IO a
runDB action = do
    pipe <- connect (host "127.0.0.1")
    result <- access pipe master "aura-farm-battle" action
    close pipe
    return result

docToItem :: Document -> GameItem
docToItem doc = GameItem
  { item_id       = fromMaybe "" (doc !? "item_id")
  , item_category = fromMaybe "" (doc !? "item_category")
  , item_type     = fromMaybe "" (doc !? "item_type")
  , item_name     = fromMaybe "" (doc !? "item_name")
  , rarity        = fromMaybe 1  (doc !? "rarity")
  }

-- ==========================================
-- CÁC HÀM TRUY XUẤT CHO CONTROLLER
-- ==========================================

-- Lấy toàn bộ ID của Quần Áo (Dùng làm Pool quay Gacha Quần Áo)
getClothesPool :: IO [GameItem]
getClothesPool = runDB $ do
    docs <- find (select ["item_category" =: ("clothes" :: Text)] "game_items") >>= rest
    return (map docToItem docs)

-- Lấy toàn bộ GameItem của Kỹ Năng (Dùng làm Pool quay Gacha Skill)
getSkillsPool :: IO [GameItem]
getSkillsPool = runDB $ do
    docs <- find (select ["item_category" =: ("skill" :: Text)] "game_items") >>= rest
    return (map docToItem docs)

-- Lấy thông tin chi tiết của một danh sách ID (Dùng khi trả dữ liệu thật cho UI nếu UI cần)
getItemsByIds :: [Text] -> IO [GameItem]
getItemsByIds ids = runDB $ do
    docs <- find (select ["item_id" =: ["$in" =: ids]] "game_items") >>= rest
    return (map docToItem docs)
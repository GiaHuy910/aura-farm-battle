{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}
module Model.Rooms where

import Database.MongoDB
import Data.Maybe (fromMaybe)
import Data.UUID.V4 (nextRandom)
import Data.UUID (toString)
import Control.Monad.IO.Class (liftIO)
import Data.Text (Text, pack)

-- 1. Định nghĩa cấu trúc dữ liệu
data Room = Room
  {room_id :: Text
  ,room_name  :: Text
  , room_password  :: Text
  , owner_id   :: Text
  , user_ids   :: [Text]
  , occupancy :: Int
  , is_private :: Bool
  } deriving (Show)

-- 2. Hàm tiện ích để tự động kết nối và đóng MongoDB
-- Tạo hàm này để bạn không phải viết lại code kết nối mỗi khi thêm tính năng mới
runDB :: Action IO a -> IO a
runDB action = do
    pipe <- connect (host "127.0.0.1")
    result <- access pipe master "aura-farm-battle" action
    close pipe
    return result

-- 3. Hàm lấy danh sách phòng (Rất ngắn gọn khi dùng runDB)
getRooms :: IO [Room]
getRooms = runDB $ do
    -- Sử dụng record update { project = ... }
    docs <- find ((select [] "room") { project = ["room_password" =: (0 :: Int)] }) >>= rest
    return (map docToRoom docs)

-- 4. Chuyển đổi BSON Document sang Room
-- Dùng toán tử (!?) để tự động ép kiểu BSON sang String/Bool
-- Dùng fromMaybe để gán giá trị mặc định nếu database không có trường đó
docToRoom :: Document -> Room
docToRoom doc = Room
  { room_id = fromMaybe "" (doc !? "room_id")
  , room_name  = fromMaybe ""    (doc !? "room_name")
  , room_password  = fromMaybe ""    (doc !? "room_password")
  , owner_id   = fromMaybe ""    (doc !? "owner_id")
  , user_ids   = fromMaybe []    (doc !? "user_ids")
  , occupancy = fromMaybe 0     (doc !? "occupancy")
  , is_private = fromMaybe False (doc !? "is_private")
  }

-- ==========================================
-- CÁC HÀM THAO TÁC VỚI PHÒNG (CRUD)
-- ==========================================

-- Hàm phụ trợ: Chuyển cấu trúc Room trong Haskell thành Document để lưu vào MongoDB
roomToDoc :: Room -> Document
roomToDoc r =
  [ "room_id" =: room_id r
  , "room_name" =: room_name r
  , "room_password"  =: room_password r
  , "owner_id"   =: owner_id r
  , "user_ids"    =: user_ids r
  , "occupancy" =: occupancy r
  , "is_private" =: is_private r
  ]

-- 1. Hàm tạo phòng mới
createRoom :: Room -> IO Room
createRoom newRoom = runDB $ do
    uuid <- liftIO nextRandom
    let validUsers = take 2 (user_ids newRoom)
    if null validUsers
        then error "Phòng phải có ít nhất 1 người (chủ phòng)"
    else do
        let realOccupancy = length (user_ids newRoom)
        let valiatedRoom = newRoom { room_id = pack (toString uuid), occupancy = realOccupancy }
        insert_ "room" (roomToDoc valiatedRoom)
                    -- insert_ (có dấu gạch dưới) dùng khi ta không cần lấy lại ID do MongoDB tự sinh ra.
        return valiatedRoom

-- 5. Hàm xóa phòng khi chủ phòng rời đi
-- Tham số: Tên phòng -> ID người vừa rời (phải là Owner thì mới xóa được)
deleteRoom :: Text -> Text -> IO ()
deleteRoom rName reqOwnerID = runDB $ do
    deleteOne (select ["room_name" =: rName, "owner_id" =: reqOwnerID] "room")

-- Hàm cho phép người chơi tham gia phòng (Trả về True nếu thành công, False nếu thất bại)
joinRoom :: Text -> Text -> Text -> IO Bool
joinRoom rName rPass newUserID = runDB $ do
    maybeDoc <- findOne (select ["room_name" =: rName] "room")
    case maybeDoc of
        Nothing -> return False --K tìm thấy phòng
        Just doc -> do
            let room = docToRoom doc
            if occupancy room >= 2 --Check số ng trong phòng
                then return False
                else if is_private room  --Check private
                    then if rPass == room_password room
                        then do
                            let updatedUsers = user_ids room ++ [newUserID]
                                newOccupancy = length updatedUsers
                            modify (select ["room_name" =: rName] "room") --Chỉnh sửa lại data của room
                                ["$set" =: ["user_ids" =: updatedUsers, "occupancy" =: newOccupancy]]
                            return True
                        else return False
                    else do
                        let updatedUsers = user_ids room ++ [newUserID]
                            newOccupancy = length updatedUsers
                        modify (select ["room_name" =: rName] "room")
                            ["$set" =: ["user_ids" =: updatedUsers, "occupancy" =: newOccupancy]]
                        return True
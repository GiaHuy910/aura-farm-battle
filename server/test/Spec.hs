{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE OverloadedRecordDot #-}

module Main where

import Database.MongoDB
import Data.Text (Text)

import Config.Database (runDB)
import Model.User    hiding (runDB) -- Giữ lại runDB từ module này
import Model.Skill   hiding (runDB)
import Model.Session hiding (runDB)
import Model.Clothe  hiding (runDB)
import System.IO (hSetEncoding, stdout, utf8)

-- 1. Hàm dọn dẹp data cũ
clearTestDB :: IO ()
clearTestDB = runDB $ do
  delete (select [] "user")
  delete (select [] "session")

-- 2. Khởi tạo pool vật phẩm mẫu trong MongoDB
seedDatabase :: IO ()
seedDatabase = runDB $ do
  delete (select [] "clothes")
  delete (select [] "skills")
  
  insert_ "clothes" 
    [ "clothe_id"   =: ("shirt_101" :: Text)
    , "clothe_type" =: ("shirt" :: Text)
    , "clothe_name" =: ("Áo Thun Huyền Thoại" :: Text)
    , "rarity"      =: ("Epic" :: Text)
    , "in_pool"     =: True
    ]
  insert_ "skills" 
    [ "skill_id"   =: ("skill_99" :: Text)
    , "skill_type" =: ("s1" :: Text)
    , "skill_name" =: ("Hỏa Cầu" :: Text)
    , "rarity"     =: ("Legendary" :: Text)
    , "in_pool"    =: True
    ]

main :: IO ()
main = do
  hSetEncoding stdout utf8
  putStrLn "========================================="
  putStrLn "   BẮT ĐẦU RUNTIME TEST - AURA FARM     "
  putStrLn "========================================="

  -- Bước 1: Reset DB
  putStrLn "\n[1/6] Reset DB & Khởi tạo dữ liệu mẫu (Pool Gacha)..."
  clearTestDB
  seedDatabase
  putStrLn "   ✅ Đã khởi tạo item 'shirt_101' & 'skill_99'."

  -- Bước 2: Test Register
  putStrLn "\n[2/6] Test Register User..."
  regRes <- registerUser "testuser" "pass123456"
  case regRes of
    UserAlreadyExists -> putStrLn "   ❌ FAIL: User đã tồn tại!"
    Success uid -> do
      putStrLn $ "   ✅ PASS: Đăng ký thành công! User ID = " ++ show uid

      -- Bước 3: Test Login
      putStrLn "\n[3/6] Test Login User..."
      loginRes <- loginUser "testuser" "pass123456"
      case loginRes of
        LoginFailed -> putStrLn "   ❌ FAIL: Đăng nhập thất bại!"
        LoginSuccess lUid -> putStrLn $ "   ✅ PASS: Đăng nhập thành công! User ID = " ++ show lUid

      -- Bước 4: Get User Info
      putStrLn "\n[4/6] Test Get User By ID..."
      mUser <- getUserById uid
      case mUser of
        Nothing -> putStrLn "   ❌ FAIL: Không tìm thấy User vừa tạo!"
        Just u -> do
          putStrLn $ "   ✅ PASS: Lấy dữ liệu thành công! Tickets ban đầu = " ++ show u.tickets

      -- Bước 5: Deduct Tickets
      putStrLn "\n[5/6] Test Deduct Tickets (Trừ 10 vé)..."
      okDeduct <- deductTickets uid 10
      if not okDeduct
        then putStrLn "   ❌ FAIL: Không trừ được vé!"
        else do
          mUser2 <- getUserById uid
          case mUser2 of
            Nothing -> putStrLn "   ❌ FAIL: Lỗi đọc User sau trừ vé!"
            Just u2 -> putStrLn $ "   ✅ PASS: Trừ vé thành công! Vé còn lại = " ++ show u2.tickets

      -- Bước 6: Test Gacha Store & Parse BSON Document
      putStrLn "\n[6/6] Test Gacha Storage (Kiểm tra đọc/ghi BSON Document)..."
      addGachaItems uid ClotheType ["shirt_101"]
      addGachaItems uid SkillType ["skill_99"]

      mUser3 <- getUserById uid
      case mUser3 of
        Nothing -> putStrLn "   ❌ FAIL: Lỗi đọc User sau khi add Gacha!"
        Just u3 -> do
          let cLen = length u3.owned_clothes
          let sLen = length u3.owned_skills
          if cLen > 0 && sLen > 0
            then do
                putStrLn "   ✅ PASS: Đọc/ghi BSON Document kho đồ thành công!"
                putStrLn $ "      - Áo vừa nhận: " ++ show (head u3.owned_clothes)
                putStrLn $ "      - Skill vừa nhận: " ++ show (head u3.owned_skills)
            else putStrLn "   ❌ FAIL: Kho đồ bị rỗng sau khi add!"

      -- Bước 7: Session
      putStrLn "\n[Bonus] Test Session Management..."
      sid <- createSession uid
      mAuthUid <- getUserBySession sid
      case mAuthUid of
        Just authUid | authUid == uid -> putStrLn "   ✅ PASS: Xác thực Session chính xác!"
        _ -> putStrLn "   ❌ FAIL: Session sai UID!"
      deleteSession sid
      putStrLn "   ✅ Đã xóa session thành công."

  putStrLn "\n========================================="
  putStrLn "      HOÀN THÀNH TẤT CẢ TEST CASES      "
  putStrLn "========================================="
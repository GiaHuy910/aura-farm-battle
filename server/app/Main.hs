{-# LANGUAGE OverloadedStrings #-}
module Main where

-- Nhớ import thêm các hàm bạn vừa tạo
import Game_database.Rooms (Room(..), getRooms, createRoom, deleteRoom)
import Game_database.User (User(..), registerUser, loginUser, RegisterStatus(..), LoginStatus(..), getUsers, getUser)
import System.IO (hSetEncoding, stdout, utf8)

main :: IO ()
main = do
    hSetEncoding stdout utf8
    putStrLn "--- Bắt đầu chạy test getUser ---"
    
    -- 1. Giả sử ta muốn tìm user có tên là "nguyenvana"
    let targetUsername = "abcxyz"
    
    -- 2. Gọi hàm getUser (hàm này sẽ thực thi trong IO)
    maybeUser <- getUser targetUsername
    
    -- 3. Kiểm tra kết quả trả về bằng pattern matching
    case maybeUser of
        Nothing -> 
            putStrLn $ "Not found: " ++ show targetUsername
            
        Just user -> do
            putStrLn $ "Success" ++ show user
            -- Lưu ý: Kiểu dữ liệu 'User' của bạn cần phải 'derive (Show)' 
            -- để có thể in ra trực tiếp bằng hàm print hoặc show như dưới đây:
            print user 
            
    putStrLn "--- Kết thúc test ---"
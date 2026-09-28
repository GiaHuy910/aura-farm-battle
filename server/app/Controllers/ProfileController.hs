{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE NoFieldSelectors #-}

module Controllers.ProfileController where

import Control.Monad.IO.Class (liftIO)
import Control.Monad (replicateM)
import Data.Aeson
import Data.Text (Text, pack, unpack)
import GHC.Generics
import Servant
import System.Random (randomRIO)

import Game_database.GameItem (GameItem(..), getClothesPool, getSkillsPool)
import Game_database.Session (getUserBySession)
import Game_database.PlayerProfile ( PlayerProfile(..), getProfileByUserId, deductTickets, addGachaItems )

-- ==========================================
-- 1. CÁC DATA TYPE ĐỂ TRẢ VỀ JSON CHO CLIENT
-- ==========================================
data TicketsResponse = TicketsResponse { tickets :: Int } deriving (Show, Generic)
instance ToJSON TicketsResponse

data AvatarResponse = AvatarResponse { avatar :: Text } deriving (Show, Generic)
instance ToJSON AvatarResponse

data CurrentSkillsResponse = CurrentSkillsResponse
  { na :: Text, s1 :: Text, s2 :: Text, ult :: Text } deriving (Show, Generic)
instance ToJSON CurrentSkillsResponse

data OwnedSkillsResponse = OwnedSkillsResponse { owned_skills :: [Text] } deriving (Show, Generic)
instance ToJSON OwnedSkillsResponse

data CurrentClothesResponse = CurrentClothesResponse
  { accessory :: Text, shirt :: Text, shoes :: Text } deriving (Show, Generic)
instance ToJSON CurrentClothesResponse

data OwnedClothesResponse = OwnedClothesResponse { owned_clothes :: [Text] } deriving (Show, Generic)
instance ToJSON OwnedClothesResponse

data GachaResponse = GachaResponse
  { status :: String
  , items  :: [Text]
  } deriving (Show, Generic)
instance ToJSON GachaResponse

-- ==========================================
-- 2. HÀM PHỤ TRỢ (HELPER)
-- ==========================================
-- Lấy session từ cookie (bạn có thể import từ AuthController nếu đã tách ra file Utils)
parseSessionId :: String -> Maybe Text
parseSessionId cookieHeader =
  let pairs = map (break (== '=')) $ wordsWhen (== ';') cookieHeader
      trim = reverse . dropWhile (== ' ') . reverse . dropWhile (== ' ')
  in case lookup "session_id" [(trim k, drop 1 (trim v)) | (k, v) <- pairs] of
       Just val -> Just (pack val)
       Nothing  -> Nothing
  where wordsWhen p s = case dropWhile p s of "" -> []; s' -> let (w, s'') = break p s' in w : wordsWhen p s'

-- Helper đóng gói luồng check session
withUserSession :: Maybe String -> (Text -> Handler a) -> Handler a
withUserSession mCookie action = do
    case mCookie >>= parseSessionId of
        Nothing  -> throwError err401 { errBody = "Chưa đăng nhập!" }
        Just sID -> do
            mUid <- liftIO $ getUserBySession sID
            case mUid of
                Nothing  -> throwError err401 { errBody = "Session không hợp lệ!" }
                Just uid -> action uid

-- Helper lấy Profile chuẩn xác
withPlayerProfile :: Text -> (PlayerProfile -> Handler a) -> Handler a
withPlayerProfile uid action = do
    mProfile <- liftIO $ getProfileByUserId uid
    case mProfile of
        Nothing -> throwError err404 { errBody = "Không tìm thấy hồ sơ nhân vật!" }
        Just p  -> action p

-- ==========================================
-- 3. HANDLERS NHÓM API LẤY THÔNG TIN (GET)
-- ==========================================
getTicketsHandler :: Maybe String -> Handler TicketsResponse
getTicketsHandler cookie = withUserSession cookie $ \uid -> 
    withPlayerProfile uid $ \p -> return $ TicketsResponse (tickets p)

getAvatarHandler :: Maybe String -> Handler AvatarResponse
getAvatarHandler cookie = withUserSession cookie $ \uid -> 
    withPlayerProfile uid $ \p -> return $ AvatarResponse (avatar p)

getCurrentSkillsHandler :: Maybe String -> Handler CurrentSkillsResponse
getCurrentSkillsHandler cookie = withUserSession cookie $ \uid -> 
    withPlayerProfile uid $ \p -> 
        return $ CurrentSkillsResponse (na p) (s1 p) (s2 p) (ult p)

getOwnedSkillsHandler :: Maybe String -> Handler OwnedSkillsResponse
getOwnedSkillsHandler cookie = withUserSession cookie $ \uid -> 
    withPlayerProfile uid $ \p -> return $ OwnedSkillsResponse (owned_skills p)

getCurrentClothesHandler :: Maybe String -> Handler CurrentClothesResponse
getCurrentClothesHandler cookie = withUserSession cookie $ \uid -> 
    withPlayerProfile uid $ \p -> 
        return $ CurrentClothesResponse (accessory p) (shirt p) (shoes p)

getOwnedClothesHandler :: Maybe String -> Handler OwnedClothesResponse
getOwnedClothesHandler cookie = withUserSession cookie $ \uid -> 
    withPlayerProfile uid $ \p -> return $ OwnedClothesResponse (owned_clothes p)


-- ==========================================
-- 4. HANDLERS NHÓM API QUAY GACHA (POST)
-- ==========================================

-- ==========================================
-- LOGIC TỈ LỆ GACHA (WEIGHTED RANDOM)
-- ==========================================

getWeight :: Int -> Int
getWeight 3 = 1   -- Rarity 3 (Đồ xịn): Tỉ lệ 1%
getWeight 2 = 20  -- Rarity 2 (Đồ khá): Tỉ lệ 20%
getWeight 1 = 79  -- Rarity 1 (Đồ cùi): Tỉ lệ 79%
getWeight _ = 10  -- Mặc định nếu nhập sai

-- Hàm random dựa trên trọng số
getRandomItemWithRate :: [GameItem] -> IO Text
getRandomItemWithRate pool = do
    -- 1. Tạo mảng trọng số tương ứng với các item trong pool
    let weights = map (\item -> getWeight (rarity item)) pool
    
    -- 2. Tính tổng tất cả trọng số (Ví dụ tổng = 100 hoặc hơn tùy số lượng item)
    let totalWeight = sum weights
    
    -- 3. Quay 1 con số ngẫu nhiên từ 1 đến totalWeight
    randVal <- randomRIO (1, totalWeight)
    
    -- 4. Tìm item tương ứng với con số vừa quay
    return $ pickItem randVal pool weights

-- Hàm đệ quy duyệt qua mảng để dò xem con số randVal rơi vào mốc của item nào
pickItem :: Int -> [GameItem] -> [Int] -> Text
pickItem _ [item] _ = item_id item -- Nếu chỉ còn 1 item, chắc chắn trúng nó
pickItem randVal (item:items) (w:ws)
    | randVal <= w = item_id item  -- Nếu số random rơi vào phạm vi của trọng số này -> Trúng!
    | otherwise    = pickItem (randVal - w) items ws -- Nếu chưa tới, trừ trọng số đi và xét tiếp món sau
pickItem _ [] _ = "" -- Trường hợp lỗi fallback

-- Giả lập pool đồ (Trong thực tế bạn có thể load từ Database khác)
gachaPoolClothes :: [Text]
gachaPoolClothes = ["shirt_2", "shirt_3", "shoes_2", "asc_2"]

-- Hàm chọn 1 đồ ngẫu nhiên từ list
getRandomItem :: [Text] -> IO Text
getRandomItem pool = do
    idx <- randomRIO (0, length pool - 1)
    return (pool !! idx)

-- ==========================================
-- HÀM GACHA CORE DÙNG CHUNG CHO TẤT CẢ
-- ==========================================
runGachaCore :: Int -> Text -> IO [GameItem] -> Maybe String -> Handler GachaResponse
runGachaCore count category getPool cookie = withUserSession cookie $ \uid -> do
    -- 1. Trừ số vé đúng bằng số lần quay
    success <- liftIO $ deductTickets uid count
    if not success
        then throwError err400 { errBody = "Không đủ vé để quay!" }
        else do
            -- 2. Lấy Pool tương ứng (Quần áo hoặc Skill)
            pool <- liftIO getPool
            if null pool
                then throwError err500 { errBody = "Hệ thống Gacha đang bảo trì (Pool rỗng)!" }
                else do
                    -- 3. Quay 'count' lần ngẫu nhiên
                    rolledItemIDs <- liftIO $ replicateM count (getRandomItemWithRate pool)
                    
                    -- 4. Lưu vào Database đúng mảng ("clothes" hoặc "skills")
                    liftIO $ addGachaItems uid category rolledItemIDs
                    
                    -- 5. Trả về kết quả
                    return $ GachaResponse "success" rolledItemIDs

-- HANDLERS QUẦN ÁO
gachaX1Handler, gachaX10Handler :: Maybe String -> Handler GachaResponse
gachaX1Handler  = runGachaCore 1  "clothes" getClothesPool
gachaX10Handler = runGachaCore 10 "clothes" getClothesPool

-- HANDLERS KỸ NĂNG
gachaSkillX1Handler, gachaSkillX10Handler :: Maybe String -> Handler GachaResponse
gachaSkillX1Handler  = runGachaCore 1  "skills" getSkillsPool
gachaSkillX10Handler = runGachaCore 10 "skills" getSkillsPool
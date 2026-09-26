{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}
module Controllers.AuthController where

import Control.Monad.IO.Class
import Data.Aeson hiding (Success)
import Data.Text (Text, pack, unpack)
import qualified Data.Text as T
import GHC.Generics
import Servant

--Dùng file nào thì bỏ comment
import Game_database.User (registerUser, loginUser, RegisterStatus(..), LoginStatus(..), getUserById, User(..))
--import Game_database.Usercopy (registerUser, loginUser, RegisterStatus(..), LoginStatus(..), getUser, User(..) )
import Game_database.Session (createSession, getUserBySession, deleteSession)

-- Auth Requests/Responses
-- ==========================================
-- DỮ LIỆU ĐĂNG KÝ
-- ==========================================
data RegisterRequest = RegisterRequest
  { regUsername :: Text 
  , regPassword :: Text
  } deriving (Show, Generic)

instance FromJSON RegisterRequest where
  parseJSON = genericParseJSON $ defaultOptions
    { fieldLabelModifier = \field ->
        case field of
          "regUsername" -> "username"
          "regPassword" -> "password"
          _             -> field
    }

-- ==========================================
-- DỮ LIỆU ĐĂNG NHẬP
-- ==========================================
data LoginRequest = LoginRequest
  { loginUsername :: Text
  , loginPassword :: Text
  } deriving (Show, Generic)

instance FromJSON LoginRequest where
  parseJSON = genericParseJSON $ defaultOptions
    { fieldLabelModifier = \field ->
        case field of
          "loginUsername" -> "username"
          "loginPassword" -> "password"
          _               -> field
    }


data AuthResponse = AuthResponse
  { status  :: String
  , message :: String
  } deriving (Show, Generic)

instance ToJSON AuthResponse

data MeResponse = MeResponse
    { auth :: AuthResponse
    , me   :: User
    } deriving (Show, Generic)

instance ToJSON MeResponse

-- ==========================================
-- 3. HÀM PHỤ TRỢ (HELPER)
-- ==========================================

-- Hàm bóc tách session_id từ chuỗi Cookie nhận được từ trình duyệt
parseSessionId :: String -> Maybe Text
parseSessionId cookieHeader =
  let pairs = map (break (== '=')) $ wordsWhen (== ';') cookieHeader
      trim = reverse . dropWhile (== ' ') . reverse . dropWhile (== ' ')
  in case lookup "session_id" [(trim k, drop 1 (trim v)) | (k, v) <- pairs] of
       Just val -> Just (pack val)
       Nothing  -> Nothing
  where
    wordsWhen p s = case dropWhile p s of
                      "" -> []
                      s' -> let (w, s'') = break p s' in w : wordsWhen p s'



registerHandler :: RegisterRequest -> Handler (Headers '[Header "Set-Cookie" String] AuthResponse)
registerHandler req = do
  -- Đổi username thành regUsername, password thành regPassword, và XÓA CHỮ 'pack $'
  result <- liftIO $ registerUser (regUsername req) (regPassword req)
  
  case result of
    Success -> do
       sID <- liftIO $ createSession (regUsername req)
       let cookieValue = "session_id=" ++ unpack sID ++ "; Path=/; HttpOnly; SameSite=Lax"
       return $ addHeader cookieValue (AuthResponse "success" "Đăng ký thành công!")
    UserAlreadyExists -> throwError err400 { errBody = "Tên tài khoản đã tồn tại!" }

loginHandler :: LoginRequest -> Handler (Headers '[Header "Set-Cookie" String] AuthResponse)
loginHandler req = do
  loginStatus <- liftIO $ loginUser (loginUsername req) (loginPassword req)
  case loginStatus of
    LoginSuccess -> do  -- BỎ CHỮ 'uid' Ở ĐÂY ĐI
      -- Truyền trực tiếp loginUsername vào hàm createSession
      sID <- liftIO $ createSession (loginUsername req)
      let cookieValue = "session_id=" ++ unpack sID ++ "; Path=/; HttpOnly; SameSite=Lax"
      return $ addHeader cookieValue (AuthResponse "success" "Đăng nhập thành công!")
      
    LoginFailed -> 
      throwError err401 { errBody = "Tài khoản hoặc mật khẩu không chính xác!" }

-- HANDLER ĐĂNG XUẤT (XÓA COOKIE)
logoutHandler :: Maybe String -> Handler (Headers '[Header "Set-Cookie" String] AuthResponse)
logoutHandler mCookieHeader = do
  case mCookieHeader >>= parseSessionId of
    Just sID -> do
      -- 1. Xóa session trong DB
      liftIO $ deleteSession sID
      
      -- 2. Set Max-Age=0 để trình duyệt xóa Cookie này
      let expiredCookie = "session_id=; Path=/; HttpOnly; Max-Age=0"
      return $ addHeader expiredCookie (AuthResponse "success" "Đăng xuất thành công!")
      
    Nothing -> do
      let expiredCookie = "session_id=; Path=/; HttpOnly; Max-Age=0"
      return $ addHeader expiredCookie (AuthResponse "success" "Không tìm thấy phiên đăng nhập!")

--Cua auth/me
-- Handler của auth/me
meHandler :: Maybe String -> Handler MeResponse
meHandler cookieHeader = do
    case cookieHeader of
        Nothing -> throwError err401
        Just cookie ->
            case parseSessionId cookie of
                Nothing -> throwError err401
                Just sessionId -> do
                    -- mUserId bây giờ chứa user_id thay vì username
                    mUserId <- liftIO $ getUserBySession sessionId
                    case mUserId of
                        Nothing -> throwError err401
                        Just uid -> do
                            -- Đổi từ getUser sang getUserById
                            maybeUser <- liftIO $ getUserById uid
                            case maybeUser of
                                Nothing -> throwError err404
                                Just u -> return (MeResponse (AuthResponse "success" "Xác thực thành công!") u)
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}
module Controllers.AuthController where

import Control.Monad.IO.Class
import Data.Aeson hiding (Result(..))
import Data.Text (Text, pack, unpack)
import qualified Data.Text as T
import GHC.Generics
import Servant

import Game_database.User (registerUser, verifyUserLogin, RegisterStatus(..), LoginStatus(..), getUserById, User(..),getUser,loginUser)
import Game_database.Session (createSession, getUserBySession, deleteSession)

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
  result <- liftIO $ registerUser (regUsername req) (regPassword req)
  
  case result of
    
    Success newUserID -> do
      -- Đã sửa: Truyền newUserID vào thay vì username
      sID <- liftIO $ createSession newUserID
      let cookieValue = "session_id=" ++ unpack sID ++ "; Path=/; HttpOnly; SameSite=Lax"

      -- 2. Dùng luôn newUserID, XÓA HOÀN TOÀN cục code gọi hàm getUser đi!
      return $ addHeader cookieValue (AuthResponse "success" "Đăng ký thành công!")
      
    UserAlreadyExists -> throwError err400 { errBody = "Tên tài khoản đã tồn tại!" }

loginHandler :: LoginRequest -> Handler (Headers '[Header "Set-Cookie" String] AuthResponse)
loginHandler req = do
  loginStatus <- liftIO $ loginUser (loginUsername req) (loginPassword req)
  
  case loginStatus of
    -- Hứng uID được trả về từ LoginSuccess
    LoginSuccess uID -> do
      -- Đã sửa: Truyền uID vào thay vì username
      sID <- liftIO $ createSession uID
      let cookieValue = "session_id=" ++ unpack sID ++ "; Path=/; HttpOnly; SameSite=Lax"
      
      return $ addHeader cookieValue (AuthResponse "success" "Đăng nhập thành công!")
      
    LoginFailed -> 
      throwError err401 { errBody = "Tài khoản hoặc mật khẩu không chính xác!" }

logoutHandler :: Maybe String -> Handler (Headers '[Header "Set-Cookie" String] AuthResponse)
logoutHandler mCookieHeader = do
  let expiredCookie = "session_id=; Path=/; HttpOnly; Max-Age=0"
  
  case mCookieHeader >>= parseSessionId of
    Just sID -> do
      liftIO $ deleteSession sID
      return $ addHeader expiredCookie (AuthResponse "success" "Đăng xuất thành công!")
    Nothing -> do
      return $ addHeader expiredCookie (AuthResponse "success" "Không tìm thấy phiên đăng nhập!")

meHandler :: Maybe String -> Handler MeResponse
meHandler cookieHeader = do
    case cookieHeader of
        Nothing -> throwError err401
        Just cookie ->
            case parseSessionId cookie of
                Nothing -> throwError err401
                Just sessionId -> do
                    -- mUserId bây giờ là user_id (kiểu Text)
                    mUserId <- liftIO $ getUserBySession sessionId
                    case mUserId of
                        Nothing -> throwError err401
                        Just uid -> do
                            maybeUser <- liftIO $ getUserById uid
                            case maybeUser of
                                Nothing -> throwError err404
                                Just u -> 
                                    return (MeResponse (AuthResponse "success" "Xác thực thành công!") u)
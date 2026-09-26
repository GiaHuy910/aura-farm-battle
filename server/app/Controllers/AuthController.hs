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
  { status  :: Text
  , userID :: Text
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
    -- 1. Hứng trực tiếp biến Text đi kèm với Success
    Success newUserID -> do
      sID <- liftIO $ createSession (regUsername req)
      let cookieValue = "session_id=" ++ unpack sID ++ "; Path=/; HttpOnly; SameSite=Lax"
      
      -- 2. Dùng luôn newUserID, XÓA HOÀN TOÀN cục code gọi hàm getUser đi!
      return $ addHeader cookieValue (AuthResponse "success" newUserID)
      
    UserAlreadyExists -> throwError err400 { errBody = "Tên tài khoản đã tồn tại!" }

loginHandler :: LoginRequest -> Handler (Headers '[Header "Set-Cookie" String] AuthResponse)
loginHandler req = do
  loginStatus <- liftIO $ loginUser (loginUsername req) (loginPassword req)
  
  case loginStatus of
    LoginSuccess -> do
      sID <- liftIO $ createSession (loginUsername req)
      let cookieValue = "session_id=" ++ unpack sID ++ "; Path=/; HttpOnly; SameSite=Lax"
      
      -- Tìm user để lấy user_id trả về
      maybeUser <- liftIO $ getUser (loginUsername req)
      let uID = case maybeUser of
            Just u -> user_id u
            Nothing -> ""
                  
      return $ addHeader cookieValue (AuthResponse "success" uID)
      
    LoginFailed -> 
      throwError err401 { errBody = "Tài khoản hoặc mật khẩu không chính xác!" }

logoutHandler :: Maybe String -> Handler (Headers '[Header "Set-Cookie" String] AuthResponse)
logoutHandler mCookieHeader = do
  let expiredCookie = "session_id=; Path=/; HttpOnly; Max-Age=0"
  
  case mCookieHeader >>= parseSessionId of
    Just sID -> do
      liftIO $ deleteSession sID
      return $ addHeader expiredCookie (AuthResponse "success" "")
    Nothing -> do
      return $ addHeader expiredCookie (AuthResponse "success" "")

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
                                    return (MeResponse (AuthResponse "success" uid) u)
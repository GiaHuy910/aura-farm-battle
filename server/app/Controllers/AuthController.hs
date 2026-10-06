{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedRecordDot #-}
{- HLINT ignore "Use newtype instead of data" -}

module Controllers.AuthController 
  ( withAuthenticatedUser
  , parseSessionId
  , registerHandler
  , loginHandler
  , logoutHandler
  , meHandler
  , RegisterRequest(..)
  , LoginRequest(..)
  , AuthResponse(..)
  , MeResponse(..)
  ) where

import Control.Monad.IO.Class
import Data.Aeson hiding (Result(..))
import Data.Text (Text, pack, unpack)
import GHC.Generics
import Servant

import Model.User ( registerUser, loginUser, getUserById, User(..), RegisterStatus(..), LoginStatus(..), mapEquippedSkills, mapEquippedClothes )
import Model.Session (createSession, getUserBySession, deleteSession)

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

data PublicUser = PublicUser
  { user_id       :: Text
  , username      :: Text
  , tickets       :: Int
  , equipped_skills  :: [Text]
  , equipped_clothes :: [Text]
  , pity_skill_leg        :: Int
  , pity_clothe_leg       :: Int
  } deriving (Show, Generic)

instance ToJSON PublicUser

data MeResponse = MeResponse
    { auth :: AuthResponse
    , me   :: PublicUser 
    } deriving (Show, Generic)

instance ToJSON MeResponse

parseSessionId :: String -> Maybe Text
parseSessionId cookieHeader =
  let cpairs = map (break (== '=')) $ wordsWhen (== ';') cookieHeader
      trim = reverse . dropWhile (== ' ') . reverse . dropWhile (== ' ')
  in case lookup "session_id" [(trim k, drop 1 (trim v)) | (k, v) <- cpairs] of
       Just val -> Just (pack val)
       Nothing  -> Nothing
  where
    wordsWhen p s = case dropWhile p s of
                      "" -> []
                      s' -> let (w, s'') = break p s' in w : wordsWhen p s''

registerHandler :: RegisterRequest -> Handler (Headers '[Header "Set-Cookie" String] AuthResponse)
registerHandler req = do
  result <- liftIO $ registerUser (regUsername req) (regPassword req)
  case result of
    Success newUserID -> do
      let maxage = 172800
      sID <- liftIO $ createSession newUserID maxage
      let cookieValue = "session_id=" ++ unpack sID ++ "; Path=/; HttpOnly; SameSite=Lax; Max-Age=" ++ show maxage -- 60*60*24*3 = 3 days
      return $ addHeader cookieValue (AuthResponse "success" "Đăng ký thành công!")
    UserAlreadyExists -> throwError err400 { errBody = "Tên tài khoản đã tồn tại!" }

loginHandler :: LoginRequest -> Handler (Headers '[Header "Set-Cookie" String] AuthResponse)
loginHandler req = do
  loginStatus <- liftIO $ loginUser (loginUsername req) (loginPassword req)
  case loginStatus of
    LoginSuccess uID -> do
      let maxage = 172800
      sID <- liftIO $ createSession uID maxage
      let cookieValue = "session_id=" ++ unpack sID ++ "; Path=/; HttpOnly; SameSite=Lax; Max-Age=" ++ show maxage-- 60*60*24*3 = 3 days
      return $ addHeader cookieValue (AuthResponse "success" "Đăng nhập thành công!")
    LoginFailed -> throwError err401 { errBody = "Tài khoản hoặc mật khẩu không chính xác!" }

logoutHandler :: Maybe String -> Handler (Headers '[Header "Set-Cookie" String] AuthResponse)
logoutHandler mCookieHeader = do
  let expiredCookie = "session_id=; Path=/; HttpOnly; Max-Age=0"
  case mCookieHeader >>= parseSessionId of
    Just sID -> do
      liftIO $ deleteSession sID
      return $ addHeader expiredCookie (AuthResponse "success" "Đăng xuất thành công!")
    Nothing -> return $ addHeader expiredCookie (AuthResponse "success" "Không tìm thấy phiên đăng nhập!")

meHandler :: Maybe String -> Handler MeResponse
meHandler cookieHeader = withAuthenticatedUser cookieHeader $ \u -> do
      let skills = mapEquippedSkills u.equipped_na u.equipped_s1 u.equipped_s2 u.equipped_ult
          clothes = mapEquippedClothes u.quipped_acc u.equipped_shirt u.equipped_shoes
      return $ MeResponse 
            (AuthResponse "success" "OK") 
            (PublicUser 
                  u.user_id 
                  u.username 
                  u.tickets 
                  skills
                  clothes
                  u.pity_skill_leg
                  u.pity_clothe_leg
                  )

withAuthenticatedUser :: Maybe String -> (User -> Handler a) -> Handler a
withAuthenticatedUser cookieHeader action = do
    case cookieHeader >>= parseSessionId of
        Nothing -> throwError err401 { errBody = "Chưa đăng nhập!" }
        Just sid -> do
            mUid <- liftIO $ getUserBySession sid
            case mUid of
                Nothing -> throwError err401 { errBody = "Session không hợp lệ!" }
                Just uid -> do
                    mUser <- liftIO $ getUserById uid
                    case mUser of
                        Nothing -> throwError err404 { errBody = "Không tìm thấy người dùng!" }
                        Just u  -> action u

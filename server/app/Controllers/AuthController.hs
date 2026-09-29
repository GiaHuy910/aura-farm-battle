{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedRecordDot #-}
{- HLINT ignore "Use newtype instead of data" -}

module Controllers.AuthController where

import Control.Monad (replicateM)
import Control.Monad.IO.Class
import Data.Aeson hiding (Result(..))
import Data.Text (Text, pack, unpack)
import GHC.Generics
import Servant
import System.Random (randomRIO)

import Model.User ( registerUser, loginUser, getUserById, User(..), RegisterStatus(..), LoginStatus(..), ItemType(..), deductTickets, addGachaItems )
import Model.Clothe (Clothe(..), getClothesPool)
import Model.Skill (Skill(..), getSkillsPool)
import Model.Session (createSession, getUserBySession, deleteSession)
import qualified Model.Clothe as Clothe
import qualified Model.Skill as Skill

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
  { user_id :: Text
  , username :: Text
  } deriving (Show, Generic)

instance ToJSON PublicUser

data MeResponse = MeResponse
    { auth :: AuthResponse
    , me   :: PublicUser 
    } deriving (Show, Generic)

instance ToJSON MeResponse

data TicketsResponse = TicketsResponse { tickets :: Int } deriving (Show, Generic)
instance ToJSON TicketsResponse

data AvatarResponse = AvatarResponse { avatar :: Text } deriving (Show, Generic)
instance ToJSON AvatarResponse

data CurrentSkillsResponse = CurrentSkillsResponse
  { na :: Skill, s1 :: Skill, s2 :: Skill, ult :: Skill } deriving (Show, Generic)
instance ToJSON CurrentSkillsResponse

data OwnedSkillsResponse = OwnedSkillsResponse { owned_skills :: [Skill] } deriving (Show, Generic)
instance ToJSON OwnedSkillsResponse

data CurrentClothesResponse = CurrentClothesResponse
  { accessory :: Clothe, shirt :: Clothe, shoes :: Clothe } deriving (Show, Generic)
instance ToJSON CurrentClothesResponse

data OwnedClothesResponse = OwnedClothesResponse { owned_clothes :: [Clothe] } deriving (Show, Generic)
instance ToJSON OwnedClothesResponse

data GachaResponse = GachaResponse
  { status :: String
  , items  :: [Text]
  } deriving (Show, Generic)
instance ToJSON GachaResponse

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
      sID <- liftIO $ createSession newUserID
      let cookieValue = "session_id=" ++ unpack sID ++ "; Path=/; HttpOnly; SameSite=Lax"
      return $ addHeader cookieValue (AuthResponse "success" "Đăng ký thành công!")
    UserAlreadyExists -> throwError err400 { errBody = "Tên tài khoản đã tồn tại!" }

loginHandler :: LoginRequest -> Handler (Headers '[Header "Set-Cookie" String] AuthResponse)
loginHandler req = do
  loginStatus <- liftIO $ loginUser (loginUsername req) (loginPassword req)
  case loginStatus of
    LoginSuccess uID -> do
      sID <- liftIO $ createSession uID
      let cookieValue = "session_id=" ++ unpack sID ++ "; Path=/; HttpOnly; SameSite=Lax"
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
meHandler cookieHeader = withAuthenticatedUser cookieHeader $ \u ->
    return $ MeResponse (AuthResponse "success" "OK") (PublicUser u.user_id u.username)

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

getTicketsHandler :: Maybe String -> Handler TicketsResponse
getTicketsHandler cookie = withAuthenticatedUser cookie $ \u -> return $ TicketsResponse u.tickets

getAvatarHandler :: Maybe String -> Handler AvatarResponse
getAvatarHandler cookie = withAuthenticatedUser cookie $ \u -> return $ AvatarResponse u.avatar

getCurrentSkillsHandler :: Maybe String -> Handler CurrentSkillsResponse
getCurrentSkillsHandler cookie = withAuthenticatedUser cookie $ \u -> return $ CurrentSkillsResponse u.na u.s1 u.s2 u.ult

getOwnedSkillsHandler :: Maybe String -> Handler OwnedSkillsResponse
getOwnedSkillsHandler cookie = withAuthenticatedUser cookie $ \u -> return $ OwnedSkillsResponse u.owned_skills

getCurrentClothesHandler :: Maybe String -> Handler CurrentClothesResponse
getCurrentClothesHandler cookie = withAuthenticatedUser cookie $ \u -> return $ CurrentClothesResponse u.accessory u.shirt u.shoes

getOwnedClothesHandler :: Maybe String -> Handler OwnedClothesResponse
getOwnedClothesHandler cookie = withAuthenticatedUser cookie $ \u -> return $ OwnedClothesResponse u.owned_clothes

-- HỆ THỐNG GACHA
getWeight :: Text -> Int
getWeight "Mythical"  = 1
getWeight "Legendary" = 3
getWeight "Epic"      = 10
getWeight "Rare"      = 17
getWeight "Uncommon"  = 20
getWeight _           = 50

pickItem :: Int -> [a] -> (a -> Text) -> (a -> Text) -> [Int] -> Text
pickItem _ [item] getId _ _ = getId item
pickItem randVal (item:items) getId getRarity (w:ws)
    | randVal <= w = getId item
    | otherwise    = pickItem (randVal - w) items getId getRarity ws
pickItem _ [] _ _ _ = ""

getRandomItemWithRate :: [a] -> (a -> Text) -> (a -> Text) -> IO Text
getRandomItemWithRate pool getId getRarity = do
    let weights = map (getWeight . getRarity) pool
    let totalWeight = sum weights
    randVal <- randomRIO (1, totalWeight)
    return $ pickItem randVal pool getId getRarity weights

runGachaCore :: Int -> ItemType -> IO [a] -> (a -> Text) -> (a -> Text) -> Maybe String -> Handler GachaResponse
runGachaCore count category getPool getId getRarity cookie = withAuthenticatedUser cookie $ \u -> do
    let uid = u.user_id
    success <- liftIO $ deductTickets uid count
    if not success
        then throwError err400 { errBody = "Không đủ vé để quay!" }
        else do
            pool <- liftIO getPool
            if null pool
                then throwError err500 { errBody = "Pool rỗng!" }
                else do
                    rolledIDs <- liftIO $ replicateM count (getRandomItemWithRate pool getId getRarity)
                    liftIO $ addGachaItems uid category rolledIDs
                    return $ GachaResponse "success" rolledIDs

gachaX1Handler, gachaX10Handler :: Maybe String -> Handler GachaResponse
gachaX1Handler = runGachaCore 1  ClotheType getClothesPool clothe_id Clothe.rarity
gachaX10Handler = runGachaCore 10 ClotheType getClothesPool clothe_id Clothe.rarity

gachaSkillX1Handler, gachaSkillX10Handler :: Maybe String -> Handler GachaResponse
gachaSkillX1Handler  = runGachaCore 1  SkillType getSkillsPool skill_id Skill.rarity
gachaSkillX10Handler = runGachaCore 10 SkillType getSkillsPool skill_id Skill.rarity
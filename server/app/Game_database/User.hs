{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE DeriveGeneric #-}

module Game_database.User where

import GHC.Generics (Generic)
import Data.Aeson (ToJSON)
import Database.MongoDB
import Data.Maybe (fromMaybe)
import Data.UUID.V4 (nextRandom)
import Data.UUID (toString)
import Control.Monad.IO.Class (liftIO)
import Data.Password.Bcrypt (PasswordHash(..),PasswordCheck(..),hashPassword, mkPassword, unPasswordHash,checkPassword)
import Data.Text (Text, pack)
import Data.Text.Internal.StrictBuilder (toText)

data User = User
  { user_id   :: Text
  , username :: Text
  , password :: Text
  } deriving (Show, Generic)

instance ToJSON User

runDB :: Action IO a -> IO a
runDB action = do
    pipe <- connect (host "127.0.0.1")
    result <- access pipe master "aura-farm-battle" action
    close pipe
    return result

getUsers :: IO [User] 
getUsers = runDB $ do
    docs <- find (select [] "user") >>= rest
    return (map docToUser docs)

getUser:: Text -> IO (Maybe User) 
getUser uname = runDB $ do 
    let query = (select ["username" =: uname] "user") { project = ["user_id" =: True, "username" =: True] }
    user <- findOne query
    return (fmap docToUser user)

-- Bổ sung hàm getUserById để dùng trong AuthController /auth/me
getUserById :: Text -> IO (Maybe User) 
getUserById uid = runDB $ do 
    let query = (select ["user_id" =: uid] "user") { project = ["user_id" =: True, "username" =: True] }
    userDoc <- findOne query
    return (fmap docToUser userDoc)

docToUser :: Document -> User
docToUser doc = User
  { user_id   = fromMaybe "" (doc !? "user_id")
  , username = fromMaybe "" (doc !? "username")
  , password = fromMaybe "" (doc !? "password")
  }

userToDoc :: User -> Document
userToDoc u =
  [ "user_id"   =: user_id u
  , "username" =: username u
  , "password" =: password u
  ]

createUser:: User -> IO()
createUser newUser = runDB $ do
    insert_ "user" (userToDoc newUser)

-- Cập nhật RegisterStatus để mang theo user_id khi thành công
data RegisterStatus = Success Text | UserAlreadyExists deriving (Show, Eq)
-- Cập nhật LoginStatus có kèm Text
data LoginStatus = LoginSuccess Text | LoginFailed deriving (Show, Eq)

loginUser :: Text -> Text -> IO LoginStatus
loginUser uname pass = do
    existingDocs <- runDB $ find (select ["username" =: uname] "user" ) >>= rest
    if null existingDocs
        then return LoginFailed
        else do
            let userDoc = head existingDocs
            let storedHashedPass = fromMaybe "" (userDoc !? "password")
            let storedPasswordHash = PasswordHash storedHashedPass
            let checkresult = checkPassword (mkPassword pass) storedPasswordHash
            case checkresult of
                PasswordCheckSuccess -> do
                    -- Lấy user_id từ database ra và gắn vào LoginSuccess
                    let uid = fromMaybe "" (userDoc !? "user_id")
                    return (LoginSuccess uid)
                _ -> return LoginFailed

loginUser :: Text -> Text -> IO LoginStatus
loginUser uname pass = do
    existingDocs <- runDB $ find (select ["username" =: uname] "user" ) >>= rest
    if null existingDocs
        then return LoginFailed
        else do
            let userDoc = head existingDocs
            let storedHashedPass = fromMaybe "" (userDoc !? "password")
            let storedPasswordHash = PasswordHash storedHashedPass
            let checkresult = checkPassword (mkPassword pass) storedPasswordHash
            case checkresult of
                PasswordCheckSuccess -> return LoginSuccess 
                _ -> return LoginFailed

verifyUserLogin :: Text -> Text -> IO (Maybe Text)
verifyUserLogin uname pwd = runDB $ do
    maybeUser <- findOne (select ["username" =: uname, "password" =: pwd] "user")
    case maybeUser of
        Nothing -> return Nothing
        Just uDoc -> return (Just $ fromMaybe "" (uDoc !? "user_id"))
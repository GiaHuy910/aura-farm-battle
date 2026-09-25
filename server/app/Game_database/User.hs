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

getUsers :: IO [User] --Whole ass list of users in user_db
getUsers = runDB $ do
    docs <- find (select [] "user") >>= rest
    return (map docToUser docs)

getUser:: Text -> IO (Maybe User) --One specific user by username
getUser uname = runDB $ do 
    let query = (select ["username" =: uname] "user") { project = ["user_id" =: True, "username" =: True] }
    user <- findOne query
    return (fmap docToUser user)

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
-- deleteUser :: Text -> IO ()
-- deleteUser userId = runDB $ do
--     deleteOne (select ["user_id" =: userId] "user")  

data RegisterStatus = Success | UserAlreadyExists deriving (Show, Eq)
data LoginStatus = LoginSuccess | LoginFailed deriving (Show, Eq)

--Hàm đăng ký: kiểm tra có trùng user trong user_db ko, có thì trả về UserAlreadyExists, ko thì tạo user mới và trả về Success
registerUser :: Text -> Text -> IO RegisterStatus
registerUser uname pass = do 
    existingDocs <- runDB $ find (select ["username" =: uname] "user") >>= rest
    if not (null existingDocs)
        then return UserAlreadyExists
        else do
            hashedPass <- hashPassword (mkPassword pass)
            userID <- liftIO nextRandom
            let generatedUserID = pack (toString userID)    
            let newUser = User {user_id = generatedUserID, username = uname,password = unPasswordHash hashedPass}
            createUser newUser
            return Success
--Hàm đăng nhập: kiểm tra có trùng user và pass trong user_db ko, ko thì trả về LoginFailed, có thì trả về LoginSuccess
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



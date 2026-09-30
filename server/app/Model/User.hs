{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE DeriveGeneric #-}

module Model.User where

import GHC.Generics (Generic)
import Data.Aeson (ToJSON)
import Database.MongoDB
import Data.Maybe (fromMaybe)
import Data.UUID.V4 (nextRandom)
import Data.UUID (toString)
import Control.Monad.IO.Class (liftIO)
import Data.Password.Bcrypt (PasswordHash(..), PasswordCheck(..), hashPassword, mkPassword, unPasswordHash, checkPassword)
import Data.Text (Text, pack)
--Xóa 2 cái import Clothe với Skill tại thấy nó vô dụn quá

data User = User
  { user_id       :: Text
  , username      :: Text
  , password      :: Text
  , tickets       :: Int
  , avatar        :: Text
  , na            :: Text
  , s1            :: Text
  , s2            :: Text
  , ult           :: Text
  , accessory     :: Text
  , shirt         :: Text
  , shoes         :: Text
  , owned_clothes :: [Text]
  , owned_skills  :: [Text]
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

getUser :: Text -> IO (Maybe User)
getUser uname = runDB $ do
    user <- findOne (select ["username" =: uname] "user")
    return (fmap docToUser user)

getUserById :: Text -> IO (Maybe User)
getUserById uid = runDB $ do
    userDoc <- findOne (select ["user_id" =: uid] "user")
    return (fmap docToUser userDoc)

docToUser :: Document -> User
docToUser doc = User
  { user_id       = fromMaybe "" (doc !? "user_id")
  , username      = fromMaybe "" (doc !? "username")
  , password      = fromMaybe "" (doc !? "password")
  , tickets       = fromMaybe 0  (doc !? "tickets")
  , avatar        = fromMaybe "" (doc !? "avatar")
  , na            = fromMaybe "" (doc !? "na")
  , s1            = fromMaybe "" (doc !? "s1")
  , s2            = fromMaybe "" (doc !? "s2")
  , ult           = fromMaybe "" (doc !? "ult")
  , accessory     = fromMaybe "" (doc !? "accessory")
  , shirt         = fromMaybe "" (doc !? "shirt")
  , shoes         = fromMaybe "" (doc !? "shoes")
  , owned_clothes = fromMaybe [] (doc !? "owned_clothes")
  , owned_skills  = fromMaybe [] (doc !? "owned_skills")
  }

userToDoc :: User -> Document
userToDoc u =
  [ "user_id"       =: user_id u
  , "username"      =: username u
  , "password"      =: password u
  , "tickets"       =: tickets u
  , "avatar"        =: avatar u
  , "na"            =: na u
  , "s1"            =: s1 u
  , "s2"            =: s2 u
  , "ult"           =: ult u
  , "accessory"     =: accessory u
  , "shirt"         =: shirt u
  , "shoes"         =: shoes u
  , "owned_clothes" =: owned_clothes u
  , "owned_skills"  =: owned_skills u
  ]

data RegisterStatus = Success Text | UserAlreadyExists deriving (Show, Eq)
data LoginStatus = LoginSuccess Text | LoginFailed deriving (Show, Eq)

registerUser :: Text -> Text -> IO RegisterStatus
registerUser uname pass = do
    existingDocs <- runDB $ find (select ["username" =: uname] "user") >>= rest
    if not (null existingDocs)
        then return UserAlreadyExists
        else do
            hashedPass <- hashPassword (mkPassword pass)
            userID <- liftIO nextRandom
            let generatedUserID = pack (toString userID)
            let newUser = User
                  { user_id = generatedUserID
                  , username = uname
                  , password = unPasswordHash hashedPass
                  , tickets = 100
                  , avatar = ""
                  , na = ""
                  ,s1 = ""
                  ,s2 = ""
                  ,ult = ""
                  ,accessory = ""
                  ,shirt = ""
                  ,shoes = ""
                  , owned_clothes = [], owned_skills = []
                  }
            runDB $ insert_ "user" (userToDoc newUser)
            return (Success generatedUserID)

loginUser :: Text -> Text -> IO LoginStatus
loginUser uname pass = do
    existingDocs <- runDB $ find (select ["username" =: uname] "user") >>= rest   --Làm biến giải thích quá, nếu bạn có trình bạn sẽ tự hiểu ha
    if null existingDocs
        then return LoginFailed
        else do
            let userDoc = head existingDocs
            let storedHashedPass = fromMaybe "" (userDoc !? "password")
            let checkresult = checkPassword (mkPassword pass) (PasswordHash storedHashedPass)
            case checkresult of
                PasswordCheckSuccess -> do
                    let uid = fromMaybe "" (userDoc !? "user_id")
                    return (LoginSuccess uid)
                _ -> return LoginFailed

deductTickets :: Text -> Int -> IO Bool
deductTickets uid amount = runDB $ do
    mDoc <- findOne (select ["user_id" =: uid] "user") --Tìm user qua user_id
    case mDoc of
        Nothing -> return False   --Nếu k có user nào
        Just doc -> do
            let currentTickets = fromMaybe 0 (doc !? "tickets")  --Lấy tickets và tính
            if currentTickets >= amount
                then do
                    modify (select ["user_id" =: uid] "user")
                           ["$inc" =: ["tickets" =: (-amount)]]
                    return True
                else return False

data ItemType = ClotheType | SkillType deriving (Show, Eq)

--Tối ưu hàm cho nó ngắn vầy chạy cho lẹ
addGachaItems :: Text -> ItemType -> [Text] -> IO ()
addGachaItems uid itemType newIDs = do
    case itemType of
      ClotheType -> do
        runDB $ modify (select ["user_id" =: uid] "user")
                        ["$addToSet" =: ["owned_clothes" =: ["$each" =: newIDs]]]
      SkillType -> do
        runDB $ modify (select ["user_id" =: uid] "user")
                        ["$addToSet" =: ["owned_skills" =: ["$each" =: newIDs]]]
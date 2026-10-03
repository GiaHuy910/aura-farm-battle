{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE DeriveGeneric #-}

module Model.User
    (
    User(..)
    , getUser
    , getUserById
    , registerUser
    , loginUser
    , deductTickets
    , addGachaItems
    , ItemType(..)
    ) where

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
  , equipped_na            :: Text
  , equipped_s1            :: Text
  , equipped_s2            :: Text
  , equipped_ult           :: Text
  , equipped_accessory     :: Text
  , equipped_shirt         :: Text
  , equipped_shoes         :: Text
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
    docs <- find ((select [] "user") { project = ["password" =: (0 :: Int)] }) >>= rest
    return (map docToUser docs)

getUser :: Text -> IO (Maybe User)
getUser uname = runDB $ do
    user <- findOne ((select ["username" =: uname] "user") { project = ["password" =: (0 :: Int)] })
    return (fmap docToUser user)

getUserById :: Text -> IO (Maybe User)
getUserById uid = runDB $ do
    -- Sử dụng record update { project = ... }
    maybeDoc <- findOne ((select ["user_id" =: uid] "user") { project = ["password" =: (0 :: Int)] })
    case maybeDoc of
        Nothing -> return Nothing
        Just doc -> return $ Just (docToUser doc)

docToUser :: Document -> User
docToUser doc = User
  { user_id       = fromMaybe "" (doc !? "user_id")
  , username      = fromMaybe "" (doc !? "username")
  , password      = fromMaybe "" (doc !? "password")
  , tickets       = fromMaybe 0  (doc !? "tickets")
  , avatar        = fromMaybe "" (doc !? "avatar")
  , equipped_na            = fromMaybe "" (doc !? "equipped_na")
  , equipped_s1            = fromMaybe "" (doc !? "equipped_s1")
  , equipped_s2            = fromMaybe "" (doc !? "equipped_s2")
  , equipped_ult           = fromMaybe "" (doc !? "equipped_ult")
  , equipped_accessory     = fromMaybe "" (doc !? "equipped_accessory")
  , equipped_shirt         = fromMaybe "" (doc !? "equipped_shirt")
  , equipped_shoes         = fromMaybe "" (doc !? "equipped_shoes")
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
  , "equipped_na"            =: equipped_na u
  , "equipped_s1"            =: equipped_s1 u
  , "equipped_s2"            =: equipped_s2 u
  , "equipped_ult"           =: equipped_ult u
  , "equipped_accessory"     =: equipped_accessory u
  , "equipped_shirt"         =: equipped_shirt u
  , "equipped_shoes"         =: equipped_shoes u
  , "owned_clothes" =: owned_clothes u
  , "owned_skills"  =: owned_skills u
  ]

data RegisterStatus = Success Text | UserAlreadyExists deriving (Show, Eq)
data LoginStatus = LoginSuccess Text | LoginFailed deriving (Show, Eq)

registerUser :: Text -> Text -> IO RegisterStatus
registerUser uname pass = do
    existingDocs <- runDB $ find ((select ["username" =: uname] "user") { project = ["user_id" =: (1 :: Int)] }) >>=rest
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
                  , tickets = 0
                  , avatar = ""
                  , equipped_na = "na_1"
                  , equipped_s1 = "s1_1"
                  , equipped_s2 = "s2_1"
                  , equipped_ult = "ult_1"
                  , equipped_accessory = "accessory_1"
                  , equipped_shirt = "shirt_1"
                  , equipped_shoes = "shoes_1"
                  , owned_clothes = ["shoes_1","shirt_1","accessory_1"], owned_skills = ["ult_1","s2_1","s1_1","na_1"]
                  }
            runDB $ insert_ "user" (userToDoc newUser)
            return (Success generatedUserID)

loginUser :: Text -> Text -> IO LoginStatus
loginUser uname pass = do
    existingDocs <- runDB $ find ((select ["username" =: uname] "user") { project = ["user_id" =: (1 :: Int), "password" =: (1 :: Int)] })
    case existingDocs of
        [] -> return LoginFailed -- Nếu danh sách rỗng (không tìm thấy)
        (userDoc:_) -> do        -- Lấy an toàn phần tử đầu tiên bằng Pattern Matching
            let storedHashedPass = fromMaybe "" (userDoc !? "password")
            let checkresult = checkPassword (mkPassword pass) (PasswordHash storedHashedPass)
            case checkresult of
                PasswordCheckSuccess -> do
                    let uid = fromMaybe "" (userDoc !? "user_id")
                    return (LoginSuccess uid)
                _ -> return LoginFailed

deductTickets :: Text -> Int -> IO Bool
deductTickets uid amount = runDB $ do
    mDoc <- findOne ((select ["user_id" =: uid] "user") { project = ["tickets" =: (1 :: Int)] }) --Tìm user qua user_id
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
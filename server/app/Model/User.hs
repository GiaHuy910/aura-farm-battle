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

import Model.Clothe (Clothe(..), docToClothe, clotheToDoc, getClothesByIds)
import Model.Skill (Skill(..), docToSkill, skillToDoc, getSkillsByIds)

data User = User
  { user_id       :: Text
  , username      :: Text
  , password      :: Text
  , tickets       :: Int
  , avatar        :: Text
  , na            :: Skill
  , s1            :: Skill
  , s2            :: Skill
  , ult           :: Skill
  , accessory     :: Clothe
  , shirt         :: Clothe
  , shoes         :: Clothe
  , owned_clothes :: [Clothe]
  , owned_skills  :: [Skill]
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
  , na            = docToSkill  (fromMaybe [] (doc !? "na"))
  , s1            = docToSkill  (fromMaybe [] (doc !? "s1"))
  , s2            = docToSkill  (fromMaybe [] (doc !? "s2"))
  , ult           = docToSkill  (fromMaybe [] (doc !? "ult"))
  , accessory     = docToClothe (fromMaybe [] (doc !? "accessory"))
  , shirt         = docToClothe (fromMaybe [] (doc !? "shirt"))
  , shoes         = docToClothe (fromMaybe [] (doc !? "shoes"))
  , owned_clothes = map docToClothe (fromMaybe [] (doc !? "owned_clothes"))
  , owned_skills  = map docToSkill  (fromMaybe [] (doc !? "owned_skills"))
  }

userToDoc :: User -> Document
userToDoc u =
  [ "user_id"       =: user_id u
  , "username"      =: username u
  , "password"      =: password u
  , "tickets"       =: tickets u
  , "avatar"        =: avatar u
  , "na"            =: skillToDoc (na u)
  , "s1"            =: skillToDoc (s1 u)
  , "s2"            =: skillToDoc (s2 u)
  , "ult"           =: skillToDoc (ult u)
  , "accessory"     =: clotheToDoc (accessory u)
  , "shirt"         =: clotheToDoc (shirt u)
  , "shoes"         =: clotheToDoc (shoes u)
  , "owned_clothes" =: map clotheToDoc (owned_clothes u)
  , "owned_skills"  =: map skillToDoc (owned_skills u)
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
                  , na = docToSkill [], s1 = docToSkill [], s2 = docToSkill [], ult = docToSkill []
                  , accessory = docToClothe [], shirt = docToClothe [], shoes = docToClothe []
                  , owned_clothes = [], owned_skills = []
                  }
            runDB $ insert_ "user" (userToDoc newUser)
            return (Success generatedUserID)

loginUser :: Text -> Text -> IO LoginStatus
loginUser uname pass = do
    existingDocs <- runDB $ find (select ["username" =: uname] "user") >>= rest
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
    mDoc <- findOne (select ["user_id" =: uid] "user")
    case mDoc of
        Nothing -> return False
        Just doc -> do
            let currentTickets = fromMaybe 0 (doc !? "tickets")
            if currentTickets >= amount
                then do
                    modify (select ["user_id" =: uid] "user")
                           ["$inc" =: ["tickets" =: (-amount)]]
                    return True
                else return False

data ItemType = ClotheType | SkillType deriving (Show, Eq)

-- Đã sửa: Chuyển đổi item IDs thành BSON Document hoàn chỉnh trước khi lưu vào MongoDB
addGachaItems :: Text -> ItemType -> [Text] -> IO ()
addGachaItems uid itemType newIDs = do
    case itemType of
      ClotheType -> do
        clothes <- getClothesByIds newIDs
        let docs = map clotheToDoc clothes
        runDB $ modify (select ["user_id" =: uid] "user")
                       ["$addToSet" =: ["owned_clothes" =: ["$each" =: docs]]]
      SkillType -> do
        skills <- getSkillsByIds newIDs
        let docs = map skillToDoc skills
        runDB $ modify (select ["user_id" =: uid] "user")
                       ["$addToSet" =: ["owned_skills" =: ["$each" =: docs]]]
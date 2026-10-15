{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE DeriveGeneric #-}

module Model.User
    (
        User(..),
        getUsers,
        getUser,
        getUserById,
        registerUser,
        loginUser,
        deductTickets,
        addGachaItems,
        mapEquippedSkills,
        mapEquippedClothes,
        updatePity,
        updateEquippedItem,
        updateUserAura,
        RegisterStatus(..),
        LoginStatus(..),
        ItemType(..)
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
import Config.Database (runDB)
import Config.GameConfig (userBaseAura, userTotalAura, userBonusAura)
import Model.Skill (textToRarity)
import Model.Clothe (getClothesByIds, Clothe(..))
--Xóa 2 cái import Clothe với Skill tại thấy nó vô dụn quá

data User = User
  { user_id       :: Text
  , username      :: Text
  , password      :: Text
  , tickets       :: Int
  , equipped_s1            :: Text
  , equipped_s2            :: Text
  , equipped_s3            :: Text
  , equipped_ult           :: Text
  , equipped_acc            :: Text
  , equipped_shirt         :: Text
  , equipped_shoes         :: Text
  , owned_clothes :: [Text]
  , owned_skills  :: [Text]
  , pity_skill_leg        :: Int
  , pity_clothe_leg       :: Int
  , base_aura             :: Int
  , bonus_aura            :: Int
  , total_aura            :: Int
  } deriving (Show, Generic)

instance ToJSON User

getUsers :: IO [User]
getUsers = runDB $ do
    docs <- find ((select [] "user") {project = ["password" =: (0 :: Int)]}) >>= rest
    return (map docToUser docs)

getUser :: Text -> IO (Maybe User)
getUser uname = runDB $ do
    user <- findOne ((select ["username" =: uname] "user") {project = ["password" =: (0 :: Int)]}) --Ẩn password khi lấy user
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
  , equipped_s1            = fromMaybe "" (doc !? "equipped_s1")
  , equipped_s2            = fromMaybe "" (doc !? "equipped_s2")
  , equipped_s3            = fromMaybe "" (doc !? "equipped_s3")
  , equipped_ult           = fromMaybe "" (doc !? "equipped_ult")
  , equipped_acc     = fromMaybe "" (doc !? "equipped_acc")
  , equipped_shirt         = fromMaybe "" (doc !? "equipped_shirt")
  , equipped_shoes         = fromMaybe "" (doc !? "equipped_shoes")
  , owned_clothes = fromMaybe [] (doc !? "owned_clothes")
  , owned_skills  = fromMaybe [] (doc !? "owned_skills")
  , pity_skill_leg        = fromMaybe 0 (doc !? "pity_skill_leg")
  , pity_clothe_leg       = fromMaybe 0 (doc !? "pity_clothe_leg")
  , base_aura             = fromMaybe 0 (doc !? "base_aura")
  , bonus_aura            = fromMaybe 0 (doc !? "bonus_aura")
  , total_aura             = fromMaybe 0 (doc !? "total_aura")
  }

userToDoc :: User -> Document
userToDoc u =
  [ "user_id"       =: user_id u
  , "username"      =: username u
  , "password"      =: password u
  , "tickets"       =: tickets u
  , "equipped_s1"            =: equipped_s1 u
  , "equipped_s2"            =: equipped_s2 u
  , "equipped_s3"            =: equipped_s3 u
  , "equipped_ult"           =: equipped_ult u
  , "equipped_acc"     =: equipped_acc u
  , "equipped_shirt"         =: equipped_shirt u
  , "equipped_shoes"         =: equipped_shoes u
  , "owned_clothes" =: owned_clothes u
  , "owned_skills"  =: owned_skills u
  , "pity_skill_leg"        =: pity_skill_leg u
  , "pity_clothe_leg"       =: pity_clothe_leg u
  , "base_aura"             =: base_aura u
  , "bonus_aura"            =: bonus_aura u 
  , "total_aura"            =: total_aura u
  ]

data RegisterStatus = Success Text | UserAlreadyExists deriving (Show, Eq)
data LoginStatus = LoginSuccess Text | LoginFailed deriving (Show, Eq)

createUser :: Text -> Text -> IO Text
createUser uname pass = do
    hashedPass <- hashPassword (mkPassword pass)
    userID <- liftIO nextRandom
    let generatedUserID = pack (toString userID)
        defAcc = "acc_1"
        defShirt = "shirt_1"
        defShoes = "shoes_1"
        calculatedBonus = userBonusAura userBaseAura (textToRarity defAcc) (textToRarity defShirt) (textToRarity defShoes)
        calculatedTotal = userTotalAura userBaseAura (textToRarity defAcc) (textToRarity defShirt) (textToRarity defShoes)
    let newUser = User
          { user_id          = generatedUserID
          , username         = uname
          , password         = unPasswordHash hashedPass
          , tickets          = 0
          , equipped_s1      = "s1_1"
          , equipped_s2      = "s2_1"
          , equipped_s3      = "s3_1"
          , equipped_ult     = "ult_1"
          , equipped_acc     = defAcc
          , equipped_shirt   = defShirt
          , equipped_shoes   = defShoes
          , owned_clothes    = ["shoes_1", "shirt_1", "acc_1"]
          , owned_skills     = ["ult_1", "s2_1", "s1_1", "s3_1"]
          , pity_skill_leg   = 0
          , pity_clothe_leg  = 0
          , base_aura        = userBaseAura 
          , bonus_aura       = calculatedBonus
          , total_aura       = calculatedTotal 
          }
    runDB $ insert_ "user" (userToDoc newUser)
    return generatedUserID

registerUser :: Text -> Text -> IO RegisterStatus
registerUser uname pass = do
    existingDocs <- runDB $ find (select ["username" =: uname] "user") >>= rest
    if not (null existingDocs)
        then return UserAlreadyExists
        else do
            generatedUserID <- createUser uname pass
            return (Success generatedUserID)

loginUser :: Text -> Text -> IO LoginStatus
loginUser uname pass = do
    existingDocs <- runDB $ find ((select ["username" =: uname] "user") {project = ["user_id" =: (1 :: Int), "password" =: (1 :: Int)]}) >>= rest   --Làm biến giải thích quá, nếu bạn có trình bạn sẽ tự hiểu ha
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

deductTickets :: Text -> Int -> IO (Maybe Int)
deductTickets uid amount = runDB $ do
    mDoc <- findOne ((select ["user_id" =: uid] "user") {project = ["tickets" =: (1 :: Int)]}) --Tìm user qua user_id
    case mDoc of
        Nothing -> return Nothing   --Nếu k có user nào
        Just doc -> do
            let currentTickets = fromMaybe 0 (doc !? "tickets")  --Lấy tickets và tính
            if currentTickets >= amount
                then do
                    let remaining = currentTickets - amount
                    modify (select ["user_id" =: uid] "user")
                           ["$inc" =: ["tickets" =: (-amount)]]
                    return (Just remaining)
                else return Nothing

updatePity :: Text -> Text -> Int -> IO ()
updatePity uid pityField newPity = runDB $ do
    modify (select ["user_id" =: uid] "user")
           ["$set" =: [pityField =: newPity]]

data ItemType = ClotheType | SkillType deriving (Show, Eq)

--Tối ưu hàm cho nó ngắn vầy chạy cho lẹ
addGachaItems :: Text -> ItemType -> [Text] -> IO ()
addGachaItems uid itemType newIDs = do
    case itemType of
      ClotheType -> do
        runDB $ modify (select ["user_id" =: uid] "user")
                        ["$addToSet" =: ["owned_clothes" =: ["$each" =: newIDs]]] --addToSet đã xử lý việc trùng lấp rồi ko cần phải viết hàm thêm, còn each là để xử lý việc thêm nhiều item
      SkillType -> do
        runDB $ modify (select ["user_id" =: uid] "user")
                        ["$addToSet" =: ["owned_skills" =: ["$each" =: newIDs]]]

mapEquippedSkills :: Text -> Text -> Text -> Text -> [Text]
mapEquippedSkills na s1 s2 ult = [na, s1, s2, ult]

mapEquippedClothes :: Text -> Text -> Text -> [Text]
mapEquippedClothes acc shirt shoes = [acc, shirt, shoes]

updateEquippedItem :: Text -> Text -> Text -> IO ()
updateEquippedItem uid dbField itemId = runDB $ do
    modify (select ["user_id" =: uid] "user")
           ["$set" =: [dbField =: itemId]]

updateUserAura :: Text -> IO()
updateUserAura uid = do
    mUser <- getUserById uid
    case mUser of
        Nothing -> return ()
        Just u -> do
            let accId   = equipped_acc u
                shirtId = equipped_shirt u
                shoesId = equipped_shoes u
            clothes <- getClothesByIds [accId, shirtId, shoesId]
            let bonus = sum (map aura_bonus clothes)
                total = base_aura u + bonus
            runDB $ modify (select ["user_id" =: uid] "user")
                           ["$set" =: ["bonus_aura" =: bonus, "total_aura" =: total]]
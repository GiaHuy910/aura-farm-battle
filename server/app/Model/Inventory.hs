{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE OverloadedRecordDot #-}

module Model.Inventory
  ( addTickets
  , getOwned
  , transferItem
  ) where

import           Config.Database (runDB)
import           Data.Text (Text)
import           Database.MongoDB
import           Game.Config (ItemKind (..), itemKind, slotOf)
import           Model.Clothe (Clothe (..), getClothesByIds)
import           Model.User (ItemType (..), User (..), addGachaItems, getUserById)

addTickets :: Text -> Int -> IO ()
addTickets uid n = runDB $
  modify (select ["user_id" =: uid] "user") ["$inc" =: ["tickets" =: n]]

getOwned :: Text -> IO ([Text], [Text])
getOwned uid = do
  mu <- getUserById uid
  pure $ case mu of
    Nothing -> ([], [])
    Just u  -> (u.owned_skills, u.owned_clothes)

transferItem :: Text -> Text -> Text -> IO (Maybe Text)
transferItem winner loser item = case (itemKind item, slotOf item) of
  (Just kind, Just (field, def)) -> do
    addGachaItems winner (toItemType kind) [item]
    runDB $ modify (select ["user_id" =: loser] "user")
                   ["$pull" =: [ownedField kind =: item]]
    worn <- wornItem loser field
    let replaced = worn == Just item
    if replaced
      then runDB $ modify (select ["user_id" =: loser, field =: item] "user")
                          ["$set" =: [field =: def]]
      else pure ()
    case kind of
      KindClothe -> recomputeAura loser
      KindSkill  -> pure ()
    pure (if replaced then Just def else Nothing)
  _ -> pure Nothing
  where
    toItemType KindSkill  = SkillType
    toItemType KindClothe = ClotheType
    ownedField KindSkill  = "owned_skills"
    ownedField KindClothe = "owned_clothes"

wornItem :: Text -> Text -> IO (Maybe Text)
wornItem uid field = runDB $ do
  md <- findOne ((select ["user_id" =: uid] "user") { project = [field =: (1 :: Int)] })
  pure (md >>= (!? field))

recomputeAura :: Text -> IO ()
recomputeAura uid = do
  mu <- getUserById uid
  case mu of
    Nothing -> pure ()
    Just u  -> do
      clothes <- getClothesByIds [u.equipped_acc, u.equipped_shirt, u.equipped_shoes]
      let bonus = sum (map (\c -> c.aura_bonus) clothes)
      runDB $ modify (select ["user_id" =: uid] "user")
                     ["$set" =: [ "bonus_aura" =: bonus
                                , "total_aura" =: (u.base_aura + bonus) ]]
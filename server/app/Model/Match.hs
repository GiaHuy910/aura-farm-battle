{-# LANGUAGE OverloadedStrings #-}

module Model.Match
  ( Match (..)
  , newMatchId
  , insertMatch
  , getMatch
  , setOffer
  , setPick
  , fillPicks
  , claimSettling
  , claimTickets
  , markSettled
  , listUnsettled
  ) where

import           Config.Database (runDB)
import           Control.Monad.IO.Class (liftIO)
import           Data.Maybe (fromMaybe, mapMaybe)
import           Data.Text (Text, pack)
import           Data.Time (UTCTime)
import           Data.UUID (toString)
import           Data.UUID.V4 (nextRandom)
import           Database.MongoDB

data Match = Match
  { mId             :: Text
  , mRoom           :: Text
  , mPlayers        :: [Text]
  , mWinner         :: Maybe Text   
  , mLoser          :: Maybe Text
  , mReason         :: Text           
  , mAuras          :: [(Text, Int)]     
  , mStatus         :: Text              
  , mOfferSkills    :: [Text]
  , mOfferClothes   :: [Text]
  , mDeadline       :: Maybe UTCTime
  , mPickedSkill    :: Maybe Text
  , mPickedClothe   :: Maybe Text
  , mTicketsGranted :: Bool
  , mCreatedAt      :: UTCTime
  } deriving (Show)

newMatchId :: IO Text
newMatchId = pack . toString <$> liftIO nextRandom

matchToDoc :: Match -> Document
matchToDoc m =
  [ "match_id"        =: mId m
  , "room_id"         =: mRoom m
  , "players"         =: mPlayers m
  , "winner_id"       =: mWinner m
  , "loser_id"        =: mLoser m
  , "end_reason"      =: mReason m
  , "final_aura"      =: [ ["user_id" =: u, "aura" =: a] | (u, a) <- mAuras m ]
  , "reward_status"   =: mStatus m
  , "offer_skills"    =: mOfferSkills m
  , "offer_clothes"   =: mOfferClothes m
  , "deadline"        =: mDeadline m
  , "picked_skill"    =: mPickedSkill m
  , "picked_clothe"   =: mPickedClothe m
  , "tickets_granted" =: mTicketsGranted m
  , "created_at"      =: mCreatedAt m
  ]

docToMatch :: Document -> Match
docToMatch d = Match
  { mId             = fromMaybe "" (d !? "match_id")
  , mRoom           = fromMaybe "" (d !? "room_id")
  , mPlayers        = fromMaybe [] (d !? "players")
  , mWinner         = d !? "winner_id"
  , mLoser          = d !? "loser_id"
  , mReason         = fromMaybe "completed" (d !? "end_reason")
  , mAuras          = mapMaybe auraOf (fromMaybe [] (d !? "final_aura"))
  , mStatus         = fromMaybe "none" (d !? "reward_status")
  , mOfferSkills    = fromMaybe [] (d !? "offer_skills")
  , mOfferClothes   = fromMaybe [] (d !? "offer_clothes")
  , mDeadline       = d !? "deadline"
  , mPickedSkill    = d !? "picked_skill"
  , mPickedClothe   = d !? "picked_clothe"
  , mTicketsGranted = fromMaybe False (d !? "tickets_granted")
  , mCreatedAt      = fromMaybe (read "1970-01-01 00:00:00 UTC") (d !? "created_at")
  }
  where
    auraOf sub = (,) <$> sub !? "user_id" <*> sub !? "aura"

insertMatch :: Match -> IO ()
insertMatch m = runDB $ insert_ "matches" (matchToDoc m)

getMatch :: Text -> IO (Maybe Match)
getMatch mid = runDB $ fmap docToMatch <$> findOne (select ["match_id" =: mid] "matches")

setOffer :: Text -> [Text] -> [Text] -> UTCTime -> IO ()
setOffer mid skills clothes deadline = runDB $
  modify (select ["match_id" =: mid] "matches")
    [ "$set" =:
        [ "reward_status" =: ("pending" :: Text)
        , "offer_skills"  =: skills
        , "offer_clothes" =: clothes
        , "deadline"      =: deadline
        ]
    ]

setPick :: Text -> Text -> Maybe Text -> IO Bool
setPick mid field mItem = runDB $ do
  r <- findAndModify
         (select [ "match_id" =: mid
                 , "reward_status" =: ("pending" :: Text) ] "matches")
         [ "$set" =: [ field =: mItem ] ]
  pure (either (const False) (const True) r)

fillPicks :: Text -> Maybe Text -> Maybe Text -> IO ()
fillPicks mid mSkill mClothe = runDB $ do
  case mSkill of
    Nothing -> pure ()
    Just s  -> modify (select ["match_id" =: mid, "picked_skill" =: (Null :: Value)] "matches")
                      ["$set" =: ["picked_skill" =: s]]
  case mClothe of
    Nothing -> pure ()
    Just c  -> modify (select ["match_id" =: mid, "picked_clothe" =: (Null :: Value)] "matches")
                      ["$set" =: ["picked_clothe" =: c]]

claimSettling :: Text -> Bool -> IO (Maybe Match)
claimSettling mid allowResume = runDB $ do
  let statuses = if allowResume then ["pending", "settling"] else ["pending"] :: [Text]
  r <- findAndModify
         (select [ "match_id" =: mid
                 , "reward_status" =: [ "$in" =: statuses ] ] "matches")
         [ "$set" =: [ "reward_status" =: ("settling" :: Text) ] ]
  pure (either (const Nothing) (Just . docToMatch) r)

claimTickets :: Text -> IO Bool
claimTickets mid = runDB $ do
  r <- findAndModify
         (select ["match_id" =: mid, "tickets_granted" =: False] "matches")
         [ "$set" =: [ "tickets_granted" =: True ] ]
  pure (either (const False) (const True) r)

markSettled :: Text -> IO ()
markSettled mid = runDB $
  modify (select ["match_id" =: mid] "matches")
    ["$set" =: ["reward_status" =: ("settled" :: Text)]]

listUnsettled :: IO [Match]
listUnsettled = runDB $ do
  docs <- find (select ["reward_status" =: ["$in" =: (["pending", "settling"] :: [Text])]] "matches") >>= rest
  pure (map docToMatch docs)
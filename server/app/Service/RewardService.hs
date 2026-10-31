{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE OverloadedRecordDot #-}

module Service.RewardService
  ( startReward
  , pickReward
  , unpickReward
  , confirmReward
  , recoverRewards
  ) where

import           Control.Applicative ((<|>))
import           Control.Concurrent (forkIO, threadDelay)
import           Control.Monad (forM, forM_, void, when)
import           Data.Aeson (Value, object, toJSON, (.=))
import qualified Data.Map.Strict as M
import           Data.Maybe (catMaybes, isJust, isNothing)
import           Data.Text (Text)
import qualified Data.Text as T
import           Data.Time (addUTCTime, getCurrentTime)
import           Game.Config
import           Game.Random (pickUniform)
import           Game.Registry
import           Game.Strategy (pickOffer)
import           Game.View (withField)
import           Model.Clothe (getClothesByIds)
import qualified Model.Clothe as C
import           Model.Inventory
import           Model.Match
import qualified Model.Skill as S
import           Model.User (User (..), getUserById)
import           Service.RematchService (enterEnded)
import           System.Random (newStdGen, split)
import           Ws.Env
import qualified Ws.Hub as Hub
import           Ws.Message
import           Ws.Types

startReward :: Env -> RoomId -> Text -> UserId -> UserId -> IO ()
startReward env rid mid winner loser = do
  (loserSkills, loserClothes)   <- getOwned loser
  (winnerSkills, winnerClothes) <- getOwned winner
  let okSkill  s = not (isDefaultItem s) && s `notElem` winnerSkills
      okClothe c = not (isDefaultItem c) && c `notElem` winnerClothes
  skills  <- S.getSkillsByIds (filter okSkill loserSkills)
  clothes <- getClothesByIds  (filter okClothe loserClothes)
  g0 <- newStdGen
  let (g1, g2) = split g0
      (pickedS, _) = pickOffer g1 offerSkillCount  [(s.skill_id, s.rarity) | s <- skills]
      (pickedC, _) = pickOffer g2 offerClotheCount [(c.clothe_id, c.rarity) | c <- clothes]
  now <- getCurrentTime
  let deadline = addUTCTime (fromIntegral rewardSecs) now
  setOffer mid pickedS pickedC deadline
  infoS <- describeItems pickedS
  infoC <- describeItems pickedC
  let payload = object
        [ "matchId"  .= mid
        , "winnerId" .= winner
        , "loserId"  .= loser
        , "tickets"  .= ticketReward
        , "seconds"  .= rewardSecs
        , "skills"   .= map snd infoS
        , "clothes"  .= map snd infoC
        ]
  updateGame (envRegistry env) rid (\g -> g { rgOffer = Just (payload, deadline) })
  Hub.broadcast (envHub env) rid
    (msg "reward.offer" (withField "timeLeftMs" (toJSON (rewardSecs * 1000)) payload))
  _ <- forkIO $ do
    threadDelay (rewardSecs * 1000000)
    settle env mid False
  when (null pickedS && null pickedC) (settle env mid False)

pickReward :: Env -> RoomId -> UserId -> Text -> IO ()
pickReward env rid uid item = withReward env rid uid $ \mid m ->
  case fieldFor item m of
    Nothing -> sendErr env rid uid "not_in_offer"
    Just (field, kind) -> do
      ok <- setPick mid field (Just item)
      if ok then announce env rid kind True else sendErr env rid uid "too_late"

unpickReward :: Env -> RoomId -> UserId -> Text -> IO ()
unpickReward env rid uid item = withReward env rid uid $ \mid m ->
  case fieldFor item m of
    Nothing -> sendErr env rid uid "not_in_offer"
    Just (field, kind) -> do
      ok <- setPick mid field Nothing
      if ok then announce env rid kind False else sendErr env rid uid "too_late"

confirmReward :: Env -> RoomId -> UserId -> IO ()
confirmReward env rid uid = withReward env rid uid $ \mid m ->
  if complete m then settle env mid False else sendErr env rid uid "incomplete"
  where
    complete m = (null (mOfferSkills m)  || isJust (mPickedSkill m))
              && (null (mOfferClothes m) || isJust (mPickedClothe m))

withReward :: Env -> RoomId -> UserId -> (Text -> Match -> IO ()) -> IO ()
withReward env rid uid act = do
  mg <- getGame (envRegistry env) rid
  case mg of
    Just rg | rgPhase rg == PhaseReward
            , rgWinner rg == Just uid
            , Just mid <- rgMatchId rg -> do
      mm <- getMatch mid
      case mm of
        Just m | mStatus m == "pending" -> act mid m
        _ -> sendErr env rid uid "too_late"
    _ -> sendErr env rid uid "no_reward"

fieldFor :: Text -> Match -> Maybe (Text, Text)
fieldFor item m
  | item `elem` mOfferSkills m  = Just ("picked_skill", "skill")
  | item `elem` mOfferClothes m = Just ("picked_clothe", "clothe")
  | otherwise                   = Nothing

announce :: Env -> RoomId -> Text -> Bool -> IO ()
announce env rid kind picked =
  Hub.broadcast (envHub env) rid (msg "reward.picked" (object ["kind" .= kind, "picked" .= picked]))

sendErr :: Env -> RoomId -> UserId -> Text -> IO ()
sendErr env rid uid code =
  Hub.sendToUser (envHub env) rid uid (msg "game.error" (object ["code" .= code]))

settle :: Env -> Text -> Bool -> IO ()
settle env mid resume = do
  claimed <- claimSettling mid resume
  case claimed of
    Nothing -> pure ()                     
    Just m  -> do
      g <- newStdGen
      let (gs, gc) = split g
          autoS = if isNothing (mPickedSkill m)  then fst <$> pickUniform gs (mOfferSkills m)  else Nothing
          autoC = if isNothing (mPickedClothe m) then fst <$> pickUniform gc (mOfferClothes m) else Nothing
      fillPicks mid autoS autoC
      let finalS = mPickedSkill m  <|> autoS
          finalC = mPickedClothe m <|> autoC
          auto   = isJust autoS || isJust autoC
      case (mWinner m, mLoser m) of
        (Just w, Just l) -> do
          granted <- claimTickets mid
          when granted (addTickets w ticketReward)
          (ownS, ownC) <- getOwned l
          let items = [i | i <- catMaybes [finalS, finalC], i `elem` ownS || i `elem` ownC]
          moved <- forM items $ \i -> do
            replaced <- transferItem w l i
            pure (i, replaced)
          markSettled mid
          info <- describeItems (map fst moved)
          loserAura <- maybe 0 (\u -> u.total_aura) <$> getUserById l
          let infoMap = M.fromList info
              taken = [ object [ "item"         .= M.lookup i infoMap
                               , "replacedWith" .= repl ]
                      | (i, repl) <- moved ]
              payload = object
                [ "matchId"   .= mid
                , "winnerId"  .= w
                , "loserId"   .= l
                , "tickets"   .= ticketReward
                , "auto"      .= auto
                , "taken"     .= taken
                , "loserAura" .= loserAura
                ]
          updateGame (envRegistry env) (mRoom m) (\gm -> gm { rgResult = Just payload })
          Hub.broadcast (envHub env) (mRoom m) (msg "reward.result" payload)
        _ -> markSettled mid            
      enterEnded env (mRoom m)

recoverRewards :: Env -> IO ()
recoverRewards env = do
  ms <- listUnsettled
  forM_ ms $ \m -> void (forkIO (settle env (mId m) True))
  when (not (null ms)) $
    putStrLn ("Recovered " ++ show (length ms) ++ " unsettled reward(s).")

describeItems :: [Text] -> IO [(Text, Value)]
describeItems ids = do
  let skillIds  = filter ((== Just KindSkill)  . itemKind) ids
      clotheIds = filter ((== Just KindClothe) . itemKind) ids
  skills  <- if null skillIds  then pure [] else S.getSkillsByIds skillIds
  clothes <- if null clotheIds then pure [] else getClothesByIds clotheIds
  let sMap = M.fromList [ (s.skill_id, skillJson s) | s <- skills ]
      cMap = M.fromList [ (c.clothe_id, clotheJson c) | c <- clothes ]
  pure [ (i, v) | i <- ids, Just v <- [M.lookup i sMap <|> M.lookup i cMap] ]

skillJson :: S.Skill -> Value
skillJson s = object
  [ "id"     .= s.skill_id
  , "kind"   .= ("skill" :: Text)
  , "name"   .= s.skill_name
  , "rarity" .= s.rarity
  , "isUlt"  .= ("ult_" `T.isPrefixOf` s.skill_id)
  , "effect" .= s.effect.effect_type
  ]

clotheJson :: C.Clothe -> Value
clotheJson c = object
  [ "id"        .= c.clothe_id
  , "kind"      .= ("clothe" :: Text)
  , "name"      .= c.clothe_name
  , "rarity"    .= c.rarity
  , "slot"      .= slotName c.clothe_id
  , "auraBonus" .= c.aura_bonus
  ]
  where
    slotName i | "acc_"   `T.isPrefixOf` i = "acc" :: Text
               | "shirt_" `T.isPrefixOf` i = "shirt"
               | otherwise                 = "shoes"
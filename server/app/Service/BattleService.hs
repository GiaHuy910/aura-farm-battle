{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE OverloadedRecordDot #-}

module Service.BattleService
  ( startBattle
  , submitChoice
  , forfeitMatch
  ) where

import           Control.Concurrent (forkIO, threadDelay)
import           Control.Monad (forM_, join, void, when)
import           Data.Aeson (object, (.=))
import           Data.List (find, nub)
import qualified Data.Map.Strict as M
import           Data.Text (Text)
import qualified Data.Text as T
import           Data.Time (addUTCTime, getCurrentTime)
import           Game.Config
import           Game.Registry
import           Game.Rules
import           Game.Strategy (decideOrder)
import           Game.Types
import           Game.View
import           Model.Match
import qualified Model.Skill as S
import           Model.User (User (..), getUserById)
import           Service.RematchService (enterEnded)
import           Service.RewardService (startReward)
import           System.Random (newStdGen)
import           Ws.Env
import qualified Ws.Hub as Hub
import           Ws.Message
import           Ws.Types

startBattle :: Env -> RoomId -> UserId -> UserId -> IO ()
startBattle env rid owner guest = do
  mo <- getUserById owner
  mg <- getUserById guest
  case (mo, mg) of
    (Just uo, Just ug) -> do
      skills <- S.getSkillsByIds (nub (uo.owned_skills ++ ug.owned_skills))
      let owners :: S.Skill -> [UserId]
          owners s = [u.user_id | u <- [uo, ug], s.skill_id `elem` u.owned_skills]
          pool = [toCard (owners s) s | s <- skills]
      g <- newStdGen
      let (order, _) = decideOrder g [owner, guest]
          battle0 = newBattle order pool [(owner, uo.total_aura), (guest, ug.total_aura)]
      putGame (envRegistry env) rid RoomGame
        { rgPhase = PhaseBattle, rgBattle = battle0, rgOpen = False
        , rgMatchId = Nothing, rgWinner = Nothing, rgLoser = Nothing
        , rgFinished = Nothing, rgOffer = Nothing, rgResult = Nothing, rgAgain = [] }
      rsSetStatus (envStore env) rid Playing
      Hub.broadcast (envHub env) rid (msg "game.start" (startPayload battle0))
      beginNextRound env rid
    _ -> putStrLn ("startBattle: không đọc được người chơi của phòng " ++ T.unpack rid)

toCard :: [UserId] -> S.Skill -> Card
toCard owners s = Card
  { cardId        = s.skill_id
  , cardIsUlt     = "ult_" `T.isPrefixOf` s.skill_id
  , cardName      = s.skill_name
  , cardRarity    = s.rarity
  , cardMult      = s.aura_multiplier
  , cardConsume   = s.energy_consumption
  , cardRecover   = s.energy_recovery
  , cardEffect    = s.effect.effect_type
  , cardEffectDur = s.effect.effect_duration
  , cardOwners    = owners
  }

beginNextRound :: Env -> RoomId -> IO ()
beginNextRound env rid = do
  now <- getCurrentTime
  g   <- newStdGen
  let deadline = addUTCTime (fromIntegral roundSecs) now
  r <- modifyGame (envRegistry env) rid $ \rg ->
    if rgPhase rg /= PhaseBattle || rgOpen rg
      then (rg, Nothing)
      else
        let (b1, _) = beginRound g (rgBattle rg)
            b2      = b1 { bDeadline = Just deadline }
        in (rg { rgBattle = b2, rgOpen = True }, Just b2)
  forM_ (join r) $ \b -> do
    forM_ (bOrder b) $ \u ->
      Hub.sendToUser (envHub env) rid u
        (msg "game.round" (battleViewFor u b (Just (roundSecs * 1000))))
    let n = bRound b
    _ <- forkIO $ do
      threadDelay (roundSecs * 1000000)
      resolveCurrentRound env rid n
    when (allChosen b) (resolveCurrentRound env rid n)

submitChoice :: Env -> RoomId -> UserId -> Int -> IO ()
submitChoice env rid uid idx = do
  r <- modifyGame (envRegistry env) rid $ \rg ->
    if rgPhase rg /= PhaseBattle || not (rgOpen rg)
      then (rg, Left "not_open")
      else case chooseCard uid idx (rgBattle rg) of
        Left e   -> (rg, Left e)
        Right b' -> (rg { rgBattle = b' }, Right (allChosen b', bRound b'))
  case r of
    Nothing           -> sendError env rid uid "no_game"
    Just (Left code)  -> sendError env rid uid code
    Just (Right (done, n)) -> do
      Hub.broadcast (envHub env) rid (msg "game.chosen" (object ["userId" .= uid]))
      when done (resolveCurrentRound env rid n)

sendError :: Env -> RoomId -> UserId -> Text -> IO ()
sendError env rid uid code =
  Hub.sendToUser (envHub env) rid uid (msg "game.error" (object ["code" .= code]))

resolveCurrentRound :: Env -> RoomId -> Int -> IO ()
resolveCurrentRound env rid n = do
  g <- newStdGen
  r <- modifyGame (envRegistry env) rid $ \rg ->
    if rgPhase rg == PhaseBattle && rgOpen rg && bRound (rgBattle rg) == n
      then let (b', evs, _) = resolveRound g (rgBattle rg)
           in (rg { rgBattle = b', rgOpen = False }, Just (b', evs))
      else (rg, Nothing)
  forM_ (join r) $ \(b, evs) -> do
    Hub.broadcast (envHub env) rid (msg "game.round_result" (roundResultPayload b evs))
    if bRound b >= bMaxRounds b
      then finishBattle env rid "completed" (winnerOf b)
      else void $ forkIO $ do
        threadDelay (interRoundSecs * 1000000)  
        beginNextRound env rid

finishBattle :: Env -> RoomId -> Text -> Maybe UserId -> IO ()
finishBattle env rid reason winner = do
  claimed <- modifyGame (envRegistry env) rid $ \rg ->
    if rgPhase rg == PhaseBattle
      then (rg { rgPhase = PhaseReward, rgOpen = False }, Just (rgBattle rg))
      else (rg, Nothing)
  forM_ (join claimed) $ \b -> do
    let players = bOrder b
        loser   = winner >>= \w -> find (/= w) players
    mid <- newMatchId
    now <- getCurrentTime
    insertMatch Match
      { mId = mid, mRoom = rid, mPlayers = players
      , mWinner = winner, mLoser = loser, mReason = reason
      , mAuras = [(u, fAura f) | (u, f) <- M.toList (bFighters b)]
      , mStatus = "none", mOfferSkills = [], mOfferClothes = [], mDeadline = Nothing
      , mPickedSkill = Nothing, mPickedClothe = Nothing, mTicketsGranted = False
      , mCreatedAt = now }
    rsSetStatus (envStore env) rid Finished
    let payload = object
          [ "winnerId" .= winner
          , "loserId"  .= loser
          , "reason"   .= reason
          , "players"  .= map fighterPublic (M.elems (bFighters b))
          ]
    updateGame (envRegistry env) rid $ \rg ->
      rg { rgMatchId = Just mid, rgWinner = winner, rgLoser = loser, rgFinished = Just payload }
    Hub.broadcast (envHub env) rid (msg "game.finished" payload)
    case (winner, loser) of
      (Just w, Just l) -> startReward env rid mid w l
      _                -> enterEnded env rid      

forfeitMatch :: Env -> RoomInfo -> UserId -> IO ()
forfeitMatch env room loser = do
  mg <- getGame (envRegistry env) (riId room)
  forM_ mg $ \rg ->
    when (rgPhase rg == PhaseBattle) $ do
      let winner = find (/= loser) (bOrder (rgBattle rg))
      finishBattle env (riId room) "forfeit" winner
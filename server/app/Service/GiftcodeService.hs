{-# LANGUAGE OverloadedStrings #-}

module Service.GiftcodeService
  ( RedeemResult (..)
  , redeem
  ) where

import           Control.Concurrent.STM
import           Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import           Data.Text (Text)
import qualified Data.Text as T
import           Data.Time (UTCTime, diffUTCTime, getCurrentTime)
import           System.IO.Unsafe (unsafePerformIO)

import           Model.Giftcode
import           Model.Inventory (addTickets)
import           Model.User (ItemType (..), addGachaItems)
import           Ws.Types (UserId)

data RedeemResult
  = Redeemed GiftcodeRewards
  | NotFound
  | Expired
  | UsedUp
  | AlreadyRedeemed
  | RateLimited
  deriving (Eq, Show)

type AttemptWindow = (UTCTime, Int)

{-# NOINLINE attempts #-}
attempts :: TVar (Map UserId AttemptWindow)
attempts = unsafePerformIO (newTVarIO Map.empty)

redeem :: UserId -> Text -> IO RedeemResult
redeem uid rawCode = do
  allowed <- allowAttempt uid
  if not allowed
    then pure RateLimited
    else do
      let code = normalizeGiftcodeCode rawCode
      if T.null code
        then pure NotFound
        else do
          maybeGiftcode <- findGiftcode code
          case maybeGiftcode of
            Nothing -> pure NotFound
            Just giftcode
              | not (giftcodeActive giftcode) -> pure NotFound
              | otherwise -> redeemFound uid giftcode

redeemFound :: UserId -> Giftcode -> IO RedeemResult
redeemFound uid giftcode = do
  now <- getCurrentTime
  case giftcodeExpiresAt giftcode of
    Just expiry | expiry <= now -> pure Expired
    _ -> do
      let code = giftcodeCode giftcode
      inserted <- insertRedemption code uid
      if not inserted
        then pure AlreadyRedeemed
        else do
          claimed <- claimSlot giftcode
          if not claimed
            then do
              deleteRedemption code uid
              maybeCurrent <- findGiftcode code
              case maybeCurrent of
                Just current
                  | not (giftcodeActive current) -> pure NotFound
                  | otherwise -> do
                      checkedAt <- getCurrentTime
                      case giftcodeExpiresAt current of
                        Just expiry | expiry <= checkedAt -> pure Expired
                        _ -> pure UsedUp
                Nothing -> pure NotFound
            else do
              let rewards = giftcodeRewards giftcode
              if rewardTickets rewards > 0
                then addTickets uid (rewardTickets rewards)
                else pure ()
              addItems uid SkillType (rewardSkills rewards)
              addItems uid ClotheType (rewardClothes rewards)
              pure (Redeemed rewards)

allowAttempt :: UserId -> IO Bool
allowAttempt uid = do
  now <- getCurrentTime
  atomically $ do
    current <- readTVar attempts
    let active = Map.filter (\(started, _) -> diffUTCTime now started < 600) current
        (allowed, updated) = case Map.lookup uid active of
          Nothing -> (True, Map.insert uid (now, 1) active)
          Just (started, count)
            | diffUTCTime now started >= 60 ->
                (True, Map.insert uid (now, 1) active)
            | count >= 5 -> (False, active)
            | otherwise -> (True, Map.insert uid (started, count + 1) active)
    writeTVar attempts updated
    pure allowed

addItems :: UserId -> ItemType -> [Text] -> IO ()
addItems _ _ [] = pure ()
addItems uid category ids = addGachaItems uid category ids

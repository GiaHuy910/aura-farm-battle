{-# LANGUAGE OverloadedStrings #-}

module Game.Types
  ( Card (..)
  , ActiveEffect (..)
  , Fighter (..)
  , Battle (..)
  , Event (..)
  , isDebuff
  ) where

import           Data.Map.Strict (Map)
import           Data.Text (Text)
import           Data.Time (UTCTime)
import           Ws.Types (UserId)

data Card = Card
  { cardId        :: Text
  , cardIsUlt     :: Bool
  , cardName      :: Text
  , cardRarity    :: Text
  , cardMult      :: Double  
  , cardConsume   :: Int    
  , cardRecover   :: Int    
  , cardEffect    :: Text    
  , cardEffectDur :: Int
  , cardOwners    :: [UserId]
  } deriving (Show, Eq)

data ActiveEffect = ActiveEffect
  { aeType   :: Text
  , aeLeft   :: Int    
  , aeFresh  :: Bool
  , aeSource :: UserId
  } deriving (Show, Eq)

data Fighter = Fighter
  { fUser    :: UserId
  , fAura    :: Int
  , fEnergy  :: Int
  , fEffects :: [ActiveEffect]
  , fHand    :: [Card]
  , fChoice  :: Maybe Int      
  } deriving (Show, Eq)

data Battle = Battle
  { bRound     :: Int               
  , bMaxRounds :: Int
  , bOrder     :: [UserId]            
  , bPool      :: [Card]
  , bFighters  :: Map UserId Fighter
  , bDeadline  :: Maybe UTCTime         
  } deriving (Show)

data Event
  = EvSkillUsed
      { evUser         :: UserId
      , evCard         :: Card
      , evMult         :: Double   
      , evAuraBefore   :: Int
      , evAuraAfter    :: Int
      , evEnergyBefore :: Int
      , evEnergyAfter  :: Int
      }
  | EvSkipped UserId Text           
  | EvAutoPicked UserId Int         
  | EvReplaced UserId Text Text      
  | EvEffectApplied UserId Text Int UserId  
  | EvEffectBlocked UserId Text Text   
  | EvEffectCleansed UserId Text       
  | EvEffectExpired UserId Text
  deriving (Show, Eq)

isDebuff :: Text -> Bool
isDebuff t = t `elem` ["freeze", "curse", "brainrotify"]
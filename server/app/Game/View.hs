{-# LANGUAGE OverloadedStrings #-}

module Game.View
  ( cardJson
  , fighterPublic
  , fighterSelf
  , eventJson
  , battleViewFor
  , startPayload
  , roundResultPayload
  , withField
  ) where

import           Data.Aeson (Value (..), object, toJSON, (.=))
import qualified Data.Aeson.Key as K
import qualified Data.Aeson.KeyMap as KM
import qualified Data.Map.Strict as M
import           Data.Maybe (isJust)
import           Data.Text (Text)
import           Game.Rules (canPlay, isFrozen)
import           Game.Types
import           Ws.Types (UserId)

withField :: Text -> Value -> Value -> Value
withField k v (Object o) = Object (KM.insert (K.fromText k) v o)
withField _ _ other      = other

cardJson :: Card -> Value
cardJson c = object
  [ "id"             .= cardId c
  , "isUlt"          .= cardIsUlt c
  , "name"           .= cardName c
  , "rarity"         .= cardRarity c
  , "mult"           .= cardMult c
  , "consume"        .= cardConsume c
  , "recover"        .= cardRecover c
  , "effect"         .= cardEffect c
  , "effectDuration" .= cardEffectDur c
  ]

effectsJson :: Fighter -> Value
effectsJson f = toJSON
  [ object ["type" .= aeType e, "left" .= aeLeft e, "source" .= aeSource e]
  | e <- fEffects f, aeLeft e > 0 ]

fighterPublic :: Fighter -> Value
fighterPublic f = object
  [ "id"      .= fUser f
  , "aura"    .= fAura f
  , "energy"  .= fEnergy f
  , "effects" .= effectsJson f
  , "chosen"  .= isJust (fChoice f)
  ]

fighterSelf :: Fighter -> Value
fighterSelf f = withField "hand" hand
              $ withField "choice" (toJSON (fChoice f))
              $ withField "frozen" (toJSON (isFrozen f))
              $ fighterPublic f
  where
    hand = toJSON [ withField "playable" (toJSON (canPlay f c)) (cardJson c) | c <- fHand f ]

battleViewFor :: UserId -> Battle -> Maybe Int -> Value
battleViewFor me b timeLeft = object
  [ "round"      .= bRound b
  , "maxRounds"  .= bMaxRounds b
  , "order"      .= bOrder b
  , "timeLeftMs" .= timeLeft
  , "you"        .= fmap fighterSelf (M.lookup me (bFighters b))
  , "opponent"   .= fmap fighterPublic (head' [f | (u, f) <- M.toList (bFighters b), u /= me])
  ]
  where
    head' (x : _) = Just x
    head' []      = Nothing

startPayload :: Battle -> Value
startPayload b = object
  [ "maxRounds" .= bMaxRounds b
  , "order"     .= bOrder b
  , "players"   .= map fighterPublic (M.elems (bFighters b))
  ]

roundResultPayload :: Battle -> [Event] -> Value
roundResultPayload b evs = object
  [ "round"   .= bRound b
  , "events"  .= map eventJson evs
  , "players" .= map fighterPublic (M.elems (bFighters b))
  ]

eventJson :: Event -> Value
eventJson ev = case ev of
  EvSkillUsed{} -> object
    [ "kind"         .= ("skill_used" :: Text)
    , "userId"       .= evUser ev
    , "skillId"      .= cardId (evCard ev)
    , "skill"        .= cardJson (evCard ev)
    , "effectType"   .= cardEffect (evCard ev)
    , "mult"         .= evMult ev
    , "auraBefore"   .= evAuraBefore ev
    , "auraAfter"    .= evAuraAfter ev
    , "energyBefore" .= evEnergyBefore ev
    , "energyAfter"  .= evEnergyAfter ev
    ]
  EvSkipped u why -> object ["kind" .= ("skipped" :: Text), "userId" .= u, "reason" .= why]
  EvAutoPicked u i -> object ["kind" .= ("auto_picked" :: Text), "userId" .= u, "index" .= i]
  EvReplaced u from to -> object
    ["kind" .= ("skill_replaced" :: Text), "userId" .= u, "from" .= from, "to" .= to]
  EvEffectApplied u t n src -> object
    ["kind" .= ("effect_applied" :: Text), "userId" .= u, "effectType" .= t, "rounds" .= n, "source" .= src]
  EvEffectBlocked u t by -> object
    ["kind" .= ("effect_blocked" :: Text), "userId" .= u, "effectType" .= t, "by" .= by]
  EvEffectCleansed u t -> object ["kind" .= ("effect_cleansed" :: Text), "userId" .= u, "effectType" .= t]
  EvEffectExpired u t  -> object ["kind" .= ("effect_expired" :: Text), "userId" .= u, "effectType" .= t]
{-# LANGUAGE OverloadedStrings #-}
module Game.Rules
  ( newFighter
  , newBattle
  , beginRound
  , chooseCard
  , allChosen
  , resolveRound
  , winnerOf
  , applyMult
  , canPlay
  , playableIndices
  , isFrozen
  , isActive
  , simulateMatch
  ) where

import           Data.List (foldl', sortOn)
import qualified Data.Map.Strict as M
import           Data.Maybe (fromMaybe, isJust)
import           Data.Text (Text)
import qualified Data.Text as T
import           Game.Config
import           Game.Random
import           Game.Strategy
import           Game.Types
import           System.Random (StdGen, mkStdGen)
import           Ws.Types (UserId)

newFighter :: UserId -> Int -> Fighter
newFighter uid aura = Fighter
  { fUser = uid, fAura = aura, fEnergy = 0, fEffects = [], fHand = [], fChoice = Nothing }

newBattle :: [UserId] -> [Card] -> [(UserId, Int)] -> Battle
newBattle order pool players = Battle
  { bRound     = 0
  , bMaxRounds = maxRounds
  , bOrder     = order
  , bPool      = pool
  , bFighters  = M.fromList [(u, newFighter u a) | (u, a) <- players]
  , bDeadline  = Nothing
  }

isPresent :: Text -> Fighter -> Bool
isPresent t f = any (\e -> aeType e == t && aeLeft e > 0) (fEffects f)

isActive :: Text -> Fighter -> Bool
isActive t f = any (\e -> aeType e == t && aeLeft e > 0 && not (aeFresh e)) (fEffects f)

isFrozen :: Fighter -> Bool
isFrozen = isActive "freeze"

applyMult :: Double -> Int -> Int
applyMult m a = min auraCap (1 + round (m * fromIntegral a) + a)

canPlay :: Fighter -> Card -> Bool
canPlay f c = not (cardIsUlt c) || fEnergy f >= cardConsume c

playableIndices :: Fighter -> [Int]
playableIndices f = [i | (i, c) <- zip [0 ..] (fHand f), canPlay f c]

effectiveMult :: Fighter -> Card -> Double
effectiveMult f c = cardMult c * boost * curse
  where
    boost = if isActive "boost" f then 1.5 else 1
    curse = if isActive "curse" f then 0.75 else 1

dealHand :: StdGen -> [Card] -> ([Card], StdGen)
dealHand g pool =
  let (hand, g1) = sampleWeighted g handSize [(c, cardWeight c) | c <- pool]
  in if any (not . cardIsUlt) hand
       then (hand, g1)
       else
         let normals = [c | c <- pool, not (cardIsUlt c), c `notElem` hand]
         in case pickUniform g1 normals of
              Nothing      -> (hand, g1)
              Just (n, g2) -> (take (handSize - 1) hand ++ [n], g2)

beginRound :: StdGen -> Battle -> (Battle, StdGen)
beginRound g0 b =
  let (fs, g') = foldl' step (bFighters b, g0) (bOrder b)
  in (b { bRound = bRound b + 1, bFighters = fs, bDeadline = Nothing }, g')
  where
    step (fs, g) u = case M.lookup u fs of
      Nothing -> (fs, g)
      Just f  ->
        let (hand, g1) = dealHand g (bPool b)
            f1 = f { fEnergy = min energyMax (fEnergy f + energyPerRound)
                   , fHand   = hand
                   , fChoice = Nothing }
            f2 = if isFrozen f1 then f1 { fChoice = Just (-1) } else f1
        in (M.insert u f2 fs, g1)

chooseCard :: UserId -> Int -> Battle -> Either Text Battle
chooseCard u idx b = do
  f <- maybe (Left "not_in_match") Right (M.lookup u (bFighters b))
  if isFrozen f            then Left "frozen"         else Right ()
  if isJust (fChoice f)    then Left "already_chosen" else Right ()
  if idx < 0 || idx >= length (fHand f) then Left "bad_index" else Right ()
  if not (canPlay f (fHand f !! idx)) then Left "not_enough_energy" else Right ()
  Right b { bFighters = M.insert u f { fChoice = Just idx } (bFighters b) }

allChosen :: Battle -> Bool
allChosen b = all (isJust . fChoice) (M.elems (bFighters b))

type Acc = (Battle, [Event], StdGen)

resolveRound :: StdGen -> Battle -> (Battle, [Event], StdGen)
resolveRound g0 b0 =
  let acc1 = autoFill (b0, [], g0)
      acc2 = foldl' act acc1 (bOrder b0)
      (b3, evs3, g3) = acc2
      (b4, evs4) = tickEffects b3
  in (b4 { bDeadline = Nothing }, evs3 ++ evs4, g3)

autoFill :: Acc -> Acc
autoFill acc0 = foldl' fill acc0 (bOrder (fst3 acc0))
  where
    fst3 (x, _, _) = x
    fill (b, evs, g) u = case M.lookup u (bFighters b) of
      Just f | fChoice f == Nothing ->
        case pickUniform g (playableIndices f) of
          Nothing      -> (b, evs, g)
          Just (i, g') ->
            ( b { bFighters = M.insert u f { fChoice = Just i } (bFighters b) }
            , evs ++ [EvAutoPicked u i], g' )
      _ -> (b, evs, g)

act :: Acc -> UserId -> Acc
act acc@(b, evs, g) u = case M.lookup u (bFighters b) of
  Nothing -> acc
  Just f
    | isFrozen f || fChoice f == Just (-1) || fChoice f == Nothing ->
        (b, evs ++ [EvSkipped u "freeze"], g)
    | otherwise ->
        let idx0  = fromMaybe 0 (fChoice f)
            card0 = fHand f !! idx0
            (card, replaced, g1)
              | isActive "brainrotify" f =
                  case pickUniform g (playableIndices f) of
                    Just (i, g') -> let c = fHand f !! i
                                    in (c, [EvReplaced u (cardId card0) (cardId c) | cardId c /= cardId card0], g')
                    Nothing      -> (card0, [], g)
              | otherwise = (card0, [], g)
            mult  = effectiveMult f card
            aura' = applyMult mult (fAura f)
            en'   | cardIsUlt card = fEnergy f - cardConsume card
                  | otherwise      = min energyMax (fEnergy f + cardRecover card)
            f'    = f { fAura = aura', fEnergy = en' }
            used  = EvSkillUsed
                      { evUser = u, evCard = card, evMult = mult
                      , evAuraBefore = fAura f, evAuraAfter = aura'
                      , evEnergyBefore = fEnergy f, evEnergyAfter = en' }
            b1    = b { bFighters = M.insert u f' (bFighters b) }
            (b2, effEvs) = registerEffect u card b1
        in (b2, evs ++ replaced ++ [used] ++ effEvs, g1)

registerEffect :: UserId -> Card -> Battle -> (Battle, [Event])
registerEffect u card b
  | T.null eff || dur <= 0 = (b, [])
  | eff == "purify" =
      let (b1, cleansed) = cleanseAll b
          b2 = addEffect u eff dur u b1
      in (b2, cleansed ++ [EvEffectApplied u eff dur u])
  | isDebuff eff =
      let target = opponentOf b u
      in case M.lookup target (bFighters b) of
           Nothing -> (b, [])
           Just tf
             | isPresent "guard" tf          ->
                 ( consumeGuard target b
                 , [EvEffectBlocked target eff "guard"]
                 )
             | any (isPresent "purify") (M.elems (bFighters b)) -> (b, [EvEffectBlocked target eff "purify"])
             | otherwise -> (addEffect target eff dur u b, [EvEffectApplied target eff dur u])
  | otherwise = (addEffect u eff dur u b, [EvEffectApplied u eff dur u])
  where
    eff = cardEffect card
    dur = cardEffectDur card
    consumeGuard target battle =
      battle { bFighters = M.adjust removeGuard target (bFighters battle) }
    removeGuard fighter =
      fighter { fEffects = filter ((/= "guard") . aeType) (fEffects fighter) }

opponentOf :: Battle -> UserId -> UserId
opponentOf b u = case filter (/= u) (bOrder b) of
  (o : _) -> o
  []      -> u

addEffect :: UserId -> Text -> Int -> UserId -> Battle -> Battle
addEffect target t dur src b = b { bFighters = M.adjust upd target (bFighters b) }
  where
    upd f = f { fEffects = ActiveEffect t dur True src : filter ((/= t) . aeType) (fEffects f) }

cleanseAll :: Battle -> (Battle, [Event])
cleanseAll b =
  let users = bOrder b
      evs   = [ EvEffectCleansed u (aeType e)
              | u <- users, Just f <- [M.lookup u (bFighters b)]
              , e <- fEffects f, isDebuff (aeType e) ]
      strip f = f { fEffects = filter (not . isDebuff . aeType) (fEffects f) }
  in (b { bFighters = M.map strip (bFighters b) }, evs)

tickEffects :: Battle -> (Battle, [Event])
tickEffects b =
  let step u (fs, evs) = case M.lookup u fs of
        Nothing -> (fs, evs)
        Just f  ->
          let tick e | aeFresh e = e { aeFresh = False }
                     | otherwise = e { aeLeft = aeLeft e - 1 }
              es'  = map tick (fEffects f)
              dead = [EvEffectExpired u (aeType e) | e <- es', aeLeft e <= 0]
          in (M.insert u f { fEffects = filter ((> 0) . aeLeft) es', fChoice = Nothing } fs, evs ++ dead)
      (fs', evs') = foldl' (flip step) (bFighters b, []) (bOrder b)
  in (b { bFighters = fs' }, evs')

winnerOf :: Battle -> Maybe UserId
winnerOf b = case sortOn (negate . snd) [(u, fAura f) | (u, f) <- M.toList (bFighters b)] of
  ((u1, a1) : (_, a2) : _) | a1 > a2 -> Just u1
  _                                  -> Nothing

simulateMatch :: Int -> [Card] -> [(UserId, Int)] -> (Battle, [[Event]])
simulateMatch seed pool players = go g1 b0 []
  where
    (order, g1) = decideOrder (mkStdGen seed) (map fst players)
    b0 = newBattle order pool players
    go g b logs
      | bRound b >= bMaxRounds b = (b, reverse logs)
      | otherwise =
          let (b1, g2)        = beginRound g b
              (b2, evs, g3)   = resolveRound g2 b1
          in go g3 b2 (evs : logs)
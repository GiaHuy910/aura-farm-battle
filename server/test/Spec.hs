{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import           Data.Aeson (Value (..), object, toJSON, (.=))
import qualified Data.Aeson.Key as Key
import qualified Data.Aeson.KeyMap as KeyMap
import qualified Data.Map.Strict as Map
import           Data.Text (Text)
import           Data.Time (UTCTime)
import           Database.MongoDB ((=:))
import           Config.GameConfig (Rarity (..))
import           Game.Config
import           Game.Random
import           Game.Rules
import           Game.Strategy
import           Game.Types
import           Game.View
import qualified Model.Clothe as Clothe
import qualified Model.Match as Match
import qualified Model.Skill as Skill
import qualified Model.User as User
import           System.Random (mkStdGen)
import           Test.Hspec
import           Test.QuickCheck hiding (shuffle)

-- Explicit fixtures keep the random-dependent round tests reproducible.
player1, player2 :: Text
player1 = "player-1"
player2 = "player-2"

card :: Text -> Bool -> Double -> Int -> Int -> Text -> Int -> Card
card cid isUlt mult consume recover effect duration = Card
  { cardId = cid
  , cardIsUlt = isUlt
  , cardName = cid
  , cardRarity = "common"
  , cardMult = mult
  , cardConsume = consume
  , cardRecover = recover
  , cardEffect = effect
  , cardEffectDur = duration
  , cardOwners = [player1]
  }

normal1, normal2, normal3, normal4 :: Card
normal1 = card "normal-1" False 1 0 1 "" 0
normal2 = card "normal-2" False 1.5 0 1 "" 0
normal3 = card "normal-3" False 2 0 1 "" 0
normal4 = card "normal-4" False 2.5 0 1 "" 0

normalCards :: [Card]
normalCards = [normal1, normal2, normal3, normal4]

ultCard :: Card
ultCard = card "ult-1" True 3 3 0 "" 0

withFighter :: Text -> Fighter -> Battle -> Battle
withFighter uid fighter battle =
  battle { bFighters = Map.insert uid fighter (bFighters battle) }

fighterOf :: Text -> Battle -> Fighter
fighterOf uid = (Map.! uid) . bFighters

chosenBattle :: Card -> Card -> Battle
chosenBattle first second =
  let battle = newBattle [player1, player2] normalCards [(player1, 100), (player2, 100)]
      f1 = (fighterOf player1 battle) { fHand = [first], fChoice = Just 0 }
      f2 = (fighterOf player2 battle) { fHand = [second], fChoice = Just 0 }
  in withFighter player2 f2 (withFighter player1 f1 battle)

lookupField :: Text -> Value -> Maybe Value
lookupField name (Object fields) = KeyMap.lookup (Key.fromText name) fields
lookupField _ _ = Nothing

eventKind :: Value -> Maybe Value
eventKind = lookupField "kind"

hasEffect :: Text -> Fighter -> Bool
hasEffect effect = any ((== effect) . aeType) . fEffects

errorOf :: Either Text a -> Maybe Text
errorOf = either Just (const Nothing)

main :: IO ()
main = hspec $ do
  describe "Game.Rules" $ do
    describe "applyMult" $ do
      it "applies the multiplier formula and cap to hand-picked values" $ do
        applyMult 0 0 `shouldBe` 1
        applyMult 0 100 `shouldBe` 101
        applyMult 1 100 `shouldBe` 201
        applyMult 0.5 10 `shouldBe` 16
        applyMult 0.75 100 `shouldBe` 176
        applyMult 100 auraCap `shouldBe` auraCap

      it "keeps non-negative aura inputs within the configured range" $
        property $ forAll (choose (0, 100000)) $ \aura ->
          forAll (choose (0.0, 10.0)) $ \mult ->
            let result = applyMult mult aura
            in result >= 0 && result <= auraCap

    it "allows normal cards regardless of energy but gates ultimates by consume" $ do
      let fighter = (newFighter player1 100) { fEnergy = 2 }
      canPlay fighter normal1 `shouldBe` True
      canPlay fighter ultCard `shouldBe` False
      canPlay (fighter { fEnergy = 3 }) ultCard `shouldBe` True

    it "returns only playable hand indices" $ do
      let fighter = (newFighter player1 100)
            { fEnergy = 2, fHand = [normal1, ultCard] }
      playableIndices fighter `shouldBe` [0]

    it "deals a deterministic four-card hand from a sufficiently large pool" $ do
      let (hand1, _) = beginRound (mkStdGen 42) (newBattle [player1] normalCards [(player1, 100)])
          (hand2, _) = beginRound (mkStdGen 42) (newBattle [player1] normalCards [(player1, 100)])
      length (fHand (fighterOf player1 hand1)) `shouldBe` handSize
      fHand (fighterOf player1 hand1) `shouldBe` fHand (fighterOf player1 hand2)
      all (`elem` normalCards) (fHand (fighterOf player1 hand1)) `shouldBe` True

    it "deals at most the available cards when the pool is smaller than a hand" $ do
      let pool = take 2 normalCards
          (battle, _) = beginRound (mkStdGen 42) (newBattle [player1] pool [(player1, 100)])
          hand = fHand (fighterOf player1 battle)
      length hand `shouldBe` 2
      all (`elem` pool) hand `shouldBe` True

    it "increments the round and energy, caps energy, redraws, and clears prior choices" $ do
      let base = newBattle [player1, player2] normalCards [(player1, 100), (player2, 100)]
          f1 = (fighterOf player1 base) { fEnergy = energyMax, fChoice = Just 0 }
          f2 = (fighterOf player2 base) { fEnergy = 2, fChoice = Just 0 }
          (next, _) = beginRound (mkStdGen 42) (withFighter player2 f2 (withFighter player1 f1 base))
      bRound next `shouldBe` 1
      fEnergy (fighterOf player1 next) `shouldBe` energyMax
      fEnergy (fighterOf player2 next) `shouldBe` 3
      fChoice (fighterOf player1 next) `shouldBe` Nothing
      length (fHand (fighterOf player1 next)) `shouldBe` handSize

    it "marks a fighter with an active freeze as already skipped for the round" $ do
      let base = newBattle [player1] normalCards [(player1, 100)]
          fighter = (fighterOf player1 base)
            { fEffects = [ActiveEffect "freeze" 2 False player2] }
          (next, _) = beginRound (mkStdGen 42) (withFighter player1 fighter base)
      fChoice (fighterOf player1 next) `shouldBe` Just (-1)

    describe "chooseCard" $ do
      let base = newBattle [player1] normalCards [(player1, 100)]
          playerWith hand energy effects choice =
            (fighterOf player1 base)
              { fHand = hand, fEnergy = energy, fEffects = effects, fChoice = choice }

      it "returns bad_index for an out-of-range index" $
        errorOf (chooseCard player1 5
          (withFighter player1 (playerWith normalCards 0 [] Nothing) base))
          `shouldBe` Just "bad_index"

      it "returns not_enough_energy when an ult cannot be afforded" $
        errorOf (chooseCard player1 0
          (withFighter player1 (playerWith [ultCard] 0 [] Nothing) base))
          `shouldBe` Just "not_enough_energy"

      it "returns already_chosen when a choice is already recorded" $
        errorOf (chooseCard player1 0
          (withFighter player1 (playerWith normalCards 0 [] (Just 1)) base))
          `shouldBe` Just "already_chosen"

      it "returns frozen for a fighter with an active freeze" $
        errorOf (chooseCard player1 0 (withFighter player1
          (playerWith normalCards 0 [ActiveEffect "freeze" 1 False player2] Nothing) base))
          `shouldBe` Just "frozen"

      it "records a valid choice" $
        fmap (fChoice . fighterOf player1)
          (chooseCard player1 2 (withFighter player1 (playerWith normalCards 0 [] Nothing) base))
          `shouldBe` Right (Just 2)

    it "considers the round complete when every fighter has a choice" $ do
      let battle = newBattle [player1, player2] normalCards [(player1, 100), (player2, 100)]
          ready = withFighter player2
            ((fighterOf player2 battle) { fChoice = Just (-1) })
            (withFighter player1 ((fighterOf player1 battle) { fChoice = Just 0 }) battle)
      allChosen ready `shouldBe` True
      allChosen battle `shouldBe` False

    describe "resolveRound" $ do
      it "resolves actions in the configured player order" $ do
        let battle = chosenBattle normal1 normal2
            ordered = battle { bOrder = [player2, player1] }
            (_, events, _) = resolveRound (mkStdGen 42) ordered
            acted = [uid | EvSkillUsed { evUser = uid } <- events]
        acted `shouldBe` [player2, player1]

      it "auto-picks for a player who has not selected a card" $ do
        let battle = chosenBattle normal1 normal1
            f2 = (fighterOf player2 battle) { fChoice = Nothing }
            (_, events, _) = resolveRound (mkStdGen 42) (withFighter player2 f2 battle)
        any (\event -> case event of EvAutoPicked uid _ -> uid == player2; _ -> False) events
          `shouldBe` True

      it "skips a frozen player and leaves a skipped event" $ do
        let battle = chosenBattle normal1 normal1
            f2 = (fighterOf player2 battle)
              { fEffects = [ActiveEffect "freeze" 1 False player1], fChoice = Just (-1) }
            (_, events, _) = resolveRound (mkStdGen 42) (withFighter player2 f2 battle)
        EvSkipped player2 "freeze" `elem` events `shouldBe` True

      it "applies boost and curse multipliers, including their combination" $ do
        let resolveWith effects =
              let battle = chosenBattle normal1 normal1
                  f1 = (fighterOf player1 battle) { fEffects = effects }
                  (_, events, _) = resolveRound (mkStdGen 42) (withFighter player1 f1 battle)
              in [evMult event | event@EvSkillUsed { evUser = uid } <- events, uid == player1]
            boost = ActiveEffect "boost" 2 False player1
            curse = ActiveEffect "curse" 2 False player2
        resolveWith [] `shouldBe` [1]
        resolveWith [boost] `shouldBe` [1.5]
        resolveWith [curse] `shouldBe` [0.75]
        resolveWith [boost, curse] `shouldBe` [1.125]

      it "applies self-buffs to the actor and debuffs to the opponent" $ do
        let cases = [("boost", player1), ("guard", player1), ("curse", player2),
                     ("freeze", player2), ("brainrotify", player2)]
        mapM_ (\(effect, target) -> do
          let battle = chosenBattle (card "effect-card" False 1 0 0 effect 2) normal1
              (resolved, events, _) = resolveRound (mkStdGen 42) battle
          hasEffect effect (fighterOf target resolved) `shouldBe` True
          EvEffectApplied target effect 2 player1 `elem` events `shouldBe` True
          ) cases

      it "cleanses debuffs from both players when purify is used" $ do
        let battle = chosenBattle (card "purify-card" False 1 0 0 "purify" 2) normal1
            f1 = (fighterOf player1 battle)
              { fEffects = [ActiveEffect "curse" 2 False player2] }
            f2 = (fighterOf player2 battle)
              { fEffects = [ActiveEffect "freeze" 2 False player1] }
            (resolved, events, _) =
              resolveRound (mkStdGen 42) (withFighter player2 f2 (withFighter player1 f1 battle))
        hasEffect "curse" (fighterOf player1 resolved) `shouldBe` False
        hasEffect "freeze" (fighterOf player2 resolved) `shouldBe` False
        hasEffect "purify" (fighterOf player1 resolved) `shouldBe` True
        EvEffectCleansed player1 "curse" `elem` events `shouldBe` True
        EvEffectCleansed player2 "freeze" `elem` events `shouldBe` True

      it "blocks a debuff with guard" $ do
        let battle = chosenBattle (card "freeze-card" False 1 0 0 "freeze" 2) normal1
            f2 = (fighterOf player2 battle)
              { fEffects = [ActiveEffect "guard" 2 False player2] }
            (resolved, events, _) = resolveRound (mkStdGen 42) (withFighter player2 f2 battle)
        hasEffect "freeze" (fighterOf player2 resolved) `shouldBe` False
        hasEffect "guard" (fighterOf player2 resolved) `shouldBe` False
        EvEffectBlocked player2 "freeze" "guard" `elem` events `shouldBe` True

      it "decrements existing effect durations and expires effects at zero" $ do
        let battle = chosenBattle normal1 normal1
            f1 = (fighterOf player1 battle)
              { fEffects = [ActiveEffect "boost" 2 False player1, ActiveEffect "guard" 1 False player1] }
            (resolved, events, _) = resolveRound (mkStdGen 42) (withFighter player1 f1 battle)
            effects = fEffects (fighterOf player1 resolved)
        map aeType effects `shouldContain` ["boost"]
        map aeLeft effects `shouldContain` [1]
        map aeType effects `shouldNotContain` ["guard"]
        EvEffectExpired player1 "guard" `elem` events `shouldBe` True

    it "returns the higher-aura player and Nothing for a tie" $ do
      let ahead = newBattle [player1, player2] [] [(player1, 20), (player2, 10)]
          tied = newBattle [player1, player2] [] [(player1, 20), (player2, 20)]
      winnerOf ahead `shouldBe` Just player1
      winnerOf tied `shouldBe` Nothing

    it "simulates exactly ten deterministic rounds with bounded energy and aura" $ do
      let players = [(player1, 100), (player2, 150)]
          first = simulateMatch 42 normalCards players
          second = simulateMatch 42 normalCards players
          (battle, logs) = first
      bRound battle `shouldBe` 10
      length logs `shouldBe` 10
      show first `shouldBe` show second
      all (\fighter -> fEnergy fighter >= 0 && fEnergy fighter <= energyMax) (Map.elems (bFighters battle))
        `shouldBe` True
      all (\fighter -> fAura fighter >= 0 && fAura fighter <= auraCap) (Map.elems (bFighters battle))
        `shouldBe` True

  describe "Game.Random and Game.Strategy" $ do
    it "shuffles without changing the input multiset" $
      property $ \values ->
        let (shuffled, _) = shuffle (mkStdGen 42) (values :: [Int])
        in length shuffled == length values && quickSort shuffled == quickSort values

    it "removes an indexed element without crashing for out-of-range indices" $ do
      removeAt 1 [10, 20, 30 :: Int] `shouldBe` [10, 30]
      removeAt (-1) [10, 20, 30 :: Int] `shouldBe` [10, 20, 30]
      removeAt 5 [10, 20, 30 :: Int] `shouldBe` [10, 20, 30]

    it "does not pick zero-weight entries when a positive weight is available" $ do
      let selected = pickWeighted (mkStdGen 42) [("zero" :: Text, 0), ("positive", 1)]
      fmap (\(value, _, _) -> value) selected `shouldBe` Just "positive"
      fst (sampleWeighted (mkStdGen 42) 1 [("zero" :: Text, 0), ("positive", 1)])
        `shouldBe` ["positive"]
      pickWeighted (mkStdGen 42) [("zero" :: Text, 0)] `shouldBe` Nothing

    it "samples the requested count without replacement when enough items exist" $ do
      let pool = zip [1 .. 5 :: Int] (repeat 1)
          (picked, _) = sampleWeighted (mkStdGen 42) 4 pool
      length picked `shouldBe` 4
      length (unique picked) `shouldBe` 4

    it "returns Nothing for an empty uniform pool and the sole item for a singleton" $ do
      pickUniform (mkStdGen 42) ([] :: [Int]) `shouldBe` Nothing
      fmap fst (pickUniform (mkStdGen 42) [7 :: Int]) `shouldBe` Just 7

    it "keeps the same order for the same seed and preserves both players" $ do
      let (order1, _) = decideOrder (mkStdGen 42) [player1, player2]
          (order2, _) = decideOrder (mkStdGen 42) [player1, player2]
      order1 `shouldBe` order2
      length order1 `shouldBe` 2
      unique order1 `shouldMatchList` [player1, player2]

    it "uses positive owner, card, and tier weights" $ do
      ownerWeight player1 `shouldSatisfy` (> 0)
      cardWeight normal1 `shouldSatisfy` (> 0)
      tierWeight "common" `shouldSatisfy` (> 0)
      tierWeight "mythical" `shouldSatisfy` (> 0)

    it "picks an offer with no duplicates, only from the pool, and handles small pools" $ do
      let pool = [("skill_1", "common"), ("shirt_1", "rare"), ("ult_1", "rare")]
          (offer, _) = pickOffer (mkStdGen 42) 5 pool
          (emptyOffer, _) = pickOffer (mkStdGen 42) 3 []
      length offer `shouldBe` 3
      length (unique offer) `shouldBe` 3
      all (`elem` map fst pool) offer `shouldBe` True
      emptyOffer `shouldBe` []

  describe "Game.Config" $ do
    it "recognizes exactly the default item identifiers" $ do
      map isDefaultItem defaultItems `shouldBe` replicate (length defaultItems) True
      isDefaultItem "unknown_item" `shouldBe` False

    it "classifies skill, ultimate, and clothing identifiers" $ do
      itemKind "s1_fire" `shouldBe` Just KindSkill
      itemKind "ult_fire" `shouldBe` Just KindSkill
      itemKind "acc_hat" `shouldBe` Just KindClothe
      itemKind "shirt_red" `shouldBe` Just KindClothe
      itemKind "shoes_blue" `shouldBe` Just KindClothe
      itemKind "unknown" `shouldBe` Nothing

    it "maps every item prefix to its equipment slot" $ do
      slotOf "s1_fire" `shouldBe` Just ("equipped_s1", "s1_1")
      slotOf "s2_fire" `shouldBe` Just ("equipped_s2", "s2_1")
      slotOf "s3_fire" `shouldBe` Just ("equipped_s3", "s3_1")
      slotOf "ult_fire" `shouldBe` Just ("equipped_ult", "ult_1")
      slotOf "acc_hat" `shouldBe` Just ("equipped_acc", "acc_1")
      slotOf "shirt_red" `shouldBe` Just ("equipped_shirt", "shirt_1")
      slotOf "shoes_blue" `shouldBe` Just ("equipped_shoes", "shoes_1")
      slotOf "unknown" `shouldBe` Nothing

  describe "Game.View" $ do
    it "includes the player's hand but never adds a hand to the opponent JSON" $ do
      let battle = newBattle [player1, player2] normalCards [(player1, 100), (player2, 100)]
          f1 = (fighterOf player1 battle) { fHand = [normal1] }
          f2 = (fighterOf player2 battle) { fHand = [card "secret-opponent-card" False 1 0 0 "" 0] }
          view = battleViewFor player1 (withFighter player2 f2 (withFighter player1 f1 battle)) Nothing
          you = lookupField "you" view
          opponent = lookupField "opponent" view
      (you >>= lookupField "hand") `shouldSatisfy` maybe False (const True)
      (opponent >>= lookupField "hand") `shouldBe` Nothing
      lookupField "round" view `shouldBe` Just (toJSON (0 :: Int))
      lookupField "maxRounds" view `shouldBe` Just (toJSON maxRounds)
      lookupField "timeLeftMs" view `shouldBe` Just Null

    it "keeps the expected public and private fighter fields" $ do
      let fighter = (newFighter player1 100) { fHand = [normal1] }
          public = fighterPublic fighter
          self = fighterSelf fighter
      lookupField "hand" public `shouldBe` Nothing
      lookupField "hand" self `shouldSatisfy` maybe False (const True)
      map (`lookupField` public) ["id", "aura", "energy", "effects", "chosen"]
        `shouldSatisfy` all (maybe False (const True))

    it "serializes each event variant with its expected kind" $ do
      let used = EvSkillUsed player1 normal1 1 10 20 2 1
          events =
            [ used
            , EvSkipped player1 "freeze"
            , EvAutoPicked player1 0
            , EvReplaced player1 "old" "new"
            , EvEffectApplied player1 "boost" 2 player1
            , EvEffectBlocked player1 "freeze" "guard"
            , EvEffectCleansed player1 "curse"
            , EvEffectExpired player1 "boost"
            ]
          expected = ["skill_used", "skipped", "auto_picked", "skill_replaced",
                      "effect_applied", "effect_blocked", "effect_cleansed", "effect_expired"]
      map (eventKind . eventJson) events `shouldBe` map (Just . String) expected

    it "adds or replaces an object field without dropping existing fields" $ do
      let original = object ["old" .= (1 :: Int), "updated" .= (2 :: Int)]
          result = withField "updated" (toJSON (3 :: Int)) original
      lookupField "old" result `shouldBe` Just (toJSON (1 :: Int))
      lookupField "updated" result `shouldBe` Just (toJSON (3 :: Int))

  describe "Pure model conversions" $ do
    it "round-trips user documents and tolerates missing fields" $ do
      let user = User.User
            { User.user_id = "u-1", User.username = "user", User.password = "hash"
            , User.tickets = 12, User.equipped_s1 = "s1_a", User.equipped_s2 = "s2_a"
            , User.equipped_s3 = "s3_a", User.equipped_ult = "ult_a"
            , User.equipped_acc = "acc_a", User.equipped_shirt = "shirt_a"
            , User.equipped_shoes = "shoes_a", User.owned_clothes = ["acc_a"]
            , User.owned_skills = ["s1_a"], User.pity_skill_leg = 1
            , User.pity_clothe_leg = 2, User.base_aura = 100
            , User.bonus_aura = 50, User.total_aura = 150
            }
          document = User.userToDoc user
      User.userToDoc (User.docToUser document) `shouldBe` document
      User.user_id (User.docToUser []) `shouldBe` ""
      User.tickets (User.docToUser []) `shouldBe` 0
      User.owned_skills (User.docToUser []) `shouldBe` []
      User.mapEquippedSkills "s1" "s2" "s3" "ult" `shouldBe` ["s1", "s2", "s3", "ult"]
      User.mapEquippedClothes "acc" "shirt" "shoes" `shouldBe` ["acc", "shirt", "shoes"]

    it "round-trips skill and effect documents and applies rarity defaults" $ do
      let skill = Skill.Skill
            { Skill.skill_id = "skill-1", Skill.skill_type = "s1", Skill.skill_name = "name"
            , Skill.energy_consumption = 2, Skill.energy_recovery = 1
            , Skill.aura_multiplier = 1.5, Skill.rarity = "rare"
            , Skill.effect = Skill.Effect "freeze" 2, Skill.in_pool = True
            }
          doc = Skill.skillToDoc skill
      Skill.skillToDoc (Skill.docToSkill doc) `shouldBe` doc
      Skill.docToSkill [] `shouldSatisfy` ((== "") . Skill.skill_id)
      Skill.effectToDoc (Skill.Effect "boost" 3) `shouldBe`
        ["effect_type" =: ("boost" :: Text), "effect_duration" =: (3 :: Int)]
      map Skill.textToRarity ["common", "uncommon", "rare", "epic", "legendary", "mythical", "other"]
        `shouldBe` [CommonBase, UncommonBase, RareBase, EpicBase, LegendaryBase, MythicalBase, CommonBase]
      Skill.getSkillBaseValue "s1" RareBase `shouldBe` 1.2
      Skill.getSkillBaseValue "ult" RareBase `shouldBe` 3.0

    it "round-trips clothing documents and maps rarity strings" $ do
      let clothe = Clothe.Clothe
            { Clothe.clothe_id = "shirt-1", Clothe.clothe_type = "shirt"
            , Clothe.clothe_name = "Shirt", Clothe.aura_bonus = 20
            , Clothe.rarity = "epic", Clothe.in_pool = True
            }
          doc = Clothe.clotheToDoc clothe
      Clothe.clotheToDoc (Clothe.docToClothe doc) `shouldBe` doc
      Clothe.docToClothe [] `shouldSatisfy` ((== "") . Clothe.clothe_id)
      map Clothe.textToRarity ["common", "uncommon", "rare", "epic", "legendary", "mythical", "other"]
        `shouldBe` [CommonBase, UncommonBase, RareBase, EpicBase, LegendaryBase, MythicalBase, CommonBase]

    it "round-trips match documents, including optional and nested fields" $ do
      let created = read "2024-01-02 03:04:05 UTC" :: UTCTime
          match = Match.Match
            { Match.mId = "match-1", Match.mRoom = "room-1", Match.mPlayers = ["u1", "u2"]
            , Match.mWinner = Just "u1", Match.mLoser = Just "u2", Match.mReason = "completed"
            , Match.mAuras = [("u1", 100), ("u2", 90)], Match.mStatus = "pending"
            , Match.mOfferSkills = ["s1"], Match.mOfferClothes = ["shirt"]
            , Match.mDeadline = Just created, Match.mPickedSkill = Nothing
            , Match.mPickedClothe = Just "shirt", Match.mTicketsGranted = False
            , Match.mCreatedAt = created
            }
          doc = Match.matchToDoc match
      Match.matchToDoc (Match.docToMatch doc) `shouldBe` doc

unique :: Eq a => [a] -> [a]
unique [] = []
unique (value : rest) = value : unique (filter (/= value) rest)

quickSort :: Ord a => [a] -> [a]
quickSort [] = []
quickSort (pivot : rest) =
  quickSort [value | value <- rest, value <= pivot]
  ++ [pivot]
  ++ quickSort [value | value <- rest, value > pivot]

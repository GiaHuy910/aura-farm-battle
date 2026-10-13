{-# LANGUAGE OverloadedStrings #-}
module Config.GameConfig
  ( userBaseAura
   , Rarity (..)
  , allRarities
  , rarityBase
  , clotheFlatBase
  , skillBase
  , userTotalAura 
  , userBonusAura
  , ultBase
  ) where


userBaseAura :: Int
userBaseAura = 100

data Rarity
  = CommonBase
  | UncommonBase
  | RareBase
  | EpicBase
  | LegendaryBase
  | MythicalBase
  deriving (Show, Eq, Ord, Enum, Bounded)

allRarities :: [Rarity]
allRarities = [minBound .. maxBound]

rarityBase :: Rarity -> Double
rarityBase CommonBase    = 0.3
rarityBase UncommonBase  = 0.6
rarityBase RareBase      = 1.2
rarityBase EpicBase      = 2.2
rarityBase LegendaryBase = 3.4
rarityBase MythicalBase  = 5.0

clotheBase :: Rarity -> Double
clotheBase = rarityBase

clotheFlatBase :: Int -> Rarity -> Int
clotheFlatBase userBase rarity = round (clotheBase rarity * fromIntegral userBase)

skillBase :: Rarity -> Double
skillBase = rarityBase

ultMultiplier :: Double
ultMultiplier = 2.5

ultBase :: Rarity -> Double
ultBase rarity = skillBase rarity * ultMultiplier

userTotalAura :: Int -> Rarity -> Rarity -> Rarity -> Int
userTotalAura userBase accessoryRarity shirtRarity shoesRarity = userBase + clotheFlatBase userBase accessoryRarity + clotheFlatBase userBase shirtRarity + clotheFlatBase userBase shoesRarity

userBonusAura :: Int -> Rarity -> Rarity -> Rarity -> Int
userBonusAura uBase accessoryRarity shirtRarity shoesRarity = clotheFlatBase uBase accessoryRarity + clotheFlatBase uBase shirtRarity + clotheFlatBase uBase shoesRarity
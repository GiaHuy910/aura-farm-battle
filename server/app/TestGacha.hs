{-# LANGUAGE OverloadedStrings #-}

module Main where

import Data.List (group, sort)
import Data.Text (Text)
import qualified Data.Text as T
import System.Random (randomRIO)

-- 1. Struct Mock Skill đơn giản dùng riêng cho test
data SkillMock = SkillMock
    { skill_id :: Text
    , rarity   :: Text
    } deriving (Show)

-- 2. Bộ Skill mẫu 53 món chuẩn theo đúng số lượng trong Main.hs
mockPool :: [SkillMock]
mockPool = concat
    [ replicate 8  (SkillMock "common_skill" "common")        -- 8 Common
    , replicate 8  (SkillMock "uncommon_skill" "uncommon")    -- 8 Uncommon
    , replicate 10 (SkillMock "rare_skill" "rare")            -- 10 Rare
    , replicate 10 (SkillMock "epic_skill" "epic")            -- 10 Epic
    , replicate 12 (SkillMock "legendary_skill" "legendary")  -- 12 Legendary
    , replicate 5  (SkillMock "mythical_skill" "mythical")    -- 5 Mythical
    ]

-- 3. Logic Gacha tỷ lệ % Double
rarityWeights :: [(Text, Double)]
rarityWeights = 
    [ ("mythical", 0.5)   -- 0.5%
    , ("legendary", 1.5)  -- 1.5%
    , ("epic", 8.0)      -- 8.0%
    , ("rare", 15.0)      -- 15.0%
    , ("uncommon", 30.0)  -- 30.0%
    , ("common", 45.0)    -- 45.0%
    ]

pickRarity :: Double -> [(Text, Double)] -> Text
pickRarity _ [(r, _)] = r
pickRarity randVal ((r, w):rest)
    | randVal <= w = r
    | otherwise    = pickRarity (randVal - w) rest
pickRarity _ [] = "common"

rollSingle :: Int -> [SkillMock] -> IO (SkillMock, Int)
rollSingle currentPity pool = do
    if currentPity >= 25
        then do
            -- Hard Pity (25 srolls): Guaranteed Legendary
            let legPool = filter (\x -> T.toLower (rarity x) == "legendary") pool
            idx <- randomRIO (0, length legPool - 1)
            return (legPool !! idx, 0)
        else do
            -- Step 1: Roll tier rarity
            let totalWeight = sum (map snd rarityWeights)
            randVal <- randomRIO (0.0 :: Double, totalWeight)
            let selectedRarity = pickRarity randVal rarityWeights
            
            -- Step 2: Filter matching items
            let filteredPool = filter (\x -> T.toLower (rarity x) == selectedRarity) pool
            let actualPool = if null filteredPool then pool else filteredPool
            
            -- Step 3: Pick item
            idx <- randomRIO (0, length actualPool - 1)
            let item = actualPool !! idx
            
            if T.toLower (rarity item) == "legendary"
                then return (item, 0)
                else return (item, currentPity + 1)

rollMultiple :: Int -> Int -> [SkillMock] -> IO ([SkillMock], Int)
rollMultiple 0 currentPity _ = return ([], currentPity)
rollMultiple n currentPity pool = do
    (item, nextPity) <- rollSingle currentPity pool
    (restItems, finalPity) <- rollMultiple (n - 1) nextPity pool
    return (item : restItems, finalPity)

main :: IO ()
main = do
    putStrLn "STARTING GACHA SIMULATION (1000 ROLLS)..."
    putStrLn $ "Mock Pool loaded: " ++ show (length mockPool) ++ " items."
    putStrLn "=========================================="
    
    let totalRolls = 5000
    (rolledSkills, finalPity) <- rollMultiple totalRolls 0 mockPool

    let rolledRarities = map (T.unpack . T.toLower . rarity) rolledSkills
    let stats = map (\l -> case l of (x:_) -> (x, length l); [] -> ("", 0)) . group . sort $ rolledRarities

    mapM_ (\(rName, count) -> do
        let pct = (fromIntegral count / fromIntegral totalRolls) * 100 :: Double
        putStrLn $ rName ++ "\t: " ++ show count ++ " rolls\t(~" ++ show pct ++ "%)"
        ) stats
        
    putStrLn "=========================================="
    putStrLn $ "Final Pity counter: " ++ show finalPity
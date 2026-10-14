{-# LANGUAGE OverloadedStrings #-}
module Seed.ClotheSeed(seedClothes) where

import Data.Text (Text)

import Model.Clothe (createClothe, countClothes)

clothe :: Text -> Text -> Text -> Text -> IO ()
clothe cid cType name r = createClothe cid cType name r True

acc :: Text -> Text -> Text -> IO ()
acc cid name r = clothe cid "acc" name r

shirt :: Text -> Text -> Text -> IO ()
shirt cid name r = clothe cid "shirt" name r

shoes :: Text -> Text -> Text -> IO ()
shoes cid name r = clothe cid "shoes" name r

seedAll :: IO ()
seedAll = do

  acc "acc_1"  "leaf"        "common"
  acc "acc_5"  "crown"       "common"
  acc "acc_6"  "weird hat"   "common"
  acc "acc_7"  "knight hat"  "common"
  acc "acc_8"  "magic hat"   "common"
  acc "acc_12" "happy hat"   "common"
  acc "acc_34" "straw hat"   "common"

  acc "acc_4"  "magical hat"  "uncommon"
  acc "acc_10" "chef hat"     "uncommon"
  acc "acc_11" "warrior hat"  "uncommon"
  acc "acc_13" "pirate hat"   "uncommon"
  acc "acc_15" "cow boy hat"  "uncommon"
  acc "acc_35" "scout hat"    "uncommon"

  acc "acc_2"  "black chicken hat" "rare"
  acc "acc_3"  "chicken hood"      "rare"
  acc "acc_14" "taoist hat"        "rare"
  acc "acc_20" "beanie"            "rare"
  acc "acc_36" "vintage lady hat"  "rare"

  acc "acc_33" "bunny ear"           "epic"
  acc "acc_16" "dark witch hat"      "epic"
  acc "acc_17" "plant pot"           "epic"
  acc "acc_28" "bowtie"              "epic"
  acc "acc_18" "clover"              "epic"
  acc "acc_22" "viking helmet"       "epic"
  acc "acc_37" "tactical police cap" "epic"
  acc "acc_29" "aviator sung glasses" "epic"

  acc "acc_9"  "conical hat"       "legendary"
  acc "acc_30" "mask"              "legendary"
  acc "acc_24" "gladiator helmet"  "legendary"
  acc "acc_25" "small angelwing"   "legendary"
  acc "acc_38" "cyber mecha helmet" "legendary"

  acc "acc_21" "samurai hat"           "mythical"
  acc "acc_23" "blue Superhero helmet" "mythical"
  acc "acc_27" "devilwing"             "mythical"
  acc "acc_31" "icewing"               "mythical"
  acc "acc_32" "bloodwing"             "mythical"
  acc "acc_19" "archagel halo wings"   "mythical"
  acc "acc_26" "eastern fire halo"     "mythical"

  shirt "shirt_1" "patched shirt" "common"
  shirt "shirt_2" "sack cloth"    "common"

  shirt "shirt_3" "chef uniform" "uncommon"
  shirt "shirt_4" "scout tunic"  "uncommon"

  shirt "shirt_5" "winter down jacket" "rare"
  shirt "shirt_6" "lady_dress"         "rare"
  shirt "shirt_7" "taoist robe"        "rare"

  shirt "shirt_8"  "viking armor"            "epic"
  shirt "shirt_9"  "tactical police uniform" "epic"
  shirt "shirt_10" "wizard robe"             "epic"

  shirt "shirt_11" "cyber mach armor" "legendary"
  shirt "shirt_12" "gladiator armor"  "legendary"

  shirt "shirt_13" "archangel holy armor" "mythical"
  shirt "shirt_14" "dragon god robe"      "mythical"

  shoes "shoes_1"  "straw shoes"       "common"
  shoes "shoes_3"  "iron shoes"        "common"
  shoes "shoes_4"  "noisy shoes"       "common"
  shoes "shoes_9"  "rainbow shoes"     "common"
  shoes "shoes_20" "leather footwraps" "common"

  shoes "shoes_7"  "leather boots" "uncommon"
  shoes "shoes_8"  "round shoes"   "uncommon"
  shoes "shoes_17" "elves boots"   "uncommon"
  shoes "shoes_21" "kitchen shoes" "uncommon"
  shoes "shoes_22" "scout boots"   "uncommon"

  shoes "shoes_5"  "apolo sandal"     "rare"
  shoes "shoes_6"  "speeder shoes"    "rare"
  shoes "shoes_11" "sausage boots"    "rare"
  shoes "shoes_15" "orange shoes"     "rare"
  shoes "shoes_19" "red high heels"   "rare"
  shoes "shoes_23" "winter sneakers"  "rare"
  shoes "shoes_24" "taoist sandals"   "rare"

  shoes "shoes_2"  "running shoes"         "epic"
  shoes "shoes_14" "astronaut boots"       "epic"
  shoes "shoes_25" "viking boots"          "epic"
  shoes "shoes_26" "tactical combat boots" "epic"

  shoes "shoes_12" "horn shoes"        "legendary"
  shoes "shoes_10" "unbreakable shoes" "legendary"
  shoes "shoes_18" "epic boots"        "legendary"
  shoes "shoes_27" "cyber mehca boots" "legendary"

  shoes "shoes_13" "magical boots"      "mythical"
  shoes "shoes_16" "chosen shoes"       "mythical"
  shoes "shoes_28" "divine plate boots" "mythical"

seedClothes :: IO ()
seedClothes = do
  existing <- countClothes
  if existing > 0
    then putStrLn ("Clothes already exist (" ++ show existing ++ "), skip seeding.")
    else do
      seedAll
      putStrLn "Seeded 80 clothes."
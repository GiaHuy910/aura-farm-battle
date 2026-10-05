{-# LANGUAGE OverloadedStrings #-}
module Config.Database (runDB) where
import Database.MongoDB

runDB :: Action IO a -> IO a
runDB action = do
    pipe <- connect (host "127.0.0.1")
    result <- access pipe master "aura-farm-battle" action
    close pipe
    return result
module Config.ServerConfig
    ( loadServerConfig
    ) where

import Configuration.Dotenv (defaultConfig, loadFile)
import System.Environment (lookupEnv)
import Text.Read (readMaybe)
import qualified Data.ByteString.Char8 as BS

loadServerConfig :: IO (Int, [BS.ByteString])
loadServerConfig = do
    loadFile defaultConfig

    portEnv <- lookupEnv "SERVER_PORT"
    originsEnv <- lookupEnv "ALLOWED_ORIGINS"

    let port = portEnv >>= readMaybe

    serverPort <- case port of
        Just p | p > 0 && p <= 65535 -> pure p
        _ -> fail "SERVER_PORT is invalid"

    origins <- case originsEnv of
        Just s | not (null s) ->
            pure [BS.pack s]
        _ -> fail "ALLOWED_ORIGINS is missing"
    
    pure (serverPort, origins)
{-# LANGUAGE OverloadedStrings #-}
module Ws.Message
  ( ClientMsg (..)
  , msg
  , playerValue
  ) where

import           Data.Aeson
import qualified Data.ByteString.Lazy as BL
import           Data.Text (Text)
import           Ws.Types

data ClientMsg = ClientMsg
  { cmType :: Text
  , cmData :: Maybe Value
  }

instance FromJSON ClientMsg where
  parseJSON = withObject "ClientMsg" $ \o ->
    ClientMsg <$> o .: "type" <*> o .:? "data"

msg :: Text -> Value -> BL.ByteString
msg t d = encode (object ["type" .= t, "data" .= d])

playerValue :: RoomStore -> UserId -> Bool -> IO Value
playerValue st u online = do
  p <- rsUserProfile st u
  pure $ object
    [ "id"               .= u
    , "name"             .= ppName p
    , "online"           .= online
    , "equipped_clothes" .= ppClothes p
    , "total_aura"       .= ppAura p
    ]
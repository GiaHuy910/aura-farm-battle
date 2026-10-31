module Ws.Env (Env (..)) where

import qualified Data.ByteString as BS
import           Game.Registry (Registry)
import           Ws.Hub (Hub)
import           Ws.Types (RoomStore)

data Env = Env
  { envHub            :: Hub
  , envStore          :: RoomStore
  , envRegistry       :: Registry        
  , envGraceSecs      :: Int           
  , envAllowedOrigins :: [BS.ByteString] 
  }
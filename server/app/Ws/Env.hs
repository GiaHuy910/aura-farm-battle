module Ws.Env (Env (..)) where

import qualified Data.ByteString as BS
import           Ws.Hub (Hub)
import           Ws.Types (RoomStore)

data Env = Env
  { envHub            :: Hub
  , envStore          :: RoomStore
  , envGraceSecs      :: Int             
  , envAllowedOrigins :: [BS.ByteString]  
  }
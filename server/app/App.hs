{-# LANGUAGE DataKinds     #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}

module App(runApp) where

import Network.Wai.Handler.Warp (run)
import Network.Wai.Middleware.Cors
import Servant
import qualified Data.ByteString as BS 

import Seed.SkillSeed  (seedSkills)
import Seed.ClotheSeed (seedClothes)
import Controllers.AuthController( registerHandler, loginHandler, logoutHandler, meHandler )
import Controllers.RoomController( getRoomsHandler, createRoomHandler, leaveRoomHandler, joinRoomHandler ) 
import Controllers.UserController( getEquippedSkillsHandler, getEquippedClothesHandler, getTicketsHandler, getOwnedItemsHandler, getGachaHandler, getEquipItemHandler)
import Controllers.PoolController( getPoolHandler )
import Controllers.GachaHistoryController( getGachaHistoryHandler)
import Controllers.WsController(wsHandler)
import Route.AuthRouter( AuthRouter)
import Route.RoomRouter( RoomRouter)
import Route.UserRouter( UserRouter)
import Route.PoolRouter( PoolRouter)
import Route.GachaHistoryRouter( GachaHistoryRouter)
import Route.WsRouter(WsRouter)
import Route.Index(Router)
import Config.ServerConfig(loadServerConfig)
import Ws.Env (Env(..))
import Ws.Hub (newHub)
import Ws.MongoStore (mongoStore)         

authServer :: Server AuthRouter
authServer =
       registerHandler
  :<|> loginHandler
  :<|> logoutHandler
  :<|> meHandler

roomServer :: Env -> Server RoomRouter
roomServer env =
       getRoomsHandler
  :<|> createRoomHandler
  :<|> joinRoomHandler env
  :<|> leaveRoomHandler env

userServer :: Server UserRouter
userServer =
       getEquippedSkillsHandler
  :<|> getEquippedClothesHandler
  :<|> getTicketsHandler
  :<|> getOwnedItemsHandler
  :<|> getGachaHandler
  :<|> getEquipItemHandler

poolServer :: Server PoolRouter
poolServer =
        getPoolHandler

gachaHistoryServer :: Server GachaHistoryRouter
gachaHistoryServer = getGachaHistoryHandler

wsServer :: Env -> Server WsRouter
wsServer env = wsHandler env

server :: Env -> Server Router
server env =
       authServer
  :<|> roomServer env
  :<|> userServer
  :<|> poolServer
  :<|> gachaHistoryServer
  :<|> wsServer env

api :: Proxy Router
api = Proxy

app :: [BS.ByteString] -> Env -> Application
app allowedOrigins env =
    let corsPolicy = simpleCorsResourcePolicy
            { corsOrigins = Just (allowedOrigins, True)
            , corsMethods =
                ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
            , corsRequestHeaders =
                ["Content-Type", "Authorization", "Cookie"]
            }
    in cors (const $ Just corsPolicy) (serve api (server env))

runApp :: IO ()
runApp = do
  (serverPort, allowedOrigins) <- loadServerConfig
  putStrLn "Checking db.."
  seedSkills
  seedClothes
  putStrLn "Sucesssfully checked!"

  hub   <- newHub
  let env = Env
        { envHub            = hub
        , envStore          = mongoStore
        , envGraceSecs      = 20
        , envAllowedOrigins = allowedOrigins
        }
  
  putStrLn "======================================"
  putStrLn "Aura Farm Battle Server"
  putStrLn "======================================"
  putStrLn "Server running at:"
  putStrLn ("http://localhost:" ++ show serverPort)
  putStrLn "======================================"

  run serverPort (app allowedOrigins env)
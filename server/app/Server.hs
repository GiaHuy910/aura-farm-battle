-- {-# LANGUAGE DataKinds     #-}
-- {-# LANGUAGE TypeOperators #-}
-- {-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
-- {-# LANGUAGE DuplicateRecordFields #-}

module Main where
import Network.Wai.Handler.Warp (run)
import Network.Wai.Middleware.Cors
import Servant

import Controllers.AuthController( registerHandler, loginHandler, logoutHandler, meHandler )
import Controllers.RoomController( getRoomsHandler, createRoomHandler, leaveRoomHandler, joinRoomHandler ) 
import Controllers.UserController( getEquippedSkillsHandler, getOwnedSkillsHandler, getEquippedClothesHandler, getOwnedClothesHandler, getTicketsHandler, getAvatarHandler)
import Route.AuthRouter( AuthRouter)
import Route.RoomRouter( RoomRouter)
import Route.UserRouter( UserRouter)
import Route.Index(Router)

authServer :: Server AuthRouter
authServer =
       registerHandler
  :<|> loginHandler
  :<|> logoutHandler
  :<|> meHandler

roomServer :: Server RoomRouter
roomServer =
       getRoomsHandler
  :<|> createRoomHandler
  :<|> joinRoomHandler
  :<|> leaveRoomHandler

userServer :: Server UserRouter
userServer =
       getEquippedSkillsHandler
  :<|> getOwnedSkillsHandler
  :<|> getEquippedClothesHandler
  :<|> getOwnedClothesHandler
  :<|> getTicketsHandler
  :<|> getAvatarHandler

server :: Server Router
server =
       authServer
  :<|> roomServer
  :<|> userServer

api :: Proxy Router
api = Proxy

corsPolicy :: CorsResourcePolicy
corsPolicy = simpleCorsResourcePolicy
    { corsOrigins = Just
        ( [ "http://localhost:4000"
          , "http://aura-farm-battle.com"
          ]
        , True -- CÁI CHỮ 'True' NÀY CHÍNH LÀ ĐỂ CHO PHÉP COOKIE (CREDENTIALS) RỒI
        )
    , corsMethods =
        [ "GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS" ]
    , corsRequestHeaders =
        [ "Content-Type", "Authorization", "Cookie" ]
    -- XÓA BỎ HOÀN TOÀN DÒNG corsRequireCredential Ở ĐÂY
    }
serverPort :: Int
serverPort = 3001

app :: Application
app = cors (const $ Just corsPolicy) (serve api server)

main :: IO ()
main = do
  putStrLn "======================================"
  putStrLn "Aura Farm Battle Server"
  putStrLn "======================================"
  putStrLn "Server running at:"
  putStrLn "http://localhost:3001"
  putStrLn "======================================"

  run serverPort app
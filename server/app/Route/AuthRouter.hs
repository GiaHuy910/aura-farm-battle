{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
module Route.AuthRouter where 

import Controllers.AuthController(RegisterRequest, LoginRequest, AuthResponse, MeResponse)
import Servant

type AuthRouter =
       "auth" :> "register"
           :> ReqBody '[JSON] RegisterRequest
           :> Post '[JSON] AuthResponse

  :<|> "auth" :> "login"
           :> ReqBody '[JSON] LoginRequest
           :> Post '[JSON]
               (Headers '[Header "Set-Cookie" String] AuthResponse)

  :<|> "auth" :> "logout"
           :> Header "Cookie" String
           :> Post '[JSON]
               (Headers '[Header "Set-Cookie" String] AuthResponse)

  :<|> "auth" :> "me"
           :> Header "Cookie" String
           :> Get '[JSON] MeResponse
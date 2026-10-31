{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module Route.GiftcodeRouter (GiftcodeRouter) where

import           Controllers.GiftcodeController
import           Servant

type GiftcodeRouter =
  "giftcode" :> "redeem"
    :> Header "Cookie" String
    :> ReqBody '[JSON] RedeemGiftcodeRequest
    :> Post '[JSON] RedeemGiftcodeResponse

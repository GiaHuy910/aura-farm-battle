{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE OverloadedRecordDot #-}

module Controllers.GiftcodeController
  ( RedeemGiftcodeRequest (..)
  , RedeemGiftcodeResponse (..)
  , redeemGiftcodeHandler
  ) where

import           Control.Monad.IO.Class (liftIO)
import           Data.Aeson (FromJSON (..), ToJSON (..), object, withObject, (.:), (.=))
import           Data.Text (Text)
import           GHC.Generics (Generic)
import           Servant

import           Controllers.AuthController (withAuthenticatedUser)
import           Model.Giftcode (GiftcodeRewards (..))
import           Model.User (User (..))
import           Service.GiftcodeService

data RedeemGiftcodeRequest = RedeemGiftcodeRequest
  { code :: Text
  } deriving (Generic, Show)

instance FromJSON RedeemGiftcodeRequest where
  parseJSON = withObject "RedeemGiftcodeRequest" $ \value ->
    RedeemGiftcodeRequest <$> value .: "code"

data RedeemGiftcodeResponse = RedeemGiftcodeResponse
  { redeemStatus   :: Text
  , redeemRewards  :: GiftcodeRewards
  } deriving (Show)

instance ToJSON RedeemGiftcodeResponse where
  toJSON response = object
    [ "status" .= redeemStatus response
    , "rewards" .= object
        [ "tickets" .= rewardTickets (redeemRewards response)
        , "skills" .= rewardSkills (redeemRewards response)
        , "clothes" .= rewardClothes (redeemRewards response)
        ]
    ]

redeemGiftcodeHandler
  :: Maybe String
  -> RedeemGiftcodeRequest
  -> Handler RedeemGiftcodeResponse
redeemGiftcodeHandler cookie request =
  withAuthenticatedUser cookie $ \user -> do
    result <- liftIO $ redeem user.user_id (code request)
    case result of
      Redeemed rewards -> pure (RedeemGiftcodeResponse "success" rewards)
      NotFound -> throwError err404 { errBody = "not_found" }
      Expired -> throwError err410 { errBody = "expired" }
      UsedUp -> throwError err409 { errBody = "used_up" }
      AlreadyRedeemed -> throwError err409 { errBody = "already_redeemed" }
      RateLimited -> throwError err429 { errBody = "rate_limited" }

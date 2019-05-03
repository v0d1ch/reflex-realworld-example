{-# LANGUAGE FlexibleContexts, LambdaCase, MultiParamTypeClasses, OverloadedStrings, PatternSynonyms #-}
module Frontend.Register where

import Control.Lens
import Reflex.Dom.Core


import           Control.Monad.IO.Class (MonadIO)
import           Data.List.NonEmpty     (NonEmpty)
import qualified Data.Map               as Map
import           Obelisk.Route.Frontend (pattern (:/), R, RouteToUrl, SetRoute, routeLink)
import           Servant.Common.Req     (reqSuccess)

import Common.Conduit.Api.Namespace        (Namespace (Namespace), unNamespace)
import Common.Conduit.Api.Users.Registrant (Registrant (Registrant))
import Common.Route                        (FrontendRoute (..))
import Frontend.Conduit.Client
import Frontend.FrontendStateT
import Frontend.Utils                      (buttonClass)


register
  :: ( DomBuilder t m
     , PostBuild t m
     , Prerender js t m
     , RouteToUrl (R FrontendRoute) m
     , SetRoute t (R FrontendRoute) m
     , TriggerEvent t m
     , PerformEvent t m
     , MonadIO (Performable m)
     , EventWriter t (NonEmpty e) (Client m)
     , AsFrontendEvent e
     , HasFrontendState t s m
     , HasLoggedInAccount s
     )
  => m ()
register = noUserWidget $ elClass "div" "auth-page" $ do
  elClass "div" "container-page" $
    elClass "div" "row" $
      elClass "div" "col-md-6 offset-md-3 col-xs-12" $ do
        elClass "h1" "text-xs-center" $ text "Sign up"
        elClass "p" "text-xs-center" $
          routeLink (FrontendRoute_Login :/ ()) $ text "Have an account?"
        elClass "ul" "error-messages" $
          blank
        prerender_ blank $ el "form" $ do
          usernameI <- elClass "fieldset" "form-group" $
            textInput $ def
              & textInputConfig_attributes .~ constDyn (Map.fromList
                [ ("class","form-control form-control-lg")
                , ("placeholder","Your name")
                ])
          emailI <- elClass "fieldset" "form-group" $
            textInput $ def
              & textInputConfig_attributes .~ constDyn (Map.fromList
                [ ("class","form-control form-control-lg")
                , ("placeholder","Email")
                ])
          passI <- elClass "fieldset" "form-group" $
            textInput $ def
              & textInputConfig_inputType  .~ "password"
              & textInputConfig_attributes .~ constDyn (Map.fromList
                [ ("class","form-control form-control-lg")
                , ("placeholder","Password")
                ])
          submitE <- buttonClass "btn btn-lg btn-primary pull-xs-right" $ text "Sign Up"
          let registrant = Registrant
                <$> usernameI ^. textInput_value
                <*> emailI ^. textInput_value
                <*> passI ^. textInput_value
          resE <- getClient ^. apiUsers . usersRegister . to (\f -> f (pure . pure . Namespace <$> registrant) submitE)
          tellEvent (fmap (pure . (_LogIn #) . unNamespace) . fmapMaybe (reqSuccess . runIdentity) $ resE)
          pure ()
  pure ()

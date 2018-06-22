{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE OverloadedStrings #-}

module Main where

import Control.Monad.IO.Class (MonadIO, liftIO)
import Control.Monad.Logger (MonadLogger, logInfoN, runStderrLoggingT)
import Data.Default.Class (def)
import Data.Monoid ((<>))
import qualified Data.Text as Text
import Development.GitRev (gitHash)
import Network.Wai.Handler.Warp
  ( HostPreference
  , defaultSettings
  , runSettings
  , setHost
  , setPort
  )
import Network.Wai.Middleware.Gzip (gzip)
import Network.Wai.Middleware.RequestLogger (logStdout)
import Options.Applicative
  ( Parser
  , auto
  , customExecParser
  , disambiguate
  , help
  , helper
  , idm
  , info
  , infoOption
  , long
  , option
  , prefs
  , short
  , showDefault
  , strOption
  , value
  )
import qualified Webserver

data Command =
  Run HostPreference
      Int
  deriving (Show, Eq)

versionOption :: Parser (a -> a)
versionOption =
  infoOption $(gitHash) (short 'v' <> long "version" <> help "Show the version")

commandParser :: Parser Command
commandParser =
  Run <$>
  (strOption
     (short 'b' <> long "bind" <> help "Webserver bind address" <> showDefault <>
      value "127.0.0.1")) <*>
  option
    auto
    (short 'p' <> long "port" <> help "Webserver port number" <> showDefault <>
     value 8080)

runCommand :: (MonadIO m, MonadLogger m) => Command -> m ()
runCommand (Run host port) = do
  logInfoN $ Text.pack $ "Running on " <> show host <> ":" <> show port
  liftIO $ runSettings settings (middleware Webserver.app)
  where
    settings = setHost host $ setPort port $ defaultSettings
    middleware = gzip def . logStdout

main :: IO ()
main = do
  command <-
    customExecParser
      (prefs disambiguate)
      (info (helper <*> versionOption <*> commandParser) idm)
  runStderrLoggingT $ runCommand command

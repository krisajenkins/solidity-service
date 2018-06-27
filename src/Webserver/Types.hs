{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE DeriveGeneric #-}

module Webserver.Types where

import Control.Lens (makeLenses, makePrisms)
import Data.Aeson
  ( FromJSON
  , ToJSON
  , Value(String)
  , (.:)
  , object
  , parseJSON
  , toJSON
  , withArray
  , withObject
  )
import Data.Map.Strict (Map)
import qualified Data.Text as Text
import Data.Text (Text)
import qualified Data.Vector as Vector
import GHC.Generics (Generic)
import PathUtils (TaintedPath)

data Status
  = Good
  | Bad
  deriving (Show, Eq, Generic)

instance ToJSON Status where
  toJSON x = object [("status", String . Text.pack . show $ x)]

------------------------------------------------------------
data RPCCall =
  RPCCallSol2IELEAsm Sol2IELEAsm
  deriving (Show, Eq, Generic)

instance FromJSON RPCCall where
  parseJSON =
    withObject "RPCCall" $ \obj -> do
      method :: Text <- obj .: "method"
      version :: Text <- obj .: "jsonrpc"
      params <- obj .: "params"
      decodeParams method version params
    where
      decodeParams "sol2iele_asm" "2.0" params =
        RPCCallSol2IELEAsm <$> parseJSON params
      decodeParams _ _ _ = fail "method/version not recognised."

data Sol2IELEAsm = Sol2IELEAsm
  { _mainFilename :: !TaintedPath
  , _files :: Map TaintedPath Text
  } deriving (Show, Eq, Generic)

instance FromJSON Sol2IELEAsm where
  parseJSON =
    withArray "params" $ \xs -> do
      params <- traverse parseJSON (Vector.toList xs)
      case params of
        [x, y] -> do
          _mainFilename <- parseJSON x
          _files <- parseJSON y
          pure Sol2IELEAsm {..}
        _ -> fail "Invalid payload."

makeLenses ''Sol2IELEAsm

makePrisms ''RPCCall

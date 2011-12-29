{-# LANGUAGE OverloadedStrings #-}
module Main where

import Control.Monad
import Database.LevelDB
import Data.ByteString.Char8 hiding (take)
import Debug.Trace

main :: IO ()
main = do
    withLevelDB dbdir opts $ \db -> do
        trace "put / delete:" $ do
            put db wopts "foo" "bar"
            get db ropts "foo" >>= print
            delete db wopts "foo"
            get db ropts "foo" >>= print

        trace "write batch:" $ do
            write db wopts [ Put "one" "one"
                           , Put "two" "two"
                           , Put "three" "three" ]
            dumpEntries db ropts

        trace "delete batch:" $ do
            write db wopts [ Del "one"
                           , Del "two"
                           , Del "three" ]
            dumpEntries db ropts

    trace "destroy database" $ destroy dbdir opts

    where
        dbdir = "/tmp/leveltest"

        opts  = defaultOptions
        wopts = defaultWriteOptions
        ropts = defaultReadOptions

        dumpEntries db ropts =
            withIterator db ropts $ \iter -> do
                iterFirst iter
                iterEntries iter print

        iterEntries iter f = do
            valid <- iterValid iter
            when valid $ do
                key <- iterKey iter
                val <- iterValue iter
                _   <- f (key, val)
                _   <- iterNext iter
                iterEntries iter f
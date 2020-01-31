{-# LANGUAGE OverloadedStrings, RecordWildCards #-}

module Main where

import Control.Applicative (optional)
import Control.Concurrent.Async (async, mapConcurrently_)
import Control.Monad (join, void)
import Control.Monad.IO.Class (liftIO)
import Fmt (fmtLn, listF, (+|), (|+))
import Data.Text.Encoding (decodeUtf8, encodeUtf8)
import Data.Text (unpack)
import Data.ByteString.Char8 as BS (ByteString, length, words, putStrLn)
import Data.Maybe (fromJust, fromMaybe, isJust, listToMaybe)
import Network.Simple.TCP (HostPreference(Host), SockAddr, Socket, closeSock, recv, send, serve)
import System.Environment (getArgs, getEnv)
import System.Exit (ExitCode(ExitSuccess))
import System.Metrics.Prometheus.Concurrent.RegistryT (registerCounter, registerGauge, runRegistryT)
import System.Metrics.Prometheus.Http.Scrape (serveHttpTextMetricsT)
import System.Metrics.Prometheus.Metric.Counter as C (Counter, inc)
import System.Metrics.Prometheus.Metric.Gauge as G (Gauge, dec, inc)
import System.Metrics.Prometheus.MetricId (addLabel, fromList)
import System.Process (readProcessWithExitCode)

data StatisticsHandlers
  = StatisticsHandlers
  { requests :: Counter
  , success  :: Gauge
  , failure  :: Gauge
  , running  :: Gauge
  }

type UploadTarget = String

-- | First element of a list that is not Nothing
firstJust :: [Maybe a] -> Maybe a
firstJust = join . listToMaybe . Prelude.filter isJust


-- | Upload target is taken either from first argument or from UPLOAD_TARGET env variable
getUploadTarget :: IO (Maybe UploadTarget)
getUploadTarget = firstJust <$> sequence
  [ listToMaybe <$> getArgs
  , optional $ getEnv "UPLOAD_TARGET"
  ]

-- | Get an environment variable with default fallback
getEnvDefault :: String -> String -> IO String
getEnvDefault var def = fromMaybe def <$> (optional $ getEnv var)

-- | Receive data from `sock` until EOF or connection closure
recvAll :: Socket -> IO (Maybe ByteString)
recvAll sock = do
  dat <- recv sock 1024
  case dat of
    Just str ->
      if BS.length str == 1024
      then (\rest -> dat <> rest) <$> recvAll sock
      else return dat
    Nothing -> return Nothing

-- | Upload a path to target binary cache
upload :: UploadTarget -> StatisticsHandlers -> ByteString -> IO ()
upload target (StatisticsHandlers {..}) path = do
  G.inc running
  (code, _, stderr) <- readProcessWithExitCode "nix"
    [ "copy", "--to", target, (unpack $ decodeUtf8 path) ]
    ""
  G.dec running
  if code /= ExitSuccess
    then G.inc failure >> Prelude.putStrLn stderr
    else G.inc success >> Prelude.putStr "Uploaded " >> BS.putStrLn path


-- | Receive space-separated paths until EOF, and upload them
handleConnection :: UploadTarget -> StatisticsHandlers -> (Socket, SockAddr) -> IO ()
handleConnection uploadTarget handlers@(StatisticsHandlers {..}) (sock, _) = do
  C.inc requests
  Just paths <- recvAll sock -- Failure here will fail only the upload thread
  let pathsList = BS.words paths
  fmtLn ("Uploading "+|listF (decodeUtf8 <$> pathsList)|+"")
  send sock ("Queued "+|Prelude.length pathsList|+" paths\n")
  closeSock sock
  mapConcurrently_ (upload uploadTarget handlers) pathsList

main :: IO ()
main = do
  uploadTarget <- fromJust <$> liftIO getUploadTarget -- Bail out if no upload target is specified
  port <- getEnvDefault "PORT" "8081"
  prometheusPort <- getEnvDefault "PROMETHEUS_PORT" "8080"
  fmtLn ("Starting server on localhost:"+|port|+" uploading to "+|uploadTarget|+"")
  runRegistryT $ do
    uploadSuccess <- registerGauge "uploads" (fromList [("upload", "success")])
    uploadFailure <- registerGauge "uploads" (addLabel "upload" "failure" mempty)
    uploadRunning <- registerGauge "uploads" (addLabel "upload" "running" mempty)
    requestCounter <- registerCounter "requests_total" mempty


    void $ liftIO $ async
      $ serve (Host "127.0.0.1") (port)
      $ handleConnection
      uploadTarget
      (StatisticsHandlers requestCounter uploadSuccess uploadFailure uploadRunning)

    serveHttpTextMetricsT (read prometheusPort) [ "metrics" ]

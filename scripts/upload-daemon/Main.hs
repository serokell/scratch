{-# LANGUAGE OverloadedStrings, RecordWildCards #-}

module Main (main) where

import Control.Monad (void, forever, forM_)
import Control.Monad.IO.Class (liftIO)
import Control.Concurrent
import Control.Concurrent.Async (async)
import Data.Text.Encoding (decodeUtf8)
import Data.Text (unpack, intercalate)
import qualified Data.Text.IO as T
import qualified Data.ByteString.Char8 as BS
import Data.ByteString.Char8 (ByteString)
import Network.Simple.TCP (HostPreference(Host), SockAddr, Socket, closeSock, recv, send, serve)
import System.Exit (ExitCode(ExitSuccess))
import System.Metrics.Prometheus.Concurrent.RegistryT (registerCounter, registerGauge, runRegistryT)
import System.Metrics.Prometheus.Http.Scrape (serveHttpTextMetricsT)
import System.Metrics.Prometheus.Metric.Counter as C (Counter, inc)
import System.Metrics.Prometheus.Metric.Gauge as G (Gauge, dec, inc)
import System.Metrics.Prometheus.MetricId (addLabel, fromList)
import System.Process (readProcessWithExitCode)
import Options.Applicative (Parser, option, progDesc, helper, info, execParser, fullDesc, header, metavar, short, help, strOption, showDefault, value, long, auto, (<**>))
import Data.Semigroup ((<>))

data StatisticsHandlers
  = StatisticsHandlers
  { requests :: Counter
  , success  :: Gauge
  , failure  :: Gauge
  , running  :: Gauge
  }

type UploadTarget = String

data UploadOptions = UploadOptions
  { port :: Int
  , prometheusPort :: Int
  , uploadTarget :: UploadTarget
  , nrWorkers :: Int
  }

uploadOptions :: Parser UploadOptions
uploadOptions = UploadOptions
  <$> option auto
  ( long "port"
    <> short 'p'
    <> metavar "PORT"
    <> value 8080
    <> showDefault
    <> help "Daemon listening port" )
  <*> option auto
  ( long "stat-port"
    <> short 's'
    <> metavar "SPORT"
    <> value 8081
    <> showDefault
    <> help "Prometheus listening port" )
  <*> strOption
  ( long "target"
    <> short 't'
    <> metavar "TARGET"
    <> help "Target" )
  <*> option auto
  ( long "workers"
    <> short 'j'
    <> metavar "WORKERS"
    <> value 2
    <> showDefault
    <> help "Number of nix-copies to run at the same time" )


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
    then G.inc failure >> putStrLn stderr
    else G.inc success >> putStr "Uploaded " >> BS.putStrLn path


-- | Receive space-separated paths until EOF, and upload them
handleConnection :: UploadTarget -> Chan (UploadTarget, ByteString) -> StatisticsHandlers -> (Socket, SockAddr) -> IO ()
handleConnection uploadTarget uploadCh (StatisticsHandlers {..}) (sock, _) = do
  C.inc requests
  Just paths <- recvAll sock -- Failure here will fail only the upload thread
  let pathsList = BS.words paths
  T.putStrLn $ "Uploading " <> (intercalate ", " $ decodeUtf8 <$> pathsList)
  send sock $ "Queued " <> (BS.pack . show $ Prelude.length pathsList) <> " paths\n"
  closeSock sock
  forM_ pathsList $ \path -> writeChan uploadCh (uploadTarget, path)

uploadWorker :: StatisticsHandlers -> Chan (UploadTarget, ByteString) -> IO ()
uploadWorker shand uploadCh = forever $ do
  readChan uploadCh >>= (uncurry $ flip upload shand)

main :: IO ()
main = do
  UploadOptions{..} <- execParser opts
  putStrLn $ "Starting server on localhost:" <> show port <> " uploading to " <> uploadTarget
  uploadCh <- newChan
  runRegistryT $ do
    uploadSuccess <- registerGauge "uploads" (fromList [("upload", "success")])
    uploadFailure <- registerGauge "uploads" (addLabel "upload" "failure" mempty)
    uploadRunning <- registerGauge "uploads" (addLabel "upload" "running" mempty)
    requestCounter <- registerCounter "requests_total" mempty
    let shand = StatisticsHandlers requestCounter uploadSuccess uploadFailure uploadRunning

    liftIO $ forM_ [1..nrWorkers] (\_ -> forkIO $ uploadWorker shand uploadCh)

    void $ liftIO $ async
      $ serve (Host "127.0.0.1") (show port)
      $ handleConnection uploadTarget uploadCh shand

    serveHttpTextMetricsT prometheusPort [ "metrics" ]
  where
    opts = info (uploadOptions <**> helper)
      ( fullDesc
     <> progDesc "Listen on PORT for target paths"
     <> header "nix-upload-daemon - keep a queue of uploading paths to a remote store" )

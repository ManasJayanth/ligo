module AST.Parser
  ( Source (..)
  , ParserCallback
  , parse
  , loadPreprocessed
  , parsePreprocessed
  , parseWithScopes
  , parseContracts
  , scanContracts
  , parseContractsWithDependencies
  , parseContractsWithDependenciesScopes
  , collectAllErrors
  ) where

import Control.Monad ((<=<))
import Control.Monad.IO.Unlift (MonadIO (liftIO), MonadUnliftIO)
import Data.Bifunctor (second)
import Data.Foldable (toList)
import Data.List (find)
import Data.Maybe (fromMaybe, isJust)
import Data.Text (Text)
import Data.Text qualified as Text (lines, unlines)
import System.Directory (doesDirectoryExist, getDirectoryContents)
import System.FilePath ((</>), takeDirectory)
import Text.Regex.TDFA ((=~))
import UnliftIO.Async (pooledMapConcurrently)
import UnliftIO.Exception (Handler (..), catches, displayException, fromEither)

import AST.Includes (includesGraph)
import AST.Parser.Camligo qualified as Caml
import AST.Parser.Pascaligo qualified as Pascal
import AST.Parser.Reasonligo qualified as Reason
import AST.Parser.Jsligo qualified as Js
import AST.Scope
  ( ContractInfo, ContractInfo', pattern FindContract, HasScopeForest, Includes (..)
  , ParsedContractInfo, addLigoErrsToMsg, addScopes, contractNotFoundException
  , lookupContract
  )
import Cli
  ( HasLigoClient, LigoDecodedExpectedClientFailureException (..)
  , SomeLigoException (..), fromLigoErrorToMsg, preprocess
  )
import Extension
import Log (Log, i)
import Log qualified
import ParseTree (Source (..), pathToSrc, toParseTree)
import Parser
import Progress (Progress (..), ProgressCallback, noProgress, (%))
import Util.Graph (wcc)

type ParserCallback m contract = Source -> m contract

parse :: Log m => ParserCallback m ContractInfo
parse src = do
  (recogniser, dialect) <- fromEither $ onExt ElimExt
    { eePascal = (Pascal.recognise, Pascal)
    , eeCaml   = (Caml.recognise,   Caml)
    , eeReason = (Reason.recognise, Reason)
    , eeJs     = (Js.recognise,     Js)
    } (srcPath src)
  tree <- toParseTree dialect src
  uncurry (FindContract src) <$> runParserM (recogniser tree)

loadPreprocessed :: (HasLigoClient m, Log m) => Source -> m (Source, [Message])
loadPreprocessed src = do
  let (src', needsPreprocessing) = prePreprocess $ srcText src
  if needsPreprocessing
    then
      (second (const []) <$> preprocess src') `catches`
        [ Handler \(LigoDecodedExpectedClientFailureException errs warns _) ->
          pure (src', fromLigoErrorToMsg <$> toList errs <> warns)
        , Handler \(_ :: SomeLigoException) ->
          pure (src', [])
        , Handler \(e :: IOError) -> do
          -- Likely LIGO isn't installed or was not found.
          $(Log.err) [i|Couldn't call LIGO, failed with #{displayException e}|]
          pure (src', [])
        ]
    else
      pure (src', [])
  where
    -- If the user has hand written any line markers, they will get removed here.
    -- Also query whether we need to do any preprocessing at all in the first place.
    prePreprocess :: Text -> (Source, Bool)
    prePreprocess contents =
      let
        hasPreprocessor = contents =~ ("^#\\s*[a-z]+" :: Text)
        prepreprocessed = (\l -> maybe (l, False) (const (mempty, True)) $ parseLineMarkerText l) <$> Text.lines contents
        shouldPreprocess = hasPreprocessor || any snd prepreprocessed
      in
      (Source (srcPath src) $ Text.unlines $ map fst prepreprocessed, shouldPreprocess)

parsePreprocessed :: (HasLigoClient m, Log m) => Source -> m ContractInfo
parsePreprocessed src = do
  (src', msgs) <- loadPreprocessed src
  addLigoErrsToMsg msgs <$> parse src'

parseWithScopes
  :: forall impl m
   . (HasScopeForest impl m, Log m)
  => Source
  -> m ContractInfo'
parseWithScopes src = do
  let fp = srcPath src
  graph <- parseContractsWithDependencies parsePreprocessed noProgress (takeDirectory fp)
  scoped <- addScopes @impl noProgress $ fromMaybe graph $ find (isJust . lookupContract fp) (Includes <$> wcc (getIncludes graph))
  maybe (contractNotFoundException fp scoped) pure (lookupContract fp scoped)

-- | Parse the whole directory for LIGO contracts and collect the results.
-- This ignores every other file which is not a contract.
parseContracts
  :: MonadUnliftIO m
  => ParserCallback m contract
  -> ProgressCallback m
  -> FilePath
  -> m [contract]
parseContracts parser reportProgress top = do
  input <- scanContracts top
  let
    numContracts = length input
    mkMsg contract = [i|Parsing #{contract}|]
  pooledMapConcurrently
    (\(n, c) -> do
      reportProgress (Progress (n % numContracts) (mkMsg c))
      src <- pathToSrc c
      parser src)
    (zip [(0 :: Int) ..] input)

-- | Scan the whole directory for LIGO contracts.
-- This ignores every other file which is not a contract.
scanContracts :: MonadIO m => FilePath -> m [FilePath]
scanContracts = liftIO . scanContractsImpl []

scanContractsImpl :: [FilePath] -> FilePath -> IO [FilePath]
scanContractsImpl seen top = do
  let exclude p = p /= "." && p /= ".."
  ds <- getDirectoryContents top
  flip foldMap (filter exclude ds) \d -> do
    let p = top </> d
    exists <- doesDirectoryExist p
    if exists
      then scanContractsImpl seen p
      else if isLigoFile p
        then pure $ p : seen
        else pure seen

parseContractsWithDependencies
  :: MonadUnliftIO m
  => ParserCallback m ContractInfo
  -> ProgressCallback m
  -> FilePath
  -> m (Includes ParsedContractInfo)
parseContractsWithDependencies parser reportProgress =
  includesGraph <=< parseContracts parser reportProgress

parseContractsWithDependenciesScopes
  :: forall impl m
   . HasScopeForest impl m
  => ParserCallback m ContractInfo
  -> ProgressCallback m
  -> FilePath
  -> m (Includes ContractInfo')
parseContractsWithDependenciesScopes parser reportProgress =
  addScopes @impl reportProgress <=< parseContractsWithDependencies parser reportProgress

collectAllErrors :: ContractInfo' -> [Message]
collectAllErrors (FindContract _ tree errs) =
  errs <> collectTreeErrors tree

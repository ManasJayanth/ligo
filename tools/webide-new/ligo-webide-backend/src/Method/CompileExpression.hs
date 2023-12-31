module Method.CompileExpression (compileExpression) where

import Data.Text qualified as Text
import System.Exit (ExitCode(ExitFailure, ExitSuccess))

import Common (WebIDEM)
import Error (LigoCompilerError(..))
import Ligo (runLigo, moduleOption)
import Schema.CompileExpressionRequest (CompileExpressionRequest(..))
import Schema.CompilerResponse (CompilerResponse(..))
import Source (withProject)
import Types (prettyDisplayFormat)

compileExpression :: CompileExpressionRequest -> WebIDEM CompilerResponse
compileExpression request =
  withProject (cerProject request) $ \(dirPath, fullMainPath, pModule) -> do
    dialect <- case inferDialect fullMainPath of
      Nothing -> throwM $ WrongMainFileExtension fullMainPath
      Just d -> pure d

    (ec, out, err) <- runLigo dirPath $
      ["compile", "expression", "--no-color"]
      ++ moduleOption pModule
      ++ [prettyDialect dialect, Text.unpack (cerFunction request)]
      ++ maybe []
           (\df -> ["--display-format", prettyDisplayFormat df])
           (cerDisplayFormat request)
      ++ maybe [] (\p -> ["-p", Text.unpack p]) (cerProtocol request)
      ++ ["--init-file", fullMainPath]

    case ec of
      ExitSuccess -> pure (CompilerResponse $ Text.pack out)
      ExitFailure _ -> throwM $ LigoCompilerError $ Text.pack err

data Dialect = CameLIGO | JsLIGO
  deriving stock (Eq, Show, Ord, Enum)

prettyDialect :: Dialect -> String
prettyDialect = \case
  CameLIGO -> "cameligo"
  JsLIGO -> "jsligo"

inferDialect :: FilePath -> Maybe Dialect
inferDialect filepath =
  case Text.takeWhileEnd (/= '.') (Text.pack filepath) of
    "mligo" -> Just CameLIGO
    "jsligo" -> Just JsLIGO
    _ -> Nothing

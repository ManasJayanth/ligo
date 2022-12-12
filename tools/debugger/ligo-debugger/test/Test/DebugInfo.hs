-- | Reading debug info from ligo debug output.
module Test.DebugInfo
  ( module Test.DebugInfo
  ) where

import Control.Lens (_Empty, hasn't)
import Data.Default (def)
import Data.Typeable (cast)
import Fmt (Buildable (..), pretty)
import Test.Tasty (TestTree, testGroup)
import Test.Util

import Morley.Debugger.Core (SourceLocation (..))
import Morley.Michelson.ErrorPos (Pos (..), SrcPos (..))
import Morley.Michelson.Typed qualified as T
import Morley.Michelson.Typed.Util (dsGoToValues)

import Language.LIGO.Debugger.CLI.Call
import Language.LIGO.Debugger.CLI.Types
import Language.LIGO.Debugger.Michelson
import Language.LIGO.Debugger.Snapshots

data SomeInstr = forall i o. SomeInstr (T.Instr i o)

instance Eq SomeInstr where
  SomeInstr i1 == SomeInstr i2 = T.instrToOps i1 == T.instrToOps i2
deriving stock instance Show SomeInstr

instance Buildable SomeInstr where
  build (SomeInstr i) = build i

-- | Get instructions with associated 'InstrNo' metas.
collectMetas :: T.Instr i o -> [(EmbeddedLigoMeta, SomeInstr)]
collectMetas = T.dfsFoldInstr def { dsGoToValues = True } \case
  T.Meta (T.SomeMeta (cast -> Just (meta :: EmbeddedLigoMeta))) i -> case i of
    T.LAMBDA _ -> mempty
    _ -> one (meta, SomeInstr i)
  _ -> mempty

(?-) :: a -> b -> (a, b)
(?-) = (,)
infixr 0 ?-

-- | LIGO uses them to insert metadata between actual instructions
dummyInstr :: T.Instr a a
dummyInstr = T.Nested T.Nop

test_SourceMapper :: TestTree
test_SourceMapper = testGroup "Reading source mapper"
  [ testCase "simple-ops.mligo contract" do
      let file = contractsDir </> "simple-ops.mligo"
      ligoMapper <- compileLigoContractDebug "main" file
      (exprLocs, T.SomeContract contract, _) <-
        case readLigoMapper ligoMapper typesReplaceRules instrReplaceRules of
          Right v -> pure v
          Left err -> assertFailure $ pretty err

      let metasAndInstrs =
            map (first stripSuffixHashFromLigoIndexedInfo) $
            filter (hasn't (_1 . _Empty)) $
            toList $ collectMetas (T.unContractCode $ T.cCode contract)

      let mainType = LigoTypeResolved
            ( mkPairType
                (mkSimpleConstantType "Unit")
                (mkSimpleConstantType "Int")
              `mkArrowType`
              mkPairType
                (mkConstantType "List" [mkSimpleConstantType "operation"])
                (mkSimpleConstantType "Int")
            )

      metasAndInstrs
        @?=
        [ LigoMereEnvInfo
            [LigoHiddenStackEntry]
            ?- SomeInstr dummyInstr

        , LigoMereEnvInfo
            [LigoHiddenStackEntry]
            ?- SomeInstr dummyInstr

        , LigoMereEnvInfo
            [LigoStackEntryNoVar intType]
            ?- SomeInstr dummyInstr

        , LigoMereEnvInfo
            [LigoStackEntryNoVar intType]
            ?- SomeInstr dummyInstr

        , LigoMereEnvInfo
            [LigoStackEntryVar "s" intType]
            ?- SomeInstr dummyInstr

        , LigoMereLocInfo
            (LigoRange file (LigoPosition 2 15) (LigoPosition 2 17))
            ?- SomeInstr (T.PUSH $ T.VInt 42)

        , LigoMereLocInfo
            (LigoRange file (LigoPosition 2 11) (LigoPosition 2 17))
            ?- SomeInstr (T.ADD @'T.TInt @'T.TInt)

        , LigoMereEnvInfo
            [LigoStackEntryVar "s2" intType]
            ?- SomeInstr dummyInstr

        , LigoMereLocInfo
            (LigoRange file (LigoPosition 3 21) (LigoPosition 3 22))
            ?- SomeInstr (T.PUSH $ T.VInt 2)

        , LigoMereLocInfo
            (LigoRange file (LigoPosition 3 11) (LigoPosition 3 18))
            ?- SomeInstr (T.MUL @'T.TInt @'T.TInt)

        , LigoMereLocInfo
            (LigoRange file (LigoPosition 3 11) (LigoPosition 3 22))
            ?- SomeInstr (T.MUL @'T.TInt @'T.TInt)

        , LigoMereEnvInfo
            [LigoStackEntryVar "s2" intType]
            ?- SomeInstr dummyInstr

        , LigoMereLocInfo
            (LigoRange file (LigoPosition 4 3) (LigoPosition 4 24))
            ?- SomeInstr (T.NIL @'T.TOperation)

        , LigoMereLocInfo
            (LigoRange file (LigoPosition 4 3) (LigoPosition 4 28))
            ?- SomeInstr T.PAIR

        , LigoMereEnvInfo
            [ LigoStackEntryVar "main" mainType
            , LigoHiddenStackEntry
            ]
            ?- SomeInstr dummyInstr

        ]

      ((_slStart &&& _slEnd) <$> toList (getInterestingSourceLocations exprLocs))
        @?=
        -- Note: the order of entries below is not the interpretation order
        -- because we extracted these pairs from Set with its lexicographical order
        [ ( SrcPos (Pos 1) (Pos 11)
          , SrcPos (Pos 1) (Pos 17)
          )
        , ( SrcPos (Pos 2) (Pos 11)
          , SrcPos (Pos 2) (Pos 18)
          )
        , ( SrcPos (Pos 2) (Pos 11)
          , SrcPos (Pos 2) (Pos 22)
          )
        , ( SrcPos (Pos 3) (Pos 3)
          , SrcPos (Pos 3) (Pos 24)
          )
        , ( SrcPos (Pos 3) (Pos 3)
          , SrcPos (Pos 3) (Pos 28)
          )
        ]
  ]


test_Errors :: TestTree
test_Errors = testGroup "Errors"
  [ testCase "duplicated ticket error is recognized" do
      let file = contractsDir </> "dupped-ticket.mligo"
      ligoMapper <- compileLigoContractDebug "main" file
      void (readLigoMapper ligoMapper typesReplaceRules instrReplaceRules)
        @?= Left (PreprocessError UnsupportedTicketDup)

  ]

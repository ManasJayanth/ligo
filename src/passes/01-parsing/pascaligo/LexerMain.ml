(* Driver for the PascaLIGO lexer *)

(* Dependencies *)

module Region    = Simple_utils.Region
module EvalOpt   = Lexer_shared.EvalOpt
module Lexer     = Lexer_shared.Lexer
module LexerUnit = Lexer_shared.LexerUnit
module LexToken  = Lexer_pascaligo.LexToken

(* Input/Output *)

module IO =
  struct
    let options =
      let open EvalOpt in
      let block = mk_block ~opening:"(*" ~closing:"*)"
      in read ~block ~line:"//" ".ligo"
  end

(* Instantiating the standalone lexer *)

module M = LexerUnit.Make (IO) (Lexer.Make (LexToken))

(* Tracing all tokens in the source *)

let () =
  match M.trace () with
    Stdlib.Ok () -> ()
  | Error Region.{value; _} -> Printf.eprintf "\027[31m%s\027[0m%!" value

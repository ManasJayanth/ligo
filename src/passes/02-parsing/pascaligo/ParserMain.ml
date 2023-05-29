(* Driver for the PascaLIGO parser *)

(* Vendor dependencies *)

module Region = Simple_utils.Region
module Std    = Simple_utils.Std
module Lexbuf = Simple_utils.Lexbuf

(* Internal dependencies *)

module Config       = Preprocessing_pascaligo.Config
module Token        = Lexing_pascaligo.Token
module UnitPasses   = Lx_psc_self_units.Self
module TokenPasses  = Lx_psc_self_tokens.Self
module ParErr       = Parsing_pascaligo.ParErr
module Tree         = Cst_shared.Tree
module CST          = Cst_pascaligo.CST
module JsLIGO       = Parsing_pascaligo.JsLIGO
module JsLIGOPretty = Parsing_jsligo.Pretty

(* APIs *)

module PreprocAPI = Preprocessor.TopAPI
module LexerAPI   = Lexing_shared.TopAPI
module ParserAPI  = Parsing_shared.TopAPI

(* CLIs *)

module PreprocParams = Preprocessor.CLI.Make (Config)
module LexerParams   = LexerLib.CLI.Make (PreprocParams)
module Parameters    = ParserLib.CLI.Make (LexerParams)
module Options       = Parameters.Options

(* Instantiating preprocessor and lexer *)

module Preprocessor = PreprocAPI.Make (PreprocParams)

module Warning =
  struct
    let add _ = () (* No warning registered *)
  end

module Lexer =
  LexerAPI.Make
    (Preprocessor)
    (LexerParams)
    (Token)
    (UnitPasses)
    (TokenPasses)
    (Warning)

(* Renamings on the parser generated by Menhir to suit the functor. *)

module Parser =
  struct
    include Parsing_pascaligo.Parser
    type tree = CST.t

    let main = contract

    module Incremental =
      struct
        let main = Incremental.contract
      end

    module Recovery = Parsing_pascaligo.RecoverParser
  end

module Pretty =
  struct
    include Parsing_pascaligo.Pretty
    type tree = CST.t
  end

module Print =
  struct
    type tree = CST.t
    type state = Tree.state
    let mk_state = Tree.mk_state
    include Cst_pascaligo.Print
  end

(* Finally... *)

module Main =
  ParserAPI.Make
    (Lexer)
    (Parameters)
    (ParErr)
    (Warning)
    (UnitPasses)
    (TokenPasses)
    (CST)
    (Parser)
    (Print)
    (Pretty)

let () =
  let open! Main in
  match check_cli () with
    Ok ->
      let file = Option.value Options.input ~default:"" in
      let no_colour = Options.no_colour in
      let std, cst = parse ~no_colour (Lexbuf.File file) in
      let () =
        match cst, Options.jsligo with
          Ok (cst, _), Some file_opt ->
            let jsligo_cst = JsLIGO.of_cst cst in
            let doc = JsLIGOPretty.(print default_state) jsligo_cst in
            let width =
              match Terminal_size.get_columns () with
                None -> 60
              | Some c -> c in
            let buffer = Buffer.create 2000 in
            let () =
              PPrint.ToBuffer.pretty 1.0 width buffer doc in
            let contents = Buffer.contents buffer in (
              match file_opt with
                None -> Std.(add_line std.out contents)
              | Some file ->
                  let out_chan = Out_channel.open_text file in
                  Out_channel.output_string out_chan contents;
                  Out_channel.close out_chan)
        | _ -> () in
      let () = Std.(add_nl std.out) in
      let () = Std.(add_nl std.err) in
      Printf.printf  "%s%!" (Std.string_of std.out);
      Printf.eprintf "%s%!" (Std.string_of std.err)
  | Error msg -> Printf.eprintf "%s\n%!" msg
  | Info  msg -> Printf.printf "%s%!" msg (* Note the absence of "\n" *)

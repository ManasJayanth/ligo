(* Driver for the JsLIGO lexer *)

(* Local dependencies *)

module Config         = Preprocessing_jsligo.Config
module PreprocParams  = Preprocessor.CLI.Make (Config)
module Token          = Lexing_jsligo.Token
module UnitPasses     = Lexing_jsligo_self_units.Self
module TokenPasses    = Lexing_jsligo_self_tokens.Self

(* Vendors dependencies *)

module Std        = Simple_utils.Std
module Lexbuf     = Simple_utils.Lexbuf
module Parameters = LexerLib.CLI.Make (PreprocParams)
module PreprocAPI = Preprocessor.TopAPI.Make (PreprocParams)

module Warning =
  struct
    let add _ = () (* No warning registered *)
  end

module API =
  Lexing_shared.TopAPI.Make
    (PreprocAPI) (Parameters) (Token)
    (UnitPasses) (TokenPasses) (Warning)

let () =
  let open! API in
  match check_cli () with
    Ok ->
      let file = Option.value Parameters.Options.input ~default:"" in
      let std, _tokens = scan_all_tokens (Lexbuf.File file) in
      let () = Std.(add_nl std.out) in
      let () = Std.(add_nl std.err) in
      Printf.printf  "%s%!" (Std.string_of std.out);
      Printf.eprintf "%s%!" (Std.string_of std.err)
  | Error msg -> Printf.eprintf "%s\n%!" msg
  | Info  msg -> Printf.printf "%s%!" msg (* Note the absence of "\n" *)

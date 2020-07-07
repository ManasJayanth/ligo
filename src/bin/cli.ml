open Cmdliner
open Trace
open Cli_helpers

let version = Version.version

let main =
  let man =
    [ `S "MORE HELP";
      `P "Use `$(mname) $(i,COMMAND) --help' for help on a single command." ] in
  (Term.(ret (const (`Help (`Auto, None)))), Term.info "ligo" ~version ~man)

let source_file n =
  let open Arg in
  let info =
    let docv = "SOURCE_FILE" in
    let doc = "$(docv) is the path to the smart contract file." in
    info ~docv ~doc [] in
  required @@ pos n (some string) None info

let entry_point n =
  let open Arg in
  let info =
    let docv = "ENTRY_POINT" in
    let doc = "$(docv) is entry-point that will be compiled." in
    info ~docv ~doc [] in
  required @@ pos n (some string) (Some "main") info

let expression purpose n =
  let open Arg in
  let docv = purpose ^ "_EXPRESSION" in
  let doc = "$(docv) is the expression that will be compiled." in
  let info = info ~docv ~doc [] in
  required @@ pos n (some string) None info

let syntax =
  let open Arg in
  let info =
    let docv = "SYNTAX" in
    let doc = "$(docv) is the syntax that will be used. Currently supported syntaxes are \"pascaligo\", \"cameligo\" and \"reasonligo\". By default, the syntax is guessed from the extension (.ligo, .mligo, .religo respectively)." in
    info ~docv ~doc ["syntax" ; "s"] in
  value @@ opt string "auto" info

let req_syntax n =
  let open Arg in
  let info =
    let docv = "SYNTAX" in
    let doc = "$(docv) is the syntax that will be used. Currently supported syntaxes are \"pascaligo\", \"cameligo\" and \"reasonligo\". By default, the syntax is guessed from the extension (.ligo, .mligo, .religo respectively)." in
    info ~docv ~doc [] in
  required @@ pos n (some string) None info

let init_file =
  let open Arg in
  let info =
    let docv = "INIT_FILE" in
    let doc = "$(docv) is the path to smart contract file to be used for context initialization." in
    info ~docv ~doc ["init-file"] in
  value @@ opt (some string) None info

let amount =
  let open Arg in
  let info =
    let docv = "AMOUNT" in
    let doc = "$(docv) is the amount the Michelson interpreter will use for the transaction." in
    info ~docv ~doc ["amount"] in
  value @@ opt string "0" info

let balance =
  let open Arg in
  let info =
    let docv = "BALANCE" in
    let doc = "$(docv) is the balance the Michelson interpreter will use for the contract balance." in
    info ~docv ~doc ["balance"] in
  value @@ opt string "0" info

let sender =
  let open Arg in
  let info =
    let docv = "SENDER" in
    let doc = "$(docv) is the sender the Michelson interpreter transaction will use." in
    info ~docv ~doc ["sender"] in
  value @@ opt (some string) None info

let source =
  let open Arg in
  let info =
    let docv = "SOURCE" in
    let doc = "$(docv) is the source the Michelson interpreter transaction will use." in
    info ~docv ~doc ["source"] in
  value @@ opt (some string) None info

let disable_michelson_typechecking =
  let open Arg in
  let info =
    let doc = "disable Michelson typecking, this might produce ill-typed Michelson code." in
    info ~doc ["disable-michelson-typechecking"] in
  value @@ flag info

let with_types =
  let open Arg in
  let info =
    let doc = "tries to infer types for all named expressions" in
    info ~doc ["with-types"] in
  value @@ flag info

let brief =
  let open Arg in
  let info =
    let doc = "in case of an error, do not display links to online resources" in
    info ~doc ["brief"] in
  value @@ flag info

let predecessor_timestamp =
  let open Arg in
  let info =
    let docv = "PREDECESSOR_TIMESTAMP" in
    let doc = "$(docv) is the predecessor_timestamp (now value minus one minute) the Michelson interpreter will use (e.g. '2000-01-01T10:10:10Z')" in
    info ~docv ~doc ["predecessor-timestamp"] in
  value @@ opt (some string) None info

let display_format =
  let open Arg in
  let open Display in
  let info  =
    let docv = "DISPLAY_FORMAT" in
    let doc = "$(docv) is the format that will be used by the CLI. Available formats are 'dev', 'json', and 'human-readable' (default). When human-readable lacks details (we are still tweaking it), please contact us and use another format in the meanwhile." in
    info ~docv ~doc ["format" ; "display-format"] in
  value @@
  opt
    (enum [("human-readable", human_readable); ("dev", dev); ("json", json)])
    human_readable
    info

let output_file =
  let open Arg in
  let info  =
    let docv = "OUTPUT_FILE" in
    let doc = "$(docv) if used, prints the output into the specified file instead of stdout" in
    info ~docv ~doc ["output" ; "output-file"] in
  value @@ opt (some string) None info

let michelson_code_format =
  let open Arg in
  let info  =
    let docv = "MICHELSON_FORMAT" in
    let doc = "$(docv) is the format that will be used by compile-contract for the resulting Michelson. Available formats are 'text' (default), 'json' and 'hex'." in
    info ~docv ~doc ["michelson-format"] in
  value @@
  opt
    (enum [("text", `Text); ("json", `Json); ("hex", `Hex)])
    `Text info

let optimize =
  let open Arg in
  let docv = "ENTRY_POINT" in
  let doc = "Apply Mini-C optimizations as if compiling $(docv)" in
  let info =
    info ~docv ~doc ["optimize"] in
  value @@ opt (some string) None info


module Helpers   = Ligo.Compile.Helpers
module Compile   = Ligo.Compile
module Decompile = Ligo.Decompile
module Run = Ligo.Run.Of_michelson

let compile_file =
  let f source_file entry_point syntax display_format disable_typecheck michelson_format output_file brief =
    return_result ~output_file ~brief ~display_format (Tezos_utils.Michelson.michelson_format michelson_format) @@
      let%bind typed,_    = Compile.Utils.type_file source_file syntax (Contract entry_point) in
      let%bind mini_c     = Compile.Of_typed.compile typed in
      let%bind michelson  = Compile.Of_mini_c.aggregate_and_compile_contract mini_c entry_point in
      Compile.Of_michelson.build_contract ~disable_typecheck michelson
  in
  let term =
    Term.(const f $ source_file 0 $ entry_point 1 $ syntax $ display_format $ disable_michelson_typechecking $ michelson_code_format $ output_file $ brief) in
  let cmdname = "compile-contract" in
  let doc = "Subcommand: Compile a contract." in
  (Term.ret term , Term.info ~doc cmdname)

let preprocess =
  let f source_file syntax display_format brief =
    return_result ~display_format ~brief (Parser.Formatter.ppx_format) @@
      Compile.Of_source.preprocess source_file (Syntax_name syntax)
  in
  let term = Term.(const f $ source_file 0 $ syntax $ display_format $ brief) in
  let cmdname = "preprocess" in
  let doc = "Subcommand: Preprocess the source file.\nWarning: Intended for development of LIGO and can break at any time." in
  (Term.ret term, Term.info ~doc cmdname)

let pretty_print =
  let f source_file syntax display_format brief =
    return_result ~display_format ~brief (Parser.Formatter.ppx_format) @@
        Compile.Of_source.pretty_print source_file (Syntax_name syntax)
  in
  let term = Term.(const f $ source_file 0 $ syntax $ display_format $ brief) in
  let cmdname = "pretty-print" in
  let doc = "Subcommand: Pretty-print the source file."
  in (Term.ret term, Term.info ~doc cmdname)

let print_cst =
  let f source_file syntax display_format brief =
    return_result ~display_format ~brief (Parser.Formatter.ppx_format) @@
      Compile.Of_source.pretty_print_cst source_file (Syntax_name syntax)
  in
  let term = Term.(const f $ source_file 0 $ syntax $ display_format $ brief) in
  let cmdname = "print-cst" in
  let doc = "Subcommand: Print the CST.\nWarning: Intended for development of LIGO and can break at any time." in
  (Term.ret term, Term.info ~doc cmdname)

let print_ast =
  let f source_file syntax display_format brief =
    return_result ~display_format ~brief (Ast_imperative.Formatter.program_format) @@
      Compile.Utils.to_imperatve source_file syntax
  in
  let term = Term.(const f $ source_file 0 $ syntax $ display_format $ brief) in
  let cmdname = "print-ast" in
  let doc = "Subcommand: Print the AST.\n Warning: Intended for development of LIGO and can break at any time." in
  (Term.ret term, Term.info ~doc cmdname)

 
let print_ast_sugar =
  let f source_file syntax display_format brief =
    return_result ~display_format ~brief (Ast_sugar.Formatter.program_format) @@
      Compile.Utils.to_sugar source_file syntax
  in
  let term = Term.(const f $ source_file 0 $ syntax $ display_format $ brief) in
  let cmdname = "print-ast-sugar" in
  let doc = "Subcommand: Print the AST.\n Warning: Intended for development of LIGO and can break at any time." in
  (Term.ret term, Term.info ~doc cmdname)

let print_ast_core =
  let f source_file syntax display_format brief =
    return_result ~display_format ~brief (Ast_core.Formatter.program_format) @@
      Compile.Utils.to_core source_file syntax
  in
  let term = Term.(const f $ source_file 0 $ syntax $ display_format $ brief) in
  let cmdname = "print-ast-core" in
  let doc = "Subcommand: Print the AST.\n Warning: Intended for development of LIGO and can break at any time." in
  (Term.ret term, Term.info ~doc cmdname) 

let print_ast_typed =
  let f source_file syntax display_format brief =
    return_result ~display_format ~brief (Ast_typed.Formatter.program_format) @@
      let%bind typed,_    = Compile.Utils.type_file source_file syntax Env in
      ok typed
  in
  let term = Term.(const f $ source_file 0 $ syntax $ display_format $ brief) in
  let cmdname = "print-ast-typed" in
  let doc = "Subcommand: Print the typed AST.\n Warning: Intended for development of LIGO and can break at any time." in
  (Term.ret term, Term.info ~doc cmdname)

let print_mini_c =
  let f source_file syntax display_format optimize brief =
    return_result ~display_format ~brief (Mini_c.Formatter.program_format) @@
      let%bind typed,_    = Compile.Utils.type_file source_file syntax Env in
      let%bind mini_c     = Compile.Of_typed.compile typed in
      match optimize with
        | None -> ok @@ Mini_c.Formatter.Raw mini_c
        | Some entry_point ->
          let%bind o = Compile.Of_mini_c.aggregate_contract mini_c entry_point in
          ok @@ Mini_c.Formatter.Optimized o
  in
  let term = Term.(const f $ source_file 0 $ syntax $ display_format $ optimize $ brief) in
  let cmdname = "print-mini-c" in
  let doc = "Subcommand: Print Mini-C. Warning: Intended for development of LIGO and can break at any time." in
  (Term.ret term, Term.info ~doc cmdname)

let measure_contract =
  let f source_file entry_point syntax display_format brief =
    let value =
      let%bind contract   = Compile.Utils.compile_file source_file syntax entry_point in
      ok @@ Tezos_utils.Michelson.measure contract in
    let format = Display.bind_format Formatter.contract_size_format Main.Formatter.error_format in
    toplevel ~display_format ~brief (Display.Displayable { value ; format }) value
  in
  let term =
    Term.(const f $ source_file 0 $ entry_point 1 $ syntax $ display_format $ brief) in
  let cmdname = "measure-contract" in
  let doc = "Subcommand: Measure a contract's compiled size in bytes." in
  (Term.ret term , Term.info ~doc cmdname)

let compile_parameter =
  let f source_file entry_point expression syntax amount balance sender source predecessor_timestamp display_format michelson_format output_file brief =
    return_result ~output_file ~display_format ~brief (Tezos_utils.Michelson.michelson_format michelson_format) @@
      let%bind typed_prg,state = Compile.Utils.type_file source_file syntax (Contract entry_point) in
      let%bind mini_c_prg      = Compile.Of_typed.compile typed_prg in
      let%bind michelson_prg   = Compile.Of_mini_c.aggregate_and_compile_contract mini_c_prg entry_point in
      let      env             = Ast_typed.program_environment Environment.default typed_prg in
      let%bind (_contract: Tezos_utils.Michelson.michelson) =
        (* fails if the given entry point is not a valid contract *)
        Compile.Of_michelson.build_contract michelson_prg in

      let%bind (typed_param,_)  = Compile.Utils.type_expression (Some source_file) syntax expression env state in
      let%bind mini_c_param     = Compile.Of_typed.compile_expression typed_param in
      let%bind compiled_param   = Compile.Of_mini_c.aggregate_and_compile_expression mini_c_prg mini_c_param in
      let%bind ()               = Compile.Of_typed.assert_equal_contract_type Check_parameter entry_point typed_prg typed_param in
      let%bind ()               = Compile.Of_michelson.assert_equal_contract_type Check_parameter michelson_prg compiled_param in
      let%bind options          = Run.make_dry_run_options {predecessor_timestamp ; amount ; balance ; sender ; source } in
      Run.evaluate_expression ~options compiled_param.expr compiled_param.expr_ty
    in
  let term =
    Term.(const f $ source_file 0 $ entry_point 1 $ expression "PARAMETER" 2 $ syntax $ amount $ balance $ sender $ source $ predecessor_timestamp $ display_format $ michelson_code_format $ output_file $ brief) in
  let cmdname = "compile-parameter" in
  let doc = "Subcommand: Compile parameters to a Michelson expression. The resulting Michelson expression can be passed as an argument in a transaction which calls a contract." in
  (Term.ret term , Term.info ~doc cmdname)

let interpret =
  let f expression init_file syntax amount balance sender source predecessor_timestamp display_format brief =
    return_result ~display_format ~brief (Decompile.Formatter.expression_format) @@
      let%bind (decl_list,state,env) = match init_file with
        | Some init_file ->
          let%bind typed_prg,state = Compile.Utils.type_file init_file syntax Env in
          let%bind mini_c_prg      = Compile.Of_typed.compile typed_prg in
          let      env             = Ast_typed.program_environment Environment.default typed_prg in
          ok (mini_c_prg,state,env)
        | None -> ok ([],Typer.Solver.initial_state,Environment.default) in

      let%bind (typed_exp,_)  = Compile.Utils.type_expression init_file syntax expression env state in
      let%bind mini_c_exp     = Compile.Of_typed.compile_expression typed_exp in
      let%bind compiled_exp   = Compile.Of_mini_c.aggregate_and_compile_expression decl_list mini_c_exp in
      let%bind options        = Run.make_dry_run_options {predecessor_timestamp ; amount ; balance ; sender ; source } in
      let%bind runres         = Run.run_expression ~options compiled_exp.expr compiled_exp.expr_ty in
      Decompile.Of_michelson.decompile_expression typed_exp.type_expression runres
  in
  let term =
    Term.(const f $ expression "EXPRESSION" 0 $ init_file $ syntax $ amount $ balance $ sender $ source $ predecessor_timestamp $ display_format $ brief) in
  let cmdname = "interpret" in
  let doc = "Subcommand: Interpret the expression in the context initialized by the provided source file." in
  (Term.ret term , Term.info ~doc cmdname)

let temp_ligo_interpreter =
  let f source_file syntax display_format brief=
    return_result ~display_format ~brief (Ligo_interpreter.Formatter.program_format) @@
      let%bind typed,_    = Compile.Utils.type_file source_file syntax Env in
      Compile.Of_typed.some_interpret typed
  in
  let term =
    Term.(const f $ source_file 0 $ syntax $ display_format $brief) in
  let cmdname = "ligo-interpret" in
  let doc = "Subcommand: (temporary / dev only) uses LIGO interpret." in
  (Term.ret term , Term.info ~doc cmdname)

let compile_storage =
  let f source_file entry_point expression syntax amount balance sender source predecessor_timestamp display_format michelson_format output_file brief =
    return_result ~output_file ~display_format ~brief (Tezos_utils.Michelson.michelson_format michelson_format) @@
      let%bind typed_prg,state = Compile.Utils.type_file source_file syntax (Contract entry_point) in
      let%bind mini_c_prg      = Compile.Of_typed.compile typed_prg in
      let%bind michelson_prg   = Compile.Of_mini_c.aggregate_and_compile_contract mini_c_prg entry_point in
      let      env             = Ast_typed.program_environment Environment.default typed_prg in
      let%bind (_contract: Tezos_utils.Michelson.michelson) =
        (* fails if the given entry point is not a valid contract *)
        Compile.Of_michelson.build_contract michelson_prg in

      let%bind (typed_param,_)  = Compile.Utils.type_expression (Some source_file) syntax expression env state in
      let%bind mini_c_param     = Compile.Of_typed.compile_expression typed_param in
      let%bind compiled_param   = Compile.Of_mini_c.aggregate_and_compile_expression mini_c_prg mini_c_param in
      let%bind ()               = Compile.Of_typed.assert_equal_contract_type Check_storage entry_point typed_prg typed_param in
      let%bind ()               = Compile.Of_michelson.assert_equal_contract_type Check_storage michelson_prg compiled_param in
      let%bind options          = Run.make_dry_run_options {predecessor_timestamp ; amount ; balance ; sender ; source } in
      Run.evaluate_expression ~options compiled_param.expr compiled_param.expr_ty in
  let term =
    Term.(const f $ source_file 0 $ entry_point 1 $ expression "STORAGE" 2 $ syntax $ amount $ balance $ sender $ source $ predecessor_timestamp $ display_format $ michelson_code_format $ output_file $ brief) in
  let cmdname = "compile-storage" in
  let doc = "Subcommand: Compile an initial storage in ligo syntax to a Michelson expression. The resulting Michelson expression can be passed as an argument in a transaction which originates a contract." in
  (Term.ret term , Term.info ~doc cmdname)

let dry_run =
  let f source_file entry_point storage input amount balance sender source predecessor_timestamp syntax display_format brief =
    return_result ~display_format ~brief (Decompile.Formatter.expression_format) @@
      let%bind typed_prg,state = Compile.Utils.type_file source_file syntax (Contract entry_point) in
      let      env             = Ast_typed.program_environment Environment.default typed_prg in
      let%bind mini_c_prg      = Compile.Of_typed.compile typed_prg in
      let%bind michelson_prg   = Compile.Of_mini_c.aggregate_and_compile_contract mini_c_prg entry_point in
      let%bind (_contract: Tezos_utils.Michelson.michelson) =
        (* fails if the given entry point is not a valid contract *)
        Compile.Of_michelson.build_contract michelson_prg in

      let%bind compiled_params   = Compile.Utils.compile_storage storage input source_file syntax env state mini_c_prg in
      let%bind args_michelson    = Run.evaluate_expression compiled_params.expr compiled_params.expr_ty in

      let%bind options           = Run.make_dry_run_options {predecessor_timestamp ; amount ; balance ; sender ; source } in
      let%bind runres  = Run.run_contract ~options michelson_prg.expr michelson_prg.expr_ty args_michelson in
      Decompile.Of_michelson.decompile_typed_program_entry_function_result typed_prg entry_point runres
    in
  let term =
    Term.(const f $ source_file 0 $ entry_point 1 $ expression "PARAMETER" 2 $ expression "STORAGE" 3 $ amount $ balance $ sender $ source $ predecessor_timestamp $ syntax $ display_format $ brief) in
  let cmdname = "dry-run" in
  let doc = "Subcommand: Run a smart-contract with the given storage and input." in
  (Term.ret term , Term.info ~doc cmdname)

let run_function =
  let f source_file entry_point parameter amount balance sender source predecessor_timestamp syntax display_format brief =
    return_result ~display_format ~brief (Decompile.Formatter.expression_format) @@
      let%bind typed_prg,state = Compile.Utils.type_file source_file syntax Env in
      let      env             = Ast_typed.program_environment Environment.default typed_prg in
      let%bind mini_c_prg      = Compile.Of_typed.compile typed_prg in


      let%bind v_syntax         = Helpers.syntax_to_variant (Syntax_name syntax) (Some source_file) in
      let%bind imperative_param = Compile.Of_source.compile_expression v_syntax parameter in
      let%bind sugar_param      = Compile.Of_imperative.compile_expression imperative_param in
      let%bind core_param       = Compile.Of_sugar.compile_expression sugar_param in
      let%bind app              = Compile.Of_core.apply entry_point core_param in
      let%bind (typed_app,_)    = Compile.Of_core.compile_expression ~env ~state app in
      let%bind compiled_applied = Compile.Of_typed.compile_expression typed_app in

      let%bind michelson        = Compile.Of_mini_c.aggregate_and_compile_expression mini_c_prg compiled_applied in
      let%bind options          = Run.make_dry_run_options {predecessor_timestamp ; amount ; balance ; sender ; source } in
      let%bind runres           = Run.run_expression ~options michelson.expr michelson.expr_ty in
      Decompile.Of_michelson.decompile_typed_program_entry_function_result typed_prg entry_point runres
    in
  let term =
    Term.(const f $ source_file 0 $ entry_point 1 $ expression "PARAMETER" 2 $ amount $ balance $ sender $ source $ predecessor_timestamp $ syntax $ display_format $ brief) in
  let cmdname = "run-function" in
  let doc = "Subcommand: Run a function with the given parameter." in
  (Term.ret term , Term.info ~doc cmdname)

let evaluate_value =
  let f source_file entry_point amount balance sender source predecessor_timestamp syntax display_format brief =
    return_result ~display_format ~brief Decompile.Formatter.expression_format @@
      let%bind typed_prg,_ = Compile.Utils.type_file source_file syntax Env in
      let%bind mini_c      = Compile.Of_typed.compile typed_prg in
      let%bind (exp,_)     = trace_option Main_errors.entrypoint_not_found @@ Mini_c.get_entry mini_c entry_point in
      let%bind compiled    = Compile.Of_mini_c.aggregate_and_compile_expression mini_c exp in
      let%bind options     = Run.make_dry_run_options {predecessor_timestamp ; amount ; balance ; sender ; source } in
      let%bind runres      = Run.run_expression ~options compiled.expr compiled.expr_ty in
      Decompile.Of_michelson.decompile_typed_program_entry_expression_result typed_prg entry_point runres
    in
  let term =
    Term.(const f $ source_file 0 $ entry_point 1 $ amount $ balance $ sender $ source $ predecessor_timestamp $ syntax $ display_format $ brief) in
  let cmdname = "evaluate-value" in
  let doc = "Subcommand: Evaluate a given definition." in
  (Term.ret term , Term.info ~doc cmdname)

let compile_expression =
  let f expression syntax display_format michelson_format brief =
    return_result ~display_format ~brief (Tezos_utils.Michelson.michelson_format michelson_format) @@
      let env = Environment.default in
      let state = Typer.Solver.initial_state in
      let%bind compiled_exp  = Compile.Utils.compile_expression None syntax expression env state in
      Run.evaluate_expression compiled_exp.expr compiled_exp.expr_ty
    in
  let term =
    Term.(const f $ expression "" 1 $ req_syntax 0 $ display_format $ michelson_code_format $ brief) in
  let cmdname = "compile-expression" in
  let doc = "Subcommand: Compile to a michelson value." in
  (Term.ret term , Term.info ~doc cmdname)

let dump_changelog =
  let f display_format brief =
    let value = [%blob "../../CHANGELOG.md"] in
    let format = Formatter.changelog_format in
    toplevel ~display_format ~brief (Display.Displayable {value ; format}) (ok value) in
  let term =
    Term.(const f $ display_format $ brief) in
  let cmdname = "changelog" in
  let doc = "Dump the LIGO changelog to stdout." in
  (Term.ret term , Term.info ~doc cmdname)

let list_declarations =
  let f source_file syntax display_format brief =
    return_result ~display_format ~brief Formatter.declarations_format @@
        let%bind core_prg     = Compile.Utils.to_core source_file syntax in
        let declarations = Compile.Of_core.list_declarations core_prg in
        ok (source_file, declarations)
  in
  let term =
    Term.(const f $ source_file 0 $ syntax $ display_format $ brief) in
  let cmdname = "list-declarations" in
  let doc = "Subcommand: List all the top-level declarations." in
  (Term.ret term , Term.info ~doc cmdname)

let transpile_contract =
  let f source_file new_syntax syntax display_format brief =
    return_result ~display_format ~brief (Parser.Formatter.ppx_format) @@
      let%bind core       = Compile.Utils.to_core source_file syntax in
      let%bind sugar      = Decompile.Of_core.decompile core in
      let%bind imperative = Decompile.Of_sugar.decompile sugar in
      let%bind buffer     = Decompile.Of_imperative.decompile imperative (Syntax_name new_syntax) in
      ok @@ buffer
  in
  let term =
    Term.(const f $ source_file 0 $ req_syntax 1 $ syntax $ display_format $ brief) in
  let cmdname = "transpile-contract" in
  let doc = "Subcommand: Transpile a contract to another syntax." in
  (Term.ret term , Term.info ~doc cmdname)

let transpile_expression =
  let f expression new_syntax syntax display_format brief =
    return_result ~display_format ~brief (Parser.Formatter.ppx_format) @@
      let%bind v_syntax   = Helpers.syntax_to_variant (Syntax_name syntax) None in
      let%bind n_syntax   = Decompile.Helpers.syntax_to_variant (Syntax_name new_syntax) None in
      let%bind imperative = Compile.Of_source.compile_expression v_syntax expression in
      let%bind sugar      = Compile.Of_imperative.compile_expression imperative in
      let%bind core       = Compile.Of_sugar.compile_expression sugar in
      let%bind sugar      = Decompile.Of_core.decompile_expression core in
      let%bind imperative = Decompile.Of_sugar.decompile_expression sugar in
      let%bind buffer     = Decompile.Of_imperative.decompile_expression imperative n_syntax in
      ok @@ buffer
  in
  let term =
    Term.(const f $ expression "" 1  $ req_syntax 2 $ req_syntax 0 $ display_format $ brief) in
  let cmdname = "transpile-expression" in
  let doc = "Subcommand: Transpile an expression to another syntax." in
  (Term.ret term , Term.info ~doc cmdname)


let get_scope =
  let f source_file syntax display_format with_types brief =
    return_result ~display_format ~brief Ligo.Scopes.Formatter.scope_format @@
    Ligo.Scopes.scopes ~with_types source_file syntax
  in
  let term =
    Term.(const f $ source_file 0 $ syntax $ display_format $ with_types $ brief) in
  let cmdname = "get-scope" in
  let doc = "Subcommand: Return the JSON encoded environment for a given file." in
  (Term.ret term , Term.info ~doc cmdname)

let run ?argv () =
  Term.eval_choice ?argv main [
    temp_ligo_interpreter ;
    compile_file ;
    measure_contract ;
    compile_parameter ;
    compile_storage ;
    compile_expression ;
    transpile_contract ;
    transpile_expression ;
    interpret ;
    dry_run ;
    run_function ;
    evaluate_value ;
    dump_changelog ;
    print_cst ;
    print_ast ;
    print_ast_sugar ;
    print_ast_core ;
    print_ast_typed ;
    print_mini_c ;
    list_declarations ;
    preprocess;
    pretty_print;
    get_scope;
  ]

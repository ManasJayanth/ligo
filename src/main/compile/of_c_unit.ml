open Helpers

type c_unit = Buffer.t

let compile ~raise ~meta c_unit (source_filename:string) : Ast_imperative.module_  =
  parse_and_abstract ~raise ~meta c_unit source_filename

let compile_expression ~raise = parse_and_abstract_expression ~raise

let compile_string ~raise : meta:meta -> c_unit -> Ast_imperative.module_  =
    fun ~meta c_unit ->
  parse_and_abstract_string ~raise meta.syntax c_unit

let compile_contract_input ~raise : meta:meta -> c_unit -> c_unit -> Ast_imperative.expression  =
    fun ~meta storage parameter ->
  let (storage,parameter) = Simple_utils.Pair.map ~f:(compile_expression ~raise ~meta) (storage,parameter) in
  Ast_imperative.e_pair storage parameter

let pretty_print_cst = pretty_print_cst

let pretty_print = pretty_print

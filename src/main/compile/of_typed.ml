open Simple_utils.Trace
open Ast_typed
open Aggregation
open Main_errors

module Var = Simple_utils.Var

module SMap = Map.Make(String)

let compile_program ~raise : Ast_typed.program -> Ast_typed.expression Ast_aggregated.program = fun p ->
  trace ~raise aggregation_tracer @@ Aggregation.compile_program p

let compile_expression_in_context ~raise ~options : Ast_typed.expression -> Ast_typed.expression Ast_aggregated.program -> Ast_aggregated.expression =
  fun exp prg ->
    let x = Aggregation.compile_expression_in_context exp prg in
    trace ~raise self_ast_aggregated_tracer @@ Self_ast_aggregated.all_expression ~options x

let compile_expression ~raise ~options : Ast_typed.expression -> Ast_aggregated.expression = fun e ->
  let x = trace ~raise aggregation_tracer @@ compile_expression e in
  trace ~raise self_ast_aggregated_tracer @@ Self_ast_aggregated.all_expression ~options x

let apply_to_entrypoint_contract ~raise ~options : Ast_typed.program -> Ast_typed.expression_variable -> Ast_aggregated.expression =
    fun prg entrypoint ->
  let aggregated_prg = compile_program ~raise prg in
  let Self_ast_typed.Helpers.{parameter=p_ty ; storage=s_ty} =
    trace ~raise self_ast_typed_tracer @@ Self_ast_typed.Helpers.fetch_contract_type entrypoint prg
  in
  let ty = t_arrow (t_pair p_ty s_ty) (t_pair (t_list (t_operation ())) s_ty) () in
  let var_ep = Ast_typed.(e_a_variable entrypoint ty) in
  compile_expression_in_context ~raise ~options var_ep aggregated_prg

let apply_to_entrypoint ~raise ~options : Ast_typed.program -> string -> Ast_aggregated.expression =
    fun prg entrypoint ->
  let aggregated_prg = compile_program ~raise prg in
  let v = Ast_typed.ValueVar.of_input_var entrypoint in
  let ty, _ =
    trace ~raise self_ast_typed_tracer @@ Self_ast_typed.Helpers.fetch_entry_type entrypoint prg in
  let var_ep = Ast_typed.(e_a_variable v ty) in
  compile_expression_in_context ~raise ~options var_ep aggregated_prg

let assert_equal_contract_type ~raise : Simple_utils.Runned_result.check_type -> Ast_typed.expression_variable -> Ast_typed.program -> Ast_typed.expression -> unit  =
    fun c entry contract param ->
  let entry_point = trace_option ~raise main_entrypoint_not_found (Ast_typed.get_entry contract entry) in
  trace ~raise (check_typed_arguments_tracer c) (
    fun ~raise ->
    match entry_point.type_expression.type_content with
    | T_arrow {type1=args;type2=_} -> (
        match args.type_content with
        | T_record m when LMap.cardinal m.content = 2 -> (
          let {associated_type=param_exp;_} = LMap.find (Label "0") m.content in
          let {associated_type=storage_exp;_} = LMap.find (Label "1") m.content in
            match c with
            | Check_parameter -> trace ~raise checking_tracer @@ Checking.assert_type_expression_eq entry_point.location (param_exp, param.type_expression)
            | Check_storage   -> trace ~raise checking_tracer @@ Checking.assert_type_expression_eq entry_point.location (storage_exp, param.type_expression)
        )
        | _ -> raise.error @@ main_entrypoint_not_a_function )
    | _ -> raise.error @@ main_entrypoint_not_a_function
  )

let apply_to_entrypoint_view ~raise ~options : Ast_typed.program -> Ast_aggregated.expression =
  fun prg ->
    let views_info = Ast_typed.Helpers.fetch_views_in_program prg in
    let aux : int -> _ -> (label * expression) = fun i (view_ty,view_binder) ->
      let (a_ty , s_ty , r_ty) =
        (* at this point the self-pass on views has been applied, we assume the types are correct *)
        trace_option ~raise main_unknown @@ Ast_typed.get_view_form view_ty in
      let ty = t_arrow (t_pair a_ty s_ty) r_ty () in
      Ast_typed.Label (string_of_int i), Ast_typed.(e_a_variable view_binder.var ty)
    in
    let tuple_view = Ast_typed.ez_e_a_record ~layout:L_comb (List.mapi ~f:aux views_info) in
    let aggregated_prg = compile_program ~raise prg in
    compile_expression_in_context ~raise ~options tuple_view aggregated_prg

let list_declarations (m : Ast_typed.module_) : expression_variable list =
  List.fold_left
    ~f:(fun prev el ->
      let open Simple_utils.Location in
      match el.wrap_content with
      | Declaration_constant {binder;attr;_} when attr.public -> binder.var::prev
      | _ -> prev)
    ~init:[] m

let list_type_declarations (m : Ast_typed.module_) : type_variable list =
  List.fold_left
    ~f:(fun prev el ->
      let open Simple_utils.Location in
      match el.wrap_content with
      | Declaration_type {type_binder;type_attr;_} when type_attr.public -> type_binder::prev
      | _ -> prev)
    ~init:[] m

let list_mod_declarations (m : Ast_typed.module_) : module_variable list =
  List.fold_left
    ~f:(fun prev el ->
      let open Simple_utils.Location in
      match el.wrap_content with
      | Declaration_module {module_binder;module_attr;_} when module_attr.public -> module_binder::prev
      | _ -> prev)
    ~init:[] m

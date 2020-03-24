open Ast_typed
open Trace

module Errors = struct
  let recursive_call_is_only_allowed_as_the_last_operation name loc () =
    let title = (thunk ("Recursion must be achieved through tail-calls only")) in
    let message () = "" in
    let data = [
      ("function" , fun () -> Format.asprintf "%a" PP.expression_variable name);
      ("location" , fun () -> Format.asprintf "%a" Location.pp loc)
    ] in
    error ~data title message ()
end
open Errors

let rec check_recursive_call : expression_variable -> bool -> expression -> unit result = fun n final_path e ->
  match e.expression_content with
  | E_literal _   -> ok ()
  | E_constant c  ->
    let%bind _ = bind_map_list (check_recursive_call n false) c.arguments in
    ok ()
  | E_variable v  -> (
    let%bind _ = trace_strong (recursive_call_is_only_allowed_as_the_last_operation n e.location) @@
    Assert.assert_true (final_path || n <> v) in
    ok ()
    )
  | E_application {lamb;args} ->
    let%bind _ = check_recursive_call n final_path lamb in
    let%bind _ = check_recursive_call n false args in
    ok ()
  | E_lambda {result;_} ->
    let%bind _ = check_recursive_call n final_path result in
    ok ()
  | E_recursive { fun_name; lambda} ->
    let%bind _ = check_recursive_call fun_name true lambda.result in
    ok ()
  | E_let_in {rhs;let_result;_} ->
    let%bind _ = check_recursive_call n false rhs in
    let%bind _ = check_recursive_call n final_path let_result in
    ok ()
  | E_constructor {element;_} ->
    let%bind _ = check_recursive_call n false element in
    ok ()
  | E_matching {matchee;cases} ->
    let%bind _ = check_recursive_call n false matchee in
    let%bind _ = check_recursive_call_in_matching n final_path cases in
    ok ()
  | E_record elm -> 
    let es = LMap.to_list elm in
    let%bind _ = bind_map_list (check_recursive_call n false) es in
    ok ()
  | E_record_accessor {expr;_} ->
    let%bind _ = check_recursive_call n false expr in
    ok ()
  | E_record_update {record;update;_} ->
    let%bind _ = check_recursive_call n false record in
    let%bind _ = check_recursive_call n false update in
    ok ()
  | E_map eel | E_big_map eel->
    let aux (e1,e2) = 
      let%bind _ = check_recursive_call n false e1 in
      let%bind _ = check_recursive_call n false e2 in
      ok ()
    in
    let%bind _ = bind_map_list aux eel in
    ok ()
  | E_list el | E_set el ->
    let%bind _ = bind_map_list (check_recursive_call n false) el in
    ok ()
  | E_look_up (e1,e2) ->
    let%bind _ = check_recursive_call n false e1 in
    let%bind _ = check_recursive_call n false e2 in
    ok ()

and check_recursive_call_in_matching = fun n final_path c ->
  match c with
  | Match_bool {match_true;match_false} ->
    let%bind _ = check_recursive_call n final_path match_true in
    let%bind _ = check_recursive_call n final_path match_false in
    ok ()
  | Match_list {match_nil;match_cons=(_,_,e,_)} ->
    let%bind _ = check_recursive_call n final_path match_nil in
    let%bind _ = check_recursive_call n final_path e in
    ok ()
  | Match_option {match_none; match_some=(_,e,_)} ->
    let%bind _ = check_recursive_call n final_path match_none in
    let%bind _ = check_recursive_call n final_path e in
    ok ()
  | Match_tuple ((_,e),_) ->
    let%bind _ = check_recursive_call n final_path e in
    ok ()
  | Match_variant (l,_) ->
    let aux (_,e) =
      let%bind _ = check_recursive_call n final_path e in
      ok ()
    in
    let%bind _ = bind_map_list aux l in
    ok ()
    

let peephole_expression : expression -> expression result = fun e ->
  let return expression_content = ok { e with expression_content } in
  match e.expression_content with
  | E_recursive {fun_name; lambda} as e-> (
    let%bind _ = check_recursive_call fun_name true lambda.result in
    return e
    )
  | e -> return e
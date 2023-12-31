(*
  This file is used throughout the pipeline. Its idea is to add a unique place
  that you have to modify when you add a new operator/constant to the language.

  This file mirrors the LIGO pipeline, starting with Simplify, then Typer and
  ending with Stacking. Usually, when adding a new operator, you'll have to add
  a new constructor at all those places.
*)

module Ligo_string = Simple_utils.Ligo_string

module Tree_abstraction = struct
  let pseudo_module_to_string (c : Ligo_prim.Constant.constant') =
    match c with
    (* Operator module *)
    | C_NEG -> "Operator.neg"
    | C_ADD -> "Operator.add"
    | C_SUB -> "Operator.sub"
    | C_SUB_MUTEZ -> "Operator.sub_mutez"
    | C_POLYMORPHIC_SUB -> "Operator.sub"
    | C_MUL -> "Operator.times"
    | C_DIV -> "Operator.div"
    | C_MOD -> "Operator.modulus"
    | C_EQ -> "Operator.eq"
    | C_NOT -> "Operator.not"
    | C_AND -> "Operator.and"
    | C_OR -> "Operator.or"
    | C_GT -> "Operator.gt"
    | C_GE -> "Operator.ge"
    | C_LT -> "Operator.lt"
    | C_LE -> "Operator.le"
    | C_CONS -> "Operator.cons"
    | C_NEQ -> "Operator.neq"
    (* Map module *)
    | C_MAP_ADD -> "Map.add"
    | C_MAP_REMOVE -> "Map.remove"
    (* Bitwise module *)
    | C_XOR -> "Bitwise.xor"
    | C_LSL -> "Bitwise.shift_left"
    | C_LSR -> "Bitwise.shift_right"
    | _ as c ->
      failwith
      @@ Format.asprintf "Constant not handled : %a" Ligo_prim.Constant.pp_constant' c
end

module Michelson = struct
  (*
    Most constants pass through the Spilling unchanged. So they need to be
    compiled down to Michelson. This is the last step.

    When compiling the constant, we need to provide its arity (through the type
    predicate, defined in `Helpers.Michelson`, and its michelson code.
    In the case of an n-ary constant, we assume that the stack has the form:
    `x1 :: x2 :: x3 ... :: xn :: _`.

    This step requires knowledge of Michelson. Knowledge of
    `Tezos_utils.Michelson` will help too, so that no Michelson has to actually
    be written by hand.
   *)
  type protocol_type = Environment.Protocols.t

  include Helpers.Michelson
  open Tezos_utils.Michelson
  open Ligo_prim.Constant

  let get_operators (protocol_version : protocol_type) c : predicate option =
    match c, protocol_version with
    | C_ADD, _ -> Some (simple_binary @@ prim "ADD")
    | C_SUB, _ -> Some (simple_binary @@ prim "SUB")
    | C_SUB_MUTEZ, _ -> Some (simple_binary @@ prim "SUB_MUTEZ")
    | C_MUL, _ -> Some (simple_binary @@ prim "MUL")
    | C_DIV, _ ->
      Some
        (simple_binary
        @@ seq [ prim "EDIV"; i_assert_some_msg (i_push_string "DIV by 0"); i_car ])
    | C_MOD, _ ->
      Some
        (simple_binary
        @@ seq [ prim "EDIV"; i_assert_some_msg (i_push_string "MOD by 0"); i_cdr ])
    | C_NEG, _ -> Some (simple_unary @@ prim "NEG")
    | C_OR, _ -> Some (simple_binary @@ prim "OR")
    | C_AND, _ -> Some (simple_binary @@ prim "AND")
    | C_XOR, _ -> Some (simple_binary @@ prim "XOR")
    | C_LOR, _ -> Some (simple_binary @@ prim "OR")
    | C_LAND, _ -> Some (simple_binary @@ prim "AND")
    | C_LXOR, _ -> Some (simple_binary @@ prim "XOR")
    | C_LSL, _ -> Some (simple_binary @@ prim "LSL")
    | C_LSR, _ -> Some (simple_binary @@ prim "LSR")
    | C_NOT, _ -> Some (simple_unary @@ prim "NOT")
    | C_PAIR, _ -> Some (simple_binary @@ prim "PAIR")
    | C_CAR, _ -> Some (simple_unary @@ prim "CAR")
    | C_CDR, _ -> Some (simple_unary @@ prim "CDR")
    | C_TRUE, _ -> Some (simple_constant @@ i_push (prim "bool") (prim "True"))
    | C_FALSE, _ -> Some (simple_constant @@ i_push (prim "bool") (prim "False"))
    | C_EQ, _ -> Some (simple_binary @@ seq [ prim "COMPARE"; prim "EQ" ])
    | C_NEQ, _ -> Some (simple_binary @@ seq [ prim "COMPARE"; prim "NEQ" ])
    | C_LT, _ -> Some (simple_binary @@ seq [ prim "COMPARE"; prim "LT" ])
    | C_LE, _ -> Some (simple_binary @@ seq [ prim "COMPARE"; prim "LE" ])
    | C_GT, _ -> Some (simple_binary @@ seq [ prim "COMPARE"; prim "GT" ])
    | C_GE, _ -> Some (simple_binary @@ seq [ prim "COMPARE"; prim "GE" ])
    | C_UPDATE, _ -> Some (simple_ternary @@ prim "UPDATE")
    | C_SOME, _ -> Some (simple_unary @@ prim "SOME")
    | C_MAP_FIND, _ ->
      Some
        (simple_binary @@ seq [ prim "GET"; i_assert_some_msg (i_push_string "MAP FIND") ])
    | C_MAP_FIND_OPT, _ -> Some (simple_binary @@ prim "GET")
    | C_MAP_ADD, _ -> Some (simple_ternary @@ seq [ dip i_some; prim "UPDATE" ])
    | C_MAP_UPDATE, _ -> Some (simple_ternary @@ prim "UPDATE")
    | (C_MAP_GET_AND_UPDATE | C_BIG_MAP_GET_AND_UPDATE), _ ->
      Some (simple_ternary @@ seq [ prim "GET_AND_UPDATE"; prim "PAIR" ])
    | C_CONS, _ -> Some (simple_binary @@ prim "CONS")
    | C_UNIT, _ -> Some (simple_constant @@ prim "UNIT")
    | C_SET_MEM, _ -> Some (simple_binary @@ prim "MEM")
    | C_SET_ADD, _ ->
      Some
        (simple_binary @@ seq [ dip (i_push (prim "bool") (prim "True")); prim "UPDATE" ])
    | C_SET_REMOVE, _ ->
      Some
        (simple_binary @@ seq [ dip (i_push (prim "bool") (prim "False")); prim "UPDATE" ])
    | C_SET_UPDATE, _ -> Some (simple_ternary @@ prim "UPDATE")
    | C_CONCAT, _ -> Some (simple_binary @@ prim "CONCAT")
    | C_CONCATS, _ -> Some (simple_unary @@ prim "CONCAT")
    | C_SLICE, _ ->
      Some
        (simple_ternary @@ seq [ prim "SLICE"; i_assert_some_msg (i_push_string "SLICE") ])
    | C_NONE, _ -> Some (trivial_special "NONE")
    | C_NIL, _ -> Some (trivial_special "NIL")
    | C_LOOP_CONTINUE, _ -> Some (trivial_special "LEFT")
    | C_LOOP_STOP, _ -> Some (trivial_special "RIGHT")
    | C_LIST_EMPTY, _ -> Some (trivial_special "NIL")
    | C_SET_EMPTY, _ -> Some (trivial_special "EMPTY_SET")
    | C_MAP_EMPTY, _ -> Some (trivial_special "EMPTY_MAP")
    | C_BIG_MAP_EMPTY, _ -> Some (trivial_special "EMPTY_BIG_MAP")
    | C_LIST_SIZE, _ -> Some (trivial_special "SIZE")
    | C_SET_SIZE, _ -> Some (trivial_special "SIZE")
    | C_MAP_SIZE, _ -> Some (trivial_special "SIZE")
    | C_SIZE, _ -> Some (trivial_special "SIZE")
    | C_MAP_MEM, _ -> Some (simple_binary @@ prim "MEM")
    | C_MAP_REMOVE, _ ->
      Some (special (fun with_args -> seq [ dip (with_args "NONE"); prim "UPDATE" ]))
    | C_LEFT, _ -> Some (trivial_special "LEFT")
    | C_RIGHT, _ -> Some (trivial_special "RIGHT")
    | C_CREATE_CONTRACT, _ ->
      Some (special (fun with_args -> seq [ with_args "CREATE_CONTRACT"; i_pair ]))
    | C_GLOBAL_CONSTANT, _ -> Some (special (fun with_args -> with_args "PUSH"))
    | _ -> None
end

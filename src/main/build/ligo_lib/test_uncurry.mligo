type test_exec_error_balance_too_low =
  { contract_too_low : address ; contract_balance : tez ; spend_request : tez }

type test_exec_error =
  | Rejected of michelson_program * address
  | Balance_too_low of test_exec_error_balance_too_low
  | Other of string

type test_exec_result = Success of nat | Fail of test_exec_error

type test_baker_policy =
  | By_round of int
  | By_account of address
  | Excluding of address list

module Test = struct
  let to_contract (type p s) (t : (p, s) typed_address) : p contract = [%external "TEST_TO_CONTRACT"] t
  let originate_from_file ((fn, e, v, s, t) : string * string * string list * michelson_program * tez) : address * michelson_program * int = [%external "TEST_ORIGINATE_FROM_FILE"] fn e v s t
  let originate (type p s) ((f, s, t) : (p * s -> operation list * s) * s * tez) : ((p, s) typed_address * michelson_program * int) = [%external "TEST_ORIGINATE"] f s t
  let set_source (a : address) : unit = [%external "TEST_SET_SOURCE"] a
  let transfer ((a, s, t) : address * michelson_program * tez) : test_exec_result = [%external "TEST_EXTERNAL_CALL_TO_ADDRESS"] a s t
  let transfer_exn ((a, s, t) : address * michelson_program * tez) : nat = [%external "TEST_EXTERNAL_CALL_TO_ADDRESS_EXN"] a s t
  let get_storage_of_address (a : address) : michelson_program = [%external "TEST_GET_STORAGE_OF_ADDRESS"] a
  let get_balance (a : address) : tez = [%external "TEST_GET_BALANCE"] a
  let log (type a) (v : a) : unit = [%external "TEST_LOG"] v
  let reset_state ((n, l) : nat * tez list) : unit = [%external "TEST_STATE_RESET"] n l
  let get_voting_power (kh : key_hash) : nat = [%external "TEST_GET_VOTING_POWER"] kh
  [@thunk]
    let get_total_voting_power : nat = [%external "TEST_GET_TOTAL_VOTING_POWER"]
  let bootstrap_contract (type p s) ((f, s, t) : (p * s -> operation list * s) * s * tez) : unit = [%external "TEST_BOOTSTRAP_CONTRACT"] f s t
  let nth_bootstrap_contract (i : nat) : address = [%external "TEST_NTH_BOOTSTRAP_CONTRACT"] i
  let nth_bootstrap_account (i : int) : address = [%external "TEST_GET_NTH_BS"] i
  let nth_bootstrap_typed_address (type a b) (n : nat) : (a, b) typed_address = [%external "TEST_NTH_BOOTSTRAP_TYPED_ADDRESS"] n
  let last_originations (u : unit) : (address, address list) map = [%external "TEST_LAST_ORIGINATIONS"] u
  let mutate_value (type a) ((n, v) : nat * a) : (a * mutation) option = [%external "TEST_MUTATE_VALUE"] n v
  let save_mutation ((s, m) : string * mutation) : string option = [%external "TEST_SAVE_MUTATION"] s m
  let mutation_test (type a b) ((v, f) : a * (a -> b)) : (b * mutation) option = [%external "TEST_MUTATION_TEST"] v f
  let mutation_test_all (type a b) ((v, f) : a * (a -> b)) : (b * mutation) list = [%external "TEST_MUTATION_TEST_ALL"] v f
  let run (type a b) ((f, v) : (a -> b) * a) : michelson_program = [%external "TEST_RUN"] f v
  let decompile (type a) (m : michelson_program) : a = [%external "TEST_DECOMPILE"] m
  let random (type a) (u : unit) : a = [%external "TEST_RANDOM"] u
  let add_account ((s, k) : string * key) : unit = [%external "TEST_ADD_ACCOUNT"] s k
  let new_account (u : unit) : string * key = [%external "TEST_NEW_ACCOUNT"] u
  let baker_account ((p, o) : (string * key) * tez option) : unit = [%external "TEST_BAKER_ACCOUNT"] p o
  let bake_until_n_cycle_end (n : nat) : unit = [%external "TEST_BAKE_UNTIL_N_CYCLE_END"] n
  let register_delegate (kh : key_hash) : unit = [%external "TEST_REGISTER_DELEGATE"] kh
  let register_constant (m : michelson_program) : string = [%external "TEST_REGISTER_CONSTANT"] m
  let cast_address (type a b) (a : address) : (a, b) typed_address = [%external "TEST_CAST_ADDRESS"] a
  let to_typed_address (type a b) (c : a contract) : (a, b) typed_address = [%external "TEST_TO_TYPED_ADDRESS"] c
  let to_entrypoint (type a b c) ((s, t) : string * (a, b) typed_address) : c contract = [%external "TEST_TO_ENTRYPOINT"] s t
  let set_big_map (type a b) ((i, m) : int * (a, b) big_map) : unit = [%external "TEST_SET_BIG_MAP"] i m
  let create_chest ((b, n) : bytes * nat) : chest * chest_key = [%external "TEST_CREATE_CHEST"] b n
  let create_chest_key ((c, n) : chest * nat) : chest_key = [%external "TEST_CREATE_CHEST_KEY"] c n
  let constant_to_michelson_program (s : string) : michelson_program = [%external "TEST_CONSTANT_TO_MICHELSON"] s
  let restore_context (u : unit) : unit = [%external "TEST_POP_CONTEXT"] u
  let save_context (u : unit) : unit = [%external "TEST_PUSH_CONTEXT"] u
  let eval (type a) (x : a) : michelson_program = run ((fun (x : a) -> x), x)
  let compile_value (type a) (x : a) : michelson_program = run ((fun (x : a) -> x), x)
  let get_storage (type p s) (t : (p, s) typed_address) : s =
      let c : p contract = to_contract t in
      let a : address = [%external "ADDRESS"] c in
      let s : michelson_program = get_storage_of_address a in
      let s : s = decompile s in
      s
  let transfer_to_contract (type p) ((c, s, t) : p contract * p * tez) : test_exec_result =
      let a : address = [%external "ADDRESS"] c in
      let s : michelson_program = eval s in
      transfer (a, s, t)
  let transfer_to_contract_exn (type p) ((c, s, t) : p contract * p * tez) : nat =
      let a : address = [%external "ADDRESS"] c in
      let s : michelson_program = eval s in
      transfer_exn (a, s, t)
  let michelson_equal ((m1, m2) : michelson_program * michelson_program) : bool = m1 = m2
  let set_baker (a : address) : unit = [%external "TEST_SET_BAKER"] (By_account a)
end

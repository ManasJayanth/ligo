open Cli_expect

let contract basename = "../../test/contracts/" ^ basename

let%expect_test _ =
  run_ligo_good [ "compile"; "contract"; contract "michelson_pair_tree.mligo" ];
  [%expect
    {|
    File "../../test/contracts/michelson_pair_tree.mligo", line 7, characters 26-31:
      6 | [@entry]
      7 | let main (action : unit) (store : storage) : return =
                                    ^^^^^
      8 |   let foo = (3,(1,2n)) in
    :
    Warning: unused variable "store".
    Hint: replace it by "_store" to prevent this warning.

    File "../../test/contracts/michelson_pair_tree.mligo", line 7, characters 10-16:
      6 | [@entry]
      7 | let main (action : unit) (store : storage) : return =
                    ^^^^^^
      8 |   let foo = (3,(1,2n)) in
    :
    Warning: unused variable "action".
    Hint: replace it by "_action" to prevent this warning.

    { parameter unit ;
      storage (pair (int %three) (pair %four (int %one) (nat %two))) ;
      code { DROP ;
             PUSH nat 2 ;
             PUSH int 1 ;
             PAIR ;
             PUSH int 3 ;
             PAIR ;
             NIL operation ;
             PAIR } } |}]

let%expect_test _ =
  run_ligo_good [ "compile"; "contract"; contract "michelson_pair_tree.jsligo" ];
  [%expect
    {|
    File "../../test/contracts/michelson_pair_tree.jsligo", line 10, characters 28-33:
      9 | @entry
     10 | const main = (action: unit, store: storage): return_ => {
                                      ^^^^^
     11 |   let foo = [3, [1, 2 as nat]];
    :
    Warning: unused variable "store".
    Hint: replace it by "_store" to prevent this warning.

    File "../../test/contracts/michelson_pair_tree.jsligo", line 10, characters 14-20:
      9 | @entry
     10 | const main = (action: unit, store: storage): return_ => {
                        ^^^^^^
     11 |   let foo = [3, [1, 2 as nat]];
    :
    Warning: unused variable "action".
    Hint: replace it by "_action" to prevent this warning.

    { parameter unit ;
      storage (pair (int %three) (pair %four (int %one) (nat %two))) ;
      code { DROP ;
             PUSH nat 2 ;
             PUSH int 1 ;
             PAIR ;
             PUSH int 3 ;
             PAIR ;
             NIL operation ;
             PAIR } } |}]

(*
let%expect_test _ =
  run_ligo_good
    [ "compile"; "contract"; contract "michelson_pair_tree_intermediary.ligo" ];
  [%expect
    {|
    File "../../test/contracts/michelson_pair_tree_intermediary.ligo", line 6, characters 21-27:
      5 |
      6 | function main (const action : unit; const store : storage) : return is {
      7 |   const foo : storage = ("foo",(1,2n)) ;
    :
    Warning: unused variable "action".
    Hint: replace it by "_action" to prevent this warning.

    File "../../test/contracts/michelson_pair_tree_intermediary.ligo", line 6, characters 42-47:
      5 |
      6 | function main (const action : unit; const store : storage) : return is {
      7 |   const foo : storage = ("foo",(1,2n)) ;
    :
    Warning: unused variable "store".
    Hint: replace it by "_store" to prevent this warning.

    { parameter unit ;
      storage (pair (string %three) (int %one) (nat %two)) ;
      code { DROP ;
             PUSH nat 2 ;
             PUSH int 1 ;
             PAIR ;
             PUSH string "foo" ;
             PAIR ;
             NIL operation ;
             PAIR } } |}]
*)

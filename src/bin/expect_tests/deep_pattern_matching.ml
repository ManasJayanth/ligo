open Cli_expect

let bad_test s = (bad_test "")^"/deep_pattern_matching/"^s
let good_test s = (test "")^"/deep_pattern_matching/"^s

(* Negatives *)

(* testing that subtitution is stoping on resursive definitions *)
let%expect_test _ =
  run_ligo_bad [ "print" ; "ast-typed" ; (bad_test "pm_fail17.mligo") ] ;
  [%expect{|
    File "../../test/contracts/negative//deep_pattern_matching/pm_fail17.mligo", line 15, characters 42-43:
     14 |     (* testing that subtitution is stoping on resursive definitions *)
     15 |     let rec a (b : int) : int =let x = fo a in b + 1 in
     16 |     (a 1) + (fo b)

    Invalid type(s)
    Cannot unify int -> int with option (int). |}]

(* wrong type on constructor argument pattern *)
let%expect_test _ =
  run_ligo_bad [ "print" ; "ast-typed" ; (bad_test "pm_fail16.mligo") ] ;
  [%expect{|
    File "../../test/contracts/negative//deep_pattern_matching/pm_fail16.mligo", line 6, characters 4-25:
      5 |   match action with
      6 |   | {one = _ ; three = _} -> 0

    Pattern not of the expected type parameter |}]

(* wrong type on constructor argument pattern *)
let%expect_test _ =
  run_ligo_bad [ "print" ; "ast-typed" ; (bad_test "pm_fail15.mligo") ] ;
  [%expect{|
    File "../../test/contracts/negative//deep_pattern_matching/pm_fail15.mligo", line 8, characters 15-19:
      7 |   match action with
      8 |   | Increment (n, m) -> 0
      9 |   | Reset            -> 0

    Pattern not of the expected type ( int * int * int ) |}]

(* wrong unit pattern in a let destructuring *)
let%expect_test _ =
  run_ligo_bad [ "print" ; "ast-typed" ; (bad_test "pm_fail14.mligo") ] ;
  [%expect{|
    File "../../test/contracts/negative//deep_pattern_matching/pm_fail14.mligo", line 2, characters 11-14:
      1 | let main (_ : unit * unit) : operation list * unit =
      2 |   let () = 42n in
      3 |   (([] : operation list), ())

    Invalid type(s).
    Expected: "nat", but got: "unit". |}]


(* Trying to match on values *)
let%expect_test _ =
  run_ligo_bad [ "print" ; "ast-typed" ; (bad_test "pm_fail10.mligo") ] ;
  [%expect{|
    File "../../test/contracts/negative//deep_pattern_matching/pm_fail10.mligo", line 5, characters 8-9:
      4 |   match x with
      5 |   | One 1 -> 2
      6 |   | Two -> 1

    Invalid pattern.
    Can't match on values. |}]

(* unbound variable *)

let%expect_test _ =
  run_ligo_bad [ "print" ; "ast-typed" ; (bad_test "pm_fail9.mligo") ] ;
  [%expect{|
    File "../../test/contracts/negative//deep_pattern_matching/pm_fail9.mligo", line 6, characters 11-12:
      5 |   | One a -> 2
      6 |   | Two -> a

    Variable "a" not found. |}]

(* wrong patterns type *)
let%expect_test _ =
  run_ligo_bad [ "print" ; "ast-typed" ; (bad_test "pm_fail1.mligo") ] ;
  [%expect{|
    File "../../test/contracts/negative//deep_pattern_matching/pm_fail1.mligo", line 6, characters 10-33:
      5 |   match x with
      6 |   | Nil , {a = a ; b = b ; c = c} -> 1
      7 |   | xs  , Nil -> 2

    Pattern not of the expected type myt |}]

let%expect_test _ =
  run_ligo_bad [ "print" ; "ast-typed" ; (bad_test "pm_fail2.mligo") ] ;
  [%expect{|
    File "../../test/contracts/negative//deep_pattern_matching/pm_fail2.mligo", line 5, characters 11-16:
      4 |   match x with
      5 |   | Nil , (a,b,c) -> 1
      6 |   | xs  , Nil -> 2

    Pattern not of the expected type myt |}]

let%expect_test _ =
  run_ligo_bad [ "print" ; "ast-typed" ; (bad_test "pm_fail5.mligo") ] ;
  [%expect{|
    File "../../test/contracts/negative//deep_pattern_matching/pm_fail5.mligo", line 5, characters 4-15:
      4 |   match x with
      5 |   | Some_fake x -> x
      6 |   | None_fake -> 1

    Pattern not of the expected type option (int) |}]

(* wrong body type *)

let%expect_test _ =
  run_ligo_bad [ "print" ; "ast-typed" ; (bad_test "pm_fail7.mligo") ] ;
  [%expect{|
    File "../../test/contracts/negative//deep_pattern_matching/pm_fail7.mligo", line 6, characters 9-10:
      5 |   | A -> "hey"
      6 |   | B -> 2

    Invalid type(s)
    Cannot unify int with string. |}]

let%expect_test _ =
  run_ligo_bad [ "print" ; "ast-typed" ; (bad_test "pm_fail8.mligo") ] ;
  [%expect{|
    File "../../test/contracts/negative//deep_pattern_matching/pm_fail8.mligo", line 19, characters 22-31:
     18 |         f (b+1)
     19 |       | Cons (a,b) -> "invalid"
     20 |     in

    Invalid type(s)
    Cannot unify string with int. |}]


(* rendundancy detected while compiling the pattern matching *)
let%expect_test _ =
  run_ligo_bad [ "print" ; "ast-typed" ; (bad_test "pm_fail3.mligo") ] ;
  [%expect{|
    File "../../test/contracts/negative//deep_pattern_matching/pm_fail3.mligo", line 6, characters 4-16:
      5 |   | xs , (a,b,c) -> 1
      6 |   | xs , (c,b,a) -> 2

    Error : this match case is unused. |}]

(* anomaly detected in the pattern matching self_ast_typed pass *)

let%expect_test _ =
  run_ligo_bad [ "print" ; "ast-typed" ; (bad_test "pm_fail11.mligo") ] ;
  [%expect{|
    File "../../test/contracts/negative//deep_pattern_matching/pm_fail11.mligo", line 2, character 2 to line 4, character 11:
      1 | let t12 = fun (x : int list) ->
      2 |   match x with
      3 |   | hd::(hd2::tl) -> hd + hd2
      4 |   | [] -> 0

    Error : this pattern-matching is not exhaustive.
    Here are examples of cases that are not matched:
    - _ :: [] |}]

let%expect_test _ =
  run_ligo_bad [ "print" ; "ast-typed" ; (bad_test "pm_fail12.mligo") ] ;
  [%expect{|
    File "../../test/contracts/negative//deep_pattern_matching/pm_fail12.mligo", line 4, character 2 to line 6, character 40:
      3 | let t13 = fun (x:recordi) ->
      4 |   match x with
      5 |   | { a = Some ([]) ; b = (hd::tl) } -> hd
      6 |   | { a = Some (hd::tl) ; b = [] } -> hd

    Error : this pattern-matching is not exhaustive.
    Here are examples of cases that are not matched:
    - {a = None; b = _} |}]

let%expect_test _ =
  run_ligo_bad [ "print" ; "ast-typed" ; (bad_test "pm_fail13.mligo") ] ;
  [%expect{|
    File "../../test/contracts/negative//deep_pattern_matching/pm_fail13.mligo", line 7, characters 5-14:
      6 |    | Increment n -> s +1
      7 |    | Decrement -> s -1
      8 |  in ([] : operation list), stor

    Pattern not of the expected type nat |}]

let%expect_test _ =
  run_ligo_bad [ "print" ; "ast-typed" ; (bad_test "pm_fail4.mligo") ] ;
  [%expect{|
    File "../../test/contracts/negative//deep_pattern_matching/pm_fail4.mligo", line 4, character 2 to line 6, character 18:
      3 | let t = fun (x: myt * myt) ->
      4 |   match x with
      5 |   | Nil , ys  -> 1
      6 |   | xs  , Nil -> 2

    Error : this pattern-matching is not exhaustive.
    Here are examples of cases that are not matched:
    - (Cons (_, _), Cons (_, _)) |}]

(* Positives *)

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t1 (Nil,Nil)" ; "--init-file" ; (good_test "pm_test.mligo") ] ;
  [%expect{| 1 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t1 (Nil,Cons(1,2))" ; "--init-file" ; (good_test "pm_test.mligo") ] ;
  [%expect{| 1 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t1 (Cons(1,2),Nil)" ; "--init-file" ; (good_test "pm_test.mligo") ] ;
  [%expect{| 2 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t1 (Cons(1,2),Cons(3,4))" ; "--init-file" ; (good_test "pm_test.mligo") ] ;
  [%expect{| 10 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t2 Nil Nil" ; "--init-file" ; (good_test "pm_test.mligo") ] ;
  [%expect{| 1 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t2 Nil (Cons (1,2))" ; "--init-file" ; (good_test "pm_test.mligo") ] ;
  [%expect{| 3 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t2 (Cons(1,2)) (Cons(1,2))" ; "--init-file" ; (good_test "pm_test.mligo") ] ;
  [%expect{| 6 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t2 (Cons(1,2)) Nil" ; "--init-file" ; (good_test "pm_test.mligo") ] ;
  [%expect{| 7 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t3 (One (Nil))" ; "--init-file" ; (good_test "pm_test.mligo") ] ;
  [%expect{| 1 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t3 (One (Cons(1,2)))" ; "--init-file" ; (good_test "pm_test.mligo") ] ;
  [%expect{| 3 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t3 (Two {a = 1 ; b = 2n ; c = \"tri\"})" ; "--init-file" ; (good_test "pm_test.mligo") ] ;
  [%expect{| 6 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t2_3 (Cons(1,2)) Nil (One(Nil))" ; "--init-file" ; (good_test "pm_test.mligo") ] ;
  [%expect{| 8 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t4 (One(Nil)) (One (Nil))" ; "--init-file" ; (good_test "pm_test.mligo") ] ;
  [%expect{| 1 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t4 (One(Nil)) (Two {a=1;b=2n;c=\"tri\"})" ; "--init-file" ; (good_test "pm_test.mligo") ] ;
  [%expect{| 2 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t4 (One(Cons(1,2))) (Two {a=1;b=2n;c=\"tri\"})" ; "--init-file" ; (good_test "pm_test.mligo") ] ;
  [%expect{| 3 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t4 (Two {a=0;b=0n;c=\"\"}) (Two {a=1;b=2n;c=\"tri\"})" ; "--init-file" ; (good_test "pm_test.mligo") ] ;
  [%expect{| 4 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t5 1" ; "--init-file" ; (good_test "pm_test.mligo") ] ;
  [%expect{| 1 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t6 42" ; "--init-file" ; (good_test "pm_test.mligo") ] ;
  [%expect{| 2 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t7 (Some 10)" ; "--init-file" ; (good_test "pm_test.mligo") ] ;
  [%expect{| 10 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t7 (None: int option)" ; "--init-file" ; (good_test "pm_test.mligo") ] ;
  [%expect{| 1 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t8 (Some (1,2)) 2" ; "--init-file" ; (good_test "pm_test.mligo") ] ;
  [%expect{| 3 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t8 (None:(int * int) option) 2" ; "--init-file" ; (good_test "pm_test.mligo") ] ;
  [%expect{| 2 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t9 (None:int option) (None:int option)" ; "--init-file" ; (good_test "pm_test.mligo") ] ;
  [%expect{| 1 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t9 (None:int option) (Some 1)" ; "--init-file" ; (good_test "pm_test.mligo") ] ;
  [%expect{| 1 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t9 (Some 1) (None:int option)" ; "--init-file" ; (good_test "pm_test.mligo") ] ;
  [%expect{| 2 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t9 (Some 1) (Some 2)" ; "--init-file" ; (good_test "pm_test.mligo") ] ;
  [%expect{| 3 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t10 (Consi(None:int option)) (Consi(Some 100))" ; "--init-file" ; (good_test "pm_test.mligo") ] ;
  [%expect{| 1 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t11 (Consi(None:int option)) (Consi(Some 100))" ; "--init-file" ; (good_test "pm_test.mligo") ] ;
  [%expect{| 4 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t12 ([]: int list)" ; "--init-file" ; (good_test "pm_test.mligo") ] ;
  [%expect{| 0 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t12 [1]" ; "--init-file" ; (good_test "pm_test.mligo") ] ;
  [%expect{| 1 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t12 [1;2]" ; "--init-file" ; (good_test "pm_test.mligo") ] ;
  [%expect{| 3 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t12 [1;2;3]" ; "--init-file" ; (good_test "pm_test.mligo") ] ;
  [%expect{| 6 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t12 [1;2;3;4]" ; "--init-file" ; (good_test "pm_test.mligo") ] ;
  [%expect{| -1 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t13 none_a some_a" ; "--init-file" ; (good_test "pm_test.mligo") ] ;
  [%expect{| -1 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t13 some_a a_empty_b_not" ; "--init-file" ; (good_test "pm_test.mligo") ] ;
  [%expect{| 111 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t13 some_a b_empty_a_not" ; "--init-file" ; (good_test "pm_test.mligo") ] ;
  [%expect{| 222 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t13 some_a some_a" ; "--init-file" ; (good_test "pm_test.mligo") ] ;
  [%expect{| 4 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "nested_record_pm { a = 1 ; b = E }" ; "--init-file" ; (good_test "pm_test.mligo") ] ;
  [%expect{| 5 |}]

let%expect_test _ =
  run_ligo_good [ "info" ; "measure-contract" ; (good_test "nested_record_sum.mligo") ] ;
  [%expect{| 142 bytes |}]

let%expect_test _ =
  run_ligo_good [ "info" ; "measure-contract" ; (good_test "edge_case_I.mligo") ] ;
  [%expect{|
    354 bytes |}]
      
let%expect_test _ =
  run_ligo_good [ "info" ; "measure-contract" ; (good_test "edge_case_T.mligo") ] ;
  [%expect{|
    3920 bytes |}]

let%expect_test _ =
  run_ligo_bad [ "info" ; "measure-contract" ; (good_test "edge_case_V.mligo") ] ;
  [%expect{|
    File "../../test/contracts//deep_pattern_matching/edge_case_V.mligo", line 6, character 7 to line 10, character 20:
      5 | let main (p, _ : p * int) : operation list * int =
      6 |   [], (match p with
      7 |     A,A,A,_,_,_ -> 1
      8 |   | B,_,_,A,A,_ -> 2
      9 |   | _,B,_,B,_,A -> 3
     10 |   | _,_,B,_,B,B -> 4)

    Error : this pattern-matching is not exhaustive.
    Here are examples of cases that are not matched:
    - (A, A, B, _, A, _) |}]

let%expect_test _ =
  run_ligo_bad [ "info" ; "measure-contract" ; (good_test "edge_case_S.mligo") ] ;
  [%expect{|
    File "../../test/contracts//deep_pattern_matching/edge_case_S.mligo", line 6, character 7 to line 11, character 31:
      5 | let main (p, _ : p * int) : operation list * int =
      6 |   [], (match p with
      7 |     A, A, _, _, _, _, _, _ -> 1
      8 |   | _, _, A, A, _, _, _, _ -> 2
      9 |   | _, _, _, _, A, A, _, _ -> 3
     10 |   | _, _, _, _, _, _, A, A -> 4
     11 |   | A, B, A, B, A, B, A, B -> 5)

    Error : this pattern-matching is not exhaustive.
    Here are examples of cases that are not matched:
    - (B, _, B, _, B, _, B, _) |}]

let%expect_test _ =
  run_ligo_good [ "compile" ; "contract" ; (good_test "pm_ticket.mligo") ] ;
  [%expect{|
    File "../../test/contracts//deep_pattern_matching/pm_ticket.mligo", line 7, characters 14-17:
      6 |   match p with
      7 |     | { myt = myt ; mynat = mynat } , None -> (([]: operation list), mynat)
      8 |     | { myt = myt ; mynat = mynat } , Some x -> (([]: operation list), x)
    :
    Warning: unused variable "myt".
    Hint: replace it by "_myt" to prevent this warning.

    File "../../test/contracts//deep_pattern_matching/pm_ticket.mligo", line 5, characters 18-19:
      4 |
      5 | let main = fun (p,s: parameter * storage) ->
      6 |   match p with
    :
    Warning: unused variable "s".
    Hint: replace it by "_s" to prevent this warning.

    { parameter (pair (pair (nat %mynat) (ticket %myt int)) (option nat)) ;
      storage nat ;
      code { CAR ;
             UNPAIR ;
             CAR ;
             SWAP ;
             IF_NONE {} { SWAP ; DROP } ;
             NIL operation ;
             PAIR } } |}]

let%expect_test _ =
  run_ligo_good [ "print" ; "ast-core" ; (good_test "list_pattern.mligo") ] ;
  [%expect{|
    const a =
       match CONS(1 , LIST_EMPTY()) with
        | [] -> 1
        | a::b::c::[] -> 2
        | _#2 -> 3 |}]


let%expect_test _ =
  run_ligo_good [ "print" ; "ast-typed" ; (good_test "pm_test.religo") ] ;
  [%expect{|
type myt = sum[Cons -> ( int * int ) , Nil -> unit]
type myr = record[a -> int , b -> nat , c -> string]
type myd =
  sum[One -> sum[Cons -> ( int * int ) , Nil -> unit] , Two -> record[a -> int , b -> nat , c -> string]]
const t1 : ( sum[Cons -> ( int * int ) , Nil -> unit] * sum[Cons -> ( int * int ) , Nil -> unit] ) -> int =
  lambda (x( sum[Cons -> ( int * int ) , Nil -> unit] * sum[Cons -> ( int * int ) , Nil -> unit] ))int return
  let fr : sum[Cons -> ( int * int ) , Nil -> unit] -> int =
    lambda (_xsum[Cons -> ( int * int ) , Nil -> unit])int return 1 in
  let fl : sum[Cons -> ( int * int ) , Nil -> unit] -> int =
    lambda (_xsum[Cons -> ( int * int ) , Nil -> unit])int return 2 in
   match x with
    | ( tuple_proj#16 : sum[Cons -> ( int * int ) , Nil -> unit] , ys : sum[Cons -> ( int * int ) , Nil -> unit] ) ->
     match tuple_proj#16 with
      | Cons ctor_proj#29 ->
         match ys with
          | Cons ctor_proj#27 ->
             match ctor_proj#29 with
              | ( a : int , b : int ) ->
               match ctor_proj#27 with
                | ( c : int , d : int ) ->
                ADD(ADD(ADD(a , b) , c) , d)
          | Nil unit_proj#26 ->
            (fl)@(tuple_proj#16)
      | Nil unit_proj#28 ->
        (fr)@(ys)
const t2 : sum[Cons -> ( int * int ) , Nil -> unit] -> sum[Cons -> ( int * int ) , Nil -> unit] -> int =
  lambda (xsum[Cons -> ( int * int ) , Nil -> unit])sum[Cons -> ( int * int ) , Nil -> unit] -> int return lambda (y
  sum[Cons -> ( int * int ) , Nil -> unit])int return  match x with
                                                        | Cons ctor_proj#35 ->
                                                           match ctor_proj#35 with
                                                            | ( a : int , b : int ) ->
                                                            let old_b : int =
                                                              b in
                                                            let b : int =
                                                               match
                                                                y with
                                                                | Cons ctor_proj#34 ->
                                                                  ADD(a , b)
                                                                | Nil unit_proj#33 ->
                                                                  let f : int -> int =
                                                                    lambda (bint)int return
                                                                  ADD
                                                                  (a , b) in
                                                                  (f)@(
                                                                  ADD
                                                                  (b , 1)) in
                                                            ADD(ADD(a ,
                                                                    old_b) ,
                                                                b)
                                                        | Nil unit_proj#37 ->
                                                           match y with
                                                            | Cons ctor_proj#30 ->
                                                               match
                                                                ctor_proj#30 with
                                                                | ( _a : int , b : int ) ->
                                                                let a : string =
                                                                  "a" in
                                                                ADD((int@{nat})@(
                                                                    (String.length)@(a)) ,
                                                                    b)
                                                            | Nil unit_proj#32 ->
                                                              1
const t3 : sum[One -> sum[Cons -> ( int * int ) , Nil -> unit] , Two -> record[a -> int , b -> nat , c -> string]] -> int =
  lambda (xsum[One -> sum[Cons -> ( int * int ) , Nil -> unit] , Two -> record[a -> int , b -> nat , c -> string]])int return
   match x with
    | One ctor_proj#41 ->
       match ctor_proj#41 with
        | Cons ctor_proj#43 ->
           match ctor_proj#41 with
            | Cons ctor_proj#38 ->
               match ctor_proj#38 with
                | ( a : int , b : int ) ->
                ADD(a , b)
            | Nil unit_proj#40 ->
              2
        | Nil unit_proj#42 ->
          1
    | Two ctor_proj#44 ->
       match ctor_proj#44 with
        | record[a -> a : int , b -> b : nat , c -> c : string] ->
        ADD(ADD(a , (int@{nat})@(b)) , (int@{nat})@((String.length)@(c)))
const t2_3 : sum[Cons -> ( int * int ) , Nil -> unit] -> sum[Cons -> ( int * int ) , Nil -> unit] ->
  sum[One -> sum[Cons -> ( int * int ) , Nil -> unit] , Two -> record[a -> int , b -> nat , c -> string]] -> int =
  lambda (xsum[Cons -> ( int * int ) , Nil -> unit])sum[Cons -> ( int * int ) , Nil -> unit] ->
  sum[One -> sum[Cons -> ( int * int ) , Nil -> unit] , Two -> record[a -> int , b -> nat , c -> string]] -> int return lambda (y
  sum[Cons -> ( int * int ) , Nil -> unit])sum[One -> sum[Cons -> ( int * int ) , Nil -> unit] , Two -> record[a -> int , b -> nat , c -> string]] -> int return lambda (x2
  sum[One -> sum[Cons -> ( int * int ) , Nil -> unit] , Two -> record[a -> int , b -> nat , c -> string]])int return
  let t2 : int =
     match x with
      | Cons ctor_proj#52 ->
         match ctor_proj#52 with
          | ( a : int , b : int ) ->
          let old_b : int = b in
          let b : int =
             match y with
              | Cons ctor_proj#49 ->
                 match ctor_proj#49 with
                  | ( a : int , b : int ) ->
                  ADD(a , b)
              | Nil unit_proj#51 ->
                let f : int -> int = lambda (bint)int return ADD(a , b) in
                (f)@(ADD(b , 1)) in
          ADD(ADD(a , old_b) , b)
      | Nil unit_proj#54 ->
         match y with
          | Cons ctor_proj#46 ->
             match ctor_proj#46 with
              | ( _a : int , b : int ) ->
              let a : string = "a" in
              ADD((int@{nat})@((String.length)@(a)) , b)
          | Nil unit_proj#48 ->
            1 in
  let t3 : int =
     match x2 with
      | One ctor_proj#58 ->
         match ctor_proj#58 with
          | Cons ctor_proj#60 ->
             match ctor_proj#58 with
              | Cons ctor_proj#55 ->
                 match ctor_proj#55 with
                  | ( a : int , b : int ) ->
                  ADD(a , b)
              | Nil unit_proj#57 ->
                2
          | Nil unit_proj#59 ->
            1
      | Two ctor_proj#61 ->
         match ctor_proj#61 with
          | record[a -> a : int , b -> b : nat , c -> c : string] ->
          ADD(ADD(a , b) , (int@{nat})@((String.length)@(c))) in
  ADD(t2 , t3)
const t4 : sum[One -> sum[Cons -> ( int * int ) , Nil -> unit] , Two -> record[a -> int , b -> nat , c -> string]] ->
  sum[One -> sum[Cons -> ( int * int ) , Nil -> unit] , Two -> record[a -> int , b -> nat , c -> string]] -> int =
  lambda (xsum[One -> sum[Cons -> ( int * int ) , Nil -> unit] , Two -> record[a -> int , b -> nat , c -> string]])
  sum[One -> sum[Cons -> ( int * int ) , Nil -> unit] , Two -> record[a -> int , b -> nat , c -> string]] -> int return lambda (y
  sum[One -> sum[Cons -> ( int * int ) , Nil -> unit] , Two -> record[a -> int , b -> nat , c -> string]])int return
  let match_#63[@var] : ( sum[One -> sum[Cons -> ( int * int ) , Nil -> unit] , Two -> record[a -> int , b -> nat , c -> string]] * sum[One -> sum[Cons -> ( int * int ) , Nil -> unit] , Two -> record[a -> int , b -> nat , c -> string]] ) =
    ( x , y ) in
   match match_#63 with
    | ( a : sum[One -> sum[Cons -> ( int * int ) , Nil -> unit] , Two -> record[a -> int , b -> nat , c -> string]] , tuple_proj#64 : sum[One -> sum[Cons -> ( int * int ) , Nil -> unit] , Two -> record[a -> int , b -> nat , c -> string]] ) ->
     match tuple_proj#64 with
      | Two ctor_proj#78 ->
         match a with
          | One ctor_proj#69 ->
             match ctor_proj#69 with
              | Cons ctor_proj#70 ->
                 match ctor_proj#70 with
                  | ( a : int , b : int ) ->
                  ADD(a , b)
              | Nil unit_proj#72 ->
                2
          | Two ctor_proj#73 ->
             match ctor_proj#73 with
              | record[a -> a : int , b -> b : nat , c -> c : string] ->
               match ctor_proj#78 with
                | record[a -> aa : int , b -> gen#3 : nat , c -> cc : string] ->
                ADD(ADD(ADD(ADD(a , (int@{nat})@(b)) ,
                            (int@{nat})@((String.length)@(c))) ,
                        aa) ,
                    (int@{nat})@((String.length)@(cc)))
      | One _x ->
        1
const t5 : int -> int =
  lambda (xint)int return let match_#79[@var] : ( int * unit ) =
                            ( x , unit ) in
                           match match_#79 with
                            | ( a : int , tuple_proj#80 : unit ) ->
                            a
const t6 : int -> int =
  lambda (xint)int return let match_#82[@var] : ( int * unit ) =
                            ( x , unit ) in
                           match match_#82 with
                            | ( gen#4 : int , gen#5 : unit ) ->
                            2
const t7 : option (int) -> int =
  lambda (xoption (int))int return  match x with
                                     | Some x ->
                                       x | None unit_proj#84 ->
                                           1
const t8 : option (( int * int )) -> int -> int =
  lambda (xoption (( int * int )))int -> int return lambda (yint)int return
  let match_#85[@var] : ( option (( int * int )) * int ) = ( x , y ) in
   match match_#85 with
    | ( tuple_proj#86 : option (( int * int )) , x : int ) ->
     match tuple_proj#86 with
      | Some ctor_proj#89 ->
         match ctor_proj#89 with
          | ( x : int , y : int ) ->
          ADD(x , y)
      | None unit_proj#91 ->
        x
const t9 : option (int) -> option (int) -> int =
  lambda (xoption (int))option (int) -> int return lambda (yoption (int))int return
  let match_#92[@var] : ( option (int) * option (int) ) = ( x , y ) in
   match match_#92 with
    | ( tuple_proj#93 : option (int) , ys : option (int) ) ->
     match tuple_proj#93 with
      | Some ctor_proj#102 ->
         match ys with
          | Some ctor_proj#100 ->
            ADD(ctor_proj#102 , ctor_proj#100)
          | None unit_proj#99 ->
            2
      | None unit_proj#101 ->
        1type optioni = option (int)
type myti = sum[Consi -> option (int) , Nili -> unit]
const fl : sum[Consi -> option (int) , Nili -> unit] -> int =
  lambda (_xsum[Consi -> option (int) , Nili -> unit])int return 1
const fo : option (int) -> int = lambda (_xoption (int))int return 2
const t10 : sum[Consi -> option (int) , Nili -> unit] -> sum[Consi -> option (int) , Nili -> unit] -> int =
  lambda (xsum[Consi -> option (int) , Nili -> unit])sum[Consi -> option (int) , Nili -> unit] -> int return lambda (y
  sum[Consi -> option (int) , Nili -> unit])int return let match_#103[@var] :
                                                       ( sum[Consi -> option (int) , Nili -> unit] * sum[Consi -> option (int) , Nili -> unit] ) =
                                                         ( x , y ) in
                                                        match match_#103 with
                                                         | ( tuple_proj#104 : sum[Consi -> option (int) , Nili -> unit] , ys : sum[Consi -> option (int) , Nili -> unit] ) ->
                                                          match tuple_proj#104 with
                                                           | Consi ctor_proj#120 ->
                                                              match ys with
                                                               | Consi ctor_proj#118 ->
                                                                  match
                                                                   ctor_proj#120 with
                                                                   | Some ctor_proj#115 ->
                                                                    ADD
                                                                    ((fo)@(ctor_proj#120) ,
                                                                    (fo)@(ctor_proj#118))
                                                                   | None unit_proj#111 ->
                                                                     match
                                                                    ys with
                                                                    | Nili ctor_proj#114 ->
                                                                    ADD
                                                                    ((fo)@(ctor_proj#120) ,
                                                                    (fo)@(ctor_proj#118))
                                                                    | Consi ctor_proj#112 ->
                                                                     match
                                                                    ctor_proj#112 with
                                                                    | None ctor_proj#113 ->
                                                                    ADD
                                                                    ((fo)@(ctor_proj#120) ,
                                                                    (fo)@(ctor_proj#118))
                                                                    | Some _b ->
                                                                    let b : int =
                                                                    1 in b
                                                               | Nili unit_proj#117 ->
                                                                 (fl)@(tuple_proj#104)
                                                           | Nili unit_proj#119 ->
                                                             (fl)@(ys)
const t11 : sum[Consi -> option (int) , Nili -> unit] -> sum[Consi -> option (int) , Nili -> unit] -> int =
  lambda (xsum[Consi -> option (int) , Nili -> unit])sum[Consi -> option (int) , Nili -> unit] -> int return lambda (y
  sum[Consi -> option (int) , Nili -> unit])int return let match_#122[@var] :
                                                       ( sum[Consi -> option (int) , Nili -> unit] * sum[Consi -> option (int) , Nili -> unit] ) =
                                                         ( x , y ) in
                                                        match match_#122 with
                                                         | ( tuple_proj#123 : sum[Consi -> option (int) , Nili -> unit] , ys : sum[Consi -> option (int) , Nili -> unit] ) ->
                                                          match tuple_proj#123 with
                                                           | Consi ctor_proj#138 ->
                                                              match ys with
                                                               | Consi ctor_proj#136 ->
                                                                  match
                                                                   ctor_proj#138 with
                                                                   | None ctor_proj#133 ->
                                                                     match
                                                                    ctor_proj#138 with
                                                                    | Some a ->
                                                                    a
                                                                    | None unit_proj#121 ->
                                                                    ADD
                                                                    ((fo)@(ctor_proj#138) ,
                                                                    (fo)@(ctor_proj#136))
                                                                   | Some _a ->
                                                                     match
                                                                    ys with
                                                                    | Nili ctor_proj#132 ->
                                                                     match
                                                                    ctor_proj#138 with
                                                                    | Some a ->
                                                                    a
                                                                    | None unit_proj#121 ->
                                                                    ADD
                                                                    ((fo)@(ctor_proj#138) ,
                                                                    (fo)@(ctor_proj#136))
                                                                    | Consi ctor_proj#130 ->
                                                                     match
                                                                    ctor_proj#130 with
                                                                    | None ctor_proj#131 ->
                                                                     match
                                                                    ctor_proj#138 with
                                                                    | Some a ->
                                                                    a
                                                                    | None unit_proj#121 ->
                                                                    ADD
                                                                    ((fo)@(ctor_proj#138) ,
                                                                    (fo)@(ctor_proj#136))
                                                                    | Some b ->
                                                                    let a : int =
                                                                    1 in
                                                                    ADD
                                                                    (a ,
                                                                    b)
                                                               | Nili unit_proj#135 ->
                                                                 (fl)@(tuple_proj#123)
                                                           | Nili unit_proj#137 ->
                                                             (fl)@(ys)
const t12 : list (int) -> int =
  lambda (xlist (int))int return  match x with
                                   | Cons ctor_proj#139 ->
                                      match ctor_proj#139 with
                                       | ( hd : int , tuple_proj#140 : list (int) ) ->
                                        match tuple_proj#140 with
                                         | Cons ctor_proj#145 ->
                                            match ctor_proj#145 with
                                             | ( hd2 : int , tuple_proj#146 : list (int) ) ->
                                              match tuple_proj#146 with
                                               | Cons ctor_proj#149 ->
                                                  match ctor_proj#149 with
                                                   | ( hd3 : int , tuple_proj#150 : list (int) ) ->
                                                    match tuple_proj#150 with
                                                     | Cons ctor_proj#153 ->
                                                       NEG(1)
                                                     | Nil unit_proj#152 ->
                                                       ADD(ADD(hd , hd2) ,
                                                           hd3)
                                               | Nil unit_proj#154 ->
                                                 ADD(hd , hd2)
                                         | Nil unit_proj#155 ->
                                           hd
                                   | Nil unit_proj#156 ->
                                     0
type recordi = record[a -> option (list (int)) , b -> list (int)]
const none_a : record[a -> option (list (int)) , b -> list (int)] =
  record[a -> None(unit) , b -> CONS(42 , LIST_EMPTY())]
const some_a : record[a -> option (list (int)) , b -> list (int)] =
  record[a -> Some(CONS(1 , CONS(2 , CONS(3 , CONS(4 , LIST_EMPTY()))))) ,
         b -> CONS(42 , LIST_EMPTY())]
const a_empty_b_not : record[a -> option (list (int)) , b -> list (int)] =
  record[a -> Some(LIST_EMPTY()) , b -> CONS(111 , LIST_EMPTY())]
const b_empty_a_not : record[a -> option (list (int)) , b -> list (int)] =
  record[a -> Some(CONS(222 , LIST_EMPTY())) , b -> LIST_EMPTY()]
const t13 : record[a -> option (list (int)) , b -> list (int)] -> record[a -> option (list (int)) , b -> list (int)] -> int =
  lambda (xrecord[a -> option (list (int)) , b -> list (int)])record[a -> option (list (int)) , b -> list (int)] -> int return lambda (y
  record[a -> option (list (int)) , b -> list (int)])int return let match_#157[@var] :
                                                                ( record[a -> option (list (int)) , b -> list (int)] * record[a -> option (list (int)) , b -> list (int)] ) =
                                                                  ( x , y ) in
                                                                 match
                                                                  match_#157 with
                                                                  | ( tuple_proj#158 : record[a -> option (list (int)) , b -> list (int)] , tuple_proj#159 : record[a -> option (list (int)) , b -> list (int)] ) ->
                                                                   match
                                                                    tuple_proj#158 with
                                                                    |
                                                                    record[a -> tuple_proj#164 : option (list (int)) , b -> gen#7 : list (int)] ->
                                                                     match
                                                                    tuple_proj#164 with
                                                                    | Some ctor_proj#186 ->
                                                                     match
                                                                    tuple_proj#159 with
                                                                    | record[a -> tuple_proj#170 : option (list (int)) , b -> tuple_proj#171 : list (int)] ->
                                                                     match
                                                                    tuple_proj#170 with
                                                                    | None ctor_proj#183 ->
                                                                    (int@{nat})@(
                                                                    (List.length@{int})@(ctor_proj#186))
                                                                    | Some ctor_proj#174 ->
                                                                     match
                                                                    ctor_proj#174 with
                                                                    | Cons ctor_proj#175 ->
                                                                     match
                                                                    ctor_proj#175 with
                                                                    | ( hd : int , _tl : list (int) ) ->
                                                                     match
                                                                    tuple_proj#171 with
                                                                    | Cons ctor_proj#178 ->
                                                                    (int@{nat})@(
                                                                    (List.length@{int})@(ctor_proj#186))
                                                                    | Nil unit_proj#177 ->
                                                                    hd
                                                                    | Nil unit_proj#179 ->
                                                                     match
                                                                    tuple_proj#171 with
                                                                    | Nil ctor_proj#182 ->
                                                                    (int@{nat})@(
                                                                    (List.length@{int})@(ctor_proj#186))
                                                                    | Cons ctor_proj#180 ->
                                                                     match
                                                                    ctor_proj#180 with
                                                                    | ( hd : int , _tl : list (int) ) ->
                                                                    hd
                                                                    | None unit_proj#184 ->
                                                                     match
                                                                    tuple_proj#159 with
                                                                    | record[a -> gen#9 : option (list (int)) , b -> gen#8 : list (int)] ->
                                                                    NEG(1) |}]

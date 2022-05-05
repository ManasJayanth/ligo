open Cli_expect

let%expect_test _ =
  run_ligo_bad [ "print" ; "ast-typed" ; (bad_test "pattern_match1.jsligo") ] ;
  [%expect{|
    File "../../test/contracts/negative/pattern_match1.jsligo", line 2, character 11 to line 4, character 4:
      1 | let test_foo = (x : test_exec_result) : string => {
      2 |   match(x, {
      3 |     Fail: (_ : test_exec_error) => "",
      4 |   });
      5 | }

    Pattern matching anomaly (redundant, or non exhaustive). |}]

let%expect_test _ =
  run_ligo_bad [ "print" ; "ast-typed" ; (bad_test "pattern_match2.jsligo") ] ;
  [%expect{|
    File "../../test/contracts/negative/pattern_match2.jsligo", line 3, characters 13-15:
      2 |   match(x, {
      3 |     Success: () => "",
      4 |     Fail: (_ : test_exec_error) => ""

    Variant pattern argument is expected of type nat but is of type unit. |}]

let%expect_test _ =
  run_ligo_bad [ "print" ; "ast-typed" ; (bad_test "pattern_match5.jsligo") ] ;
  [%expect{|
    File "../../test/contracts/negative/pattern_match5.jsligo", line 3, characters 14-30:
      2 |   match(x, {
      3 |     Success: (x : nat, y : nat) => "",
      4 |     Fail: (_ : test_exec_error) => ""

    Unsupported match pattern. |}]

let%expect_test _ =
  run_ligo_bad [ "print" ; "ast-typed" ; (bad_test "pattern_match3.jsligo") ; "--test" ] ;
  [%expect{|
    File "../../test/contracts/negative/pattern_match3.jsligo", line 4, characters 4-11:
      3 |     Success: (_ : nat) => "",
      4 |     Failure: (_ : test_exec_error) => ""
      5 |   });

    Pattern not of the expected type sum[Fail -> sum[Balance_too_low -> record[contract_balance -> tez , contract_too_low -> address , spend_request -> tez] , Other -> string , Rejected -> ( michelson_program * address )] , Success -> nat] |}]

let%expect_test _ =
  run_ligo_bad [ "print" ; "ast-typed" ; (bad_test "pattern_match6.jsligo") ] ;
  [%expect{|
  File "../../test/contracts/negative/pattern_match6.jsligo", line 6, character 24 to line 15, character 6:
    5 | let do_something = ([state, action]:[state,action]) : state => {
    6 |     return match(state, {
    7 |         S1: () => (match(action, {
    8 |             A: () => S1(),
    9 |             B: () => S2()
   10 |         })),
   11 |         S2: () => (match(action, {
   12 |             A: () => S2(),
   13 |             B: () => S1()
   14 |         })),
   15 |     });
   16 | };

  Pattern matching anomaly (redundant, or non exhaustive). |}]

let%expect_test _ =
  run_ligo_good [ "print" ; "ast-typed" ; (test "pattern_match4.jsligo") ] ;
  [%expect{xxx|
    const test_foo =
      lambda (x) return  match x with
                          | Fail _#3 ->
                            "" | Success _#2 ->
                                 ""[@private] |xxx}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t2([Nil(), Nil()])" ; "--init-file" ; (test "/deep_pattern_matching/pm_test.jsligo") ] ;
  [%expect{|
    1 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t2([Nil(), Cons([1,2])])" ; "--init-file" ; (test "/deep_pattern_matching/pm_test.jsligo") ] ;
  [%expect{|
    3 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t2([Cons([1,2]), Cons([1,2])])" ; "--init-file" ; (test "/deep_pattern_matching/pm_test.jsligo") ] ;
  [%expect{|
    6 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t2([Cons([1,2]), Nil()])" ; "--init-file" ; (test "/deep_pattern_matching/pm_test.jsligo") ] ;
  [%expect{|
    7 |}]
                                              
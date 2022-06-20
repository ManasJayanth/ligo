(* This function is almost like identity... *)
let almost_id (xs : int list) =
  if (List.length xs = 5n) then
    (match xs with
     | x :: _ -> if x = 42 then [] else xs
     | _ -> xs)
  else xs

(* Let's check if it really is *)
let test =
  (* We generate the property *)
  let test = PBT.make_test (PBT.gen_small : (int list) gen) (fun (xs : int list) -> almost_id xs = xs) in
  (* And run it *)
  PBT.run test 10000n

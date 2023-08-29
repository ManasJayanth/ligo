let nested (type a) =
  let x (type b) =
    let y (type c) =
      let z = (failwith ("nested") : a -> b -> c) in
      z in
    y in
  x

[@entry]
let main (_ : unit) (_ : unit) : operation list * unit =
  [], (nested 0 "test" 12 : unit)

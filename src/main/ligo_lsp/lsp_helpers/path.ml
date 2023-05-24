let normalise_backslashes p = p |> Str.global_replace (Str.regexp "[\\|/]+") "/"
let normalise_case = Caml.String.lowercase_ascii
let normalise p = if Sys.unix then p else p |> normalise_backslashes |> normalise_case
let equal a b = String.equal (normalise a) (normalise b)

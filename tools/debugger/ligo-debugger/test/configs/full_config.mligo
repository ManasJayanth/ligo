let contract_env =
  { now           = "2020-01-01T00:00:00Z"
  ; balance       = 1tez
  ; amount        = 2tez
  ; self          = "KT1XQcegsEtio9oGbLUHA8SKX4iZ2rpEXY9b"
  ; source        = "tz1hTK4RYECTKcjp2dddQuRGUX5Lhse3kPNY"
  ; sender        = "tz1hTK4RYECTKcjp2dddQuRGUX5Lhse3kPNY"
  ; chain_id      = "NetXH12Aer3be93"
  ; level         = 10000
  ; voting_powers = Map.literal
      [ "tz1aZcxeRT4DDZZkYcU3vuBaaBRtnxyTmQRr", 40
      ; "tz1hTK4RYECTKcjp2dddQuRGUX5Lhse3kPNY", 60
      ]
  }

let config =
  { parameter            = "some_param"
  ; storage              = "some_storage"
  ; program              = "main.mligo"
  ; entrypoint           = "main"
  ; michelson_entrypoint = "default"
  ; log_dir              = "tmp/contract.log"
  ; contract_env         = contract_env
  }

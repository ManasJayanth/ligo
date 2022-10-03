type t =
  { name : string
  ; version : string
  ; description : string
  ; scripts : (string * string) list
  ; main : string option
  ; author : string
  ; repository : Repository_url.t
  ; license : string
  ; readme : string
  ; ligo_manifest_path : string
  }
[@@deriving to_yojson]

let is_empty field value =
  if String.equal value ""
  then failwith (Format.sprintf "%s is \"\" in package.json" field)
  else ()


let is_version_correct version =
  if Option.is_none @@ Semver.of_string version
  then failwith (Format.sprintf "invalid version %s in package.json" version)
  else ()


let validate t =
  let { name; version; author; _ } = t in
  try
    is_empty "name" name;
    is_empty "author" author;
    is_empty "version" version;
    is_version_correct version;
    Ok t
  with
  | Failure e -> Error e


let try_readme ~project_root =
  let ls = Sys.ls_dir project_root in
  match
    List.find ls ~f:(fun d ->
        String.equal "readme.md" (String.lowercase d)
        || String.equal "readme" (String.lowercase d))
  with
  | None -> "ERROR: No README data found!"
  | Some r ->
    let contents = In_channel.read_all (Filename.concat project_root r) in
    String.escaped contents


let read ~project_root =
  match project_root with
  | None -> failwith "No package.json found!"
  | Some project_root ->
    let ligo_manifest_path = Filename.concat project_root "package.json" in
    let json =
      try Yojson.Safe.from_file ligo_manifest_path with
      | _ -> failwith "No package.json found!"
    in
    (try
       let module Util = Yojson.Safe.Util in
       let name =
         try json |> Util.member "name" |> Util.to_string with
         | _ -> failwith "No name field in package.json"
       in
       let version =
         try json |> Util.member "version" |> Util.to_string with
         | _ -> failwith "No version field in package.json'"
       in
       let description =
         try json |> Util.member "description" |> Util.to_string with
         | _ -> ""
       in
       let scripts =
         try
           json
           |> Util.member "scripts"
           |> Util.to_assoc
           |> List.Assoc.map ~f:Util.to_string
         with
         | _ -> []
       in
       let author =
         try json |> Util.member "author" |> Util.to_string with
         | _ -> failwith "No author field  in package.json"
       in
       let repository =
         try json |> Util.member "repository" |> Repository_url.parse with
         | _ -> failwith "No repository field in package.json"
       in
       let main =
         try Some (json |> Util.member "main" |> Util.to_string) with
         | _ -> None
       in
       let license =
         try json |> Util.member "license" |> Util.to_string with
         | _ -> failwith "No license field in package.json"
       in
       let readme =
         try json |> Util.member "readme" |> Util.to_string with
         | _ -> try_readme ~project_root
       in
       Ok
         { name
         ; version
         ; description
         ; scripts
         ; main
         ; author
         ; repository
         ; license
         ; readme
         ; ligo_manifest_path
         }
     with
    | Failure e -> Error e)

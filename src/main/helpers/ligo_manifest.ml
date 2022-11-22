module Util = Yojson.Safe.Util

module Bugs = struct
  type t =
    { email : string
    ; url : string
    }
  [@@deriving yojson]

  (* If required validate `email` & url` *)
end

type t =
  { name : string
  ; version : string
  ; description : string
  ; scripts : (string * string) list
  ; dependencies : (string * string) list
  ; dev_dependencies : (string * string) list
  ; main : string
  ; author : string
  ; type_ : string
  ; storage_fn : string option
  ; storage_arg : string option
  ; repository : Repository_url.t
  ; license : string
  ; readme : string
  ; ligo_manifest_path : string
  ; bugs : Bugs.t
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
  let ls = Sys_unix.ls_dir project_root in
  match
    List.find ls ~f:(fun d ->
        String.equal "readme.md" (String.lowercase d)
        || String.equal "readme" (String.lowercase d))
  with
  | None -> "ERROR: No README data found!"
  | Some r ->
    let contents = In_channel.read_all (Filename.concat project_root r) in
    String.escaped contents


let parse_name json =
  match Util.member "name" json with
  | `String s -> Ok s
  | `Null -> Error "No name field in package.json"
  | _ -> Error "Invalid name field in package.json"


let parse_version json =
  match Util.member "version" json with
  | `String s -> Ok s
  | `Null -> Error "No version field in package.json"
  | _ -> Error "Invalid version field in package.json"


let parse_author json =
  match Util.member "author" json with
  | `String s -> Ok s
  | `Null -> Error "No author field in package.json"
  | _ -> Error "Invalid author field in package.json"


let parse_main json =
  match Util.member "main" json with
  | `String s -> Ok s
  | `Null -> Error "No main field in package.json"
  | _ -> Error "Invalid main field in package.json"


let parse_license json =
  match Util.member "license" json with
  | `String s -> Ok s
  | `Null -> Error "No license field in package.json"
  | _ -> Error "Invalid license field in package.json"


let parse_description json =
  match Util.member "description" json with
  | `String s -> Ok s
  | _ -> Ok ""


let parse_string_assoc_list
    : (string * Yojson.Safe.t) list -> (string, string) List.Assoc.t
  =
 fun a ->
  List.filter_opt
  @@ List.map a ~f:(fun (k, v) ->
         match v with
         | `String v -> Some (k, v)
         | _ -> None)


let parse_scripts json =
  match Util.member "scripts" json with
  | `Assoc a -> Ok (parse_string_assoc_list a)
  | _ -> Ok []


let parse_dependencies json =
  match Util.member "dependencies" json with
  | `Assoc a -> Ok (parse_string_assoc_list a)
  | _ -> Ok []


let parse_dev_dependencies json =
  match Util.member "devDependencies" json with
  | `Assoc a -> Ok (parse_string_assoc_list a)
  | _ -> Ok []


let parse_repository json =
  match Util.member "repository" json with
  | `Null -> Error "No repository field in package.json"
  | repo ->
    (match Repository_url.parse repo with
    | Ok t -> Ok t
    | Error e ->
      Error (Format.sprintf "Invalid repository field in package.json\n%s" e))


let parse_readme ~project_root json =
  match Util.member "readme" json with
  | `String s -> Ok s
  | _ -> Ok (try_readme ~project_root)


let parse_type json =
  match Util.member "type" json with
  | `Null -> Ok "library"
  | `String "contract" -> Ok "contract"
  | `String "library" -> Ok "library"
  | _ ->
    Error
      "Invalid type field in package.json\n\
       Type can be either library or contract"


let parse_storage_fn ~type_ json =
  match Util.member "storage_fn" json with
  | `String s -> Ok (Some s)
  | _ when String.(type_ = "contract") ->
    Error "In case of a type : contract a `storage_fn` needs to be provided"
  | _ -> Ok None


let parse_storage_arg ~type_ json =
  match Util.member "storage_arg" json with
  | `String s -> Ok (Some s)
  | _ when String.(type_ = "contract") ->
    Error "In case of a type : contract a `storage_arg` needs to be provided"
  | _ -> Ok None


let parse_bugs json =
  match Util.member "bugs" json with
  | `Null -> Error "No bugs field in package.json"
  | bugs ->
    (match Bugs.of_yojson bugs with
    | Ok bugs -> Ok bugs
    | Error _ ->
      Error
        "Invalid `bugs` fields.\n\
         email & url (bug tracker url) needs to be provided\n\
         e.g.{ \"url\" : \"https://github.com/foo/bar/issues\" , \"email\" : \
         \"foo@bar.com\" }")


let ( let* ) x f = Result.bind x ~f

let read_from_json ~project_root ~ligo_manifest_path json =
  (* Required fields *)
  let* name = parse_name json in
  let* version = parse_version json in
  let* author = parse_author json in
  let* repository = parse_repository json in
  let* main = parse_main json in
  let* license = parse_license json in
  (* Optional fields *)
  let* description = parse_description json in
  let* scripts = parse_scripts json in
  let* dependencies = parse_dependencies json in
  let* dev_dependencies = parse_dev_dependencies json in
  let* type_ = parse_type json in
  let* storage_fn = parse_storage_fn ~type_ json in
  let* storage_arg = parse_storage_arg ~type_ json in
  let* readme = parse_readme ~project_root json in
  let* bugs = parse_bugs json in
  Ok
    { name
    ; version
    ; author
    ; description
    ; scripts
    ; dependencies
    ; dev_dependencies
    ; main
    ; type_
    ; storage_fn
    ; storage_arg
    ; repository
    ; license
    ; readme
    ; ligo_manifest_path
    ; bugs
    }


let read ~project_root =
  match project_root with
  | None -> failwith "No package.json found!"
  | Some project_root ->
    let ligo_manifest_path = Filename.concat project_root "package.json" in
    let () =
      match Sys_unix.file_exists ligo_manifest_path with
      | `No | `Unknown -> failwith "Unable to find package.json!"
      | `Yes -> ()
    in
    let json =
      try Yojson.Safe.from_file ligo_manifest_path with
      | _ -> failwith "Error in parsing package.json (invalid json)"
    in
    read_from_json ~project_root ~ligo_manifest_path json

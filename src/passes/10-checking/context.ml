(* This file represente the context which give the association of values to types *)
module Location = Simple_utils.Location
open Ast_typed

module Typing = struct

  let global_id = ref 0
  module Types = struct

    (* An [IdMap] is a [Map] augmented with an [id] field (which is wrapped around the map [value] field).
      Using a map instead of a list makes shadowed modules inaccessible,
      since they are overwritten from the map when adding the shadower, whilst they were kept when using lists.
      The [id] field in the map values is used to infer the type to which a constructor belong when they are not annotated
      e.g. we need to keep the declaration order to infer that 'c' has type z in:

        type x = A of int | B
        module M = struct
          type y = A of int
        end
        type z = A of int | AA

        let c = A 2
    *)
    module IdMap = struct
      module type OrderedType = Caml.Map.OrderedType

      module type IdMapSig = sig
        type key
        type 'a t

        val empty : 'a t
        val add : 'a t -> key -> 'a -> 'a t
        (* In case of merge conflict between two values with same keys, this merge function keeps the value with the highest id.
           This follows the principle that this map always keeps the latest value in case of conflict *)
        val merge : 'a t -> 'a t -> 'a t
        val to_kv_list : 'a t -> (key * 'a) list
      end (* of module type S *)

      module Make (Ord : OrderedType) : IdMapSig with type key = Ord.t = struct
        module Map = Simple_utils.Map.Make(Ord)

        type key = Ord.t

        type 'a id_wrapped = {
          id : int; (* This is is used in [filter_values], to return a list of matching values in chronological order *)
          value : 'a
        }
        type 'a t = ('a id_wrapped) Map.t

        let empty = Map.empty

        let add : 'a t -> key -> 'a -> 'a t =
          fun map key value ->
            global_id := !global_id + 1;
            let id = !global_id in
            let id_value = { id ; value } in
            Map.add key id_value map

        let merge : 'a t -> 'a t -> 'a t =
          fun m1 m2 ->
            let merger : key -> 'a id_wrapped option -> 'a id_wrapped option -> 'a id_wrapped option =
              fun _ v1 v2 ->
                match (v1, v2) with
                | None,   None   -> None
                | Some v, None   -> Some v
                | None,   Some v -> Some v
                | Some v1, Some v2 ->
                  if v1.id > v2.id then Some v1 else Some v2
            in
            Map.merge merger m1 m2

        let to_kvi_list : 'a t -> (key * 'a * int) list =
          fun map ->
            List.map ~f:(fun (key, value) -> (key, value.value, value.id)) @@ Map.to_kv_list map

        let sort_to_kv_list : (key * 'a * int) list -> (key * 'a) list =
          fun list ->
            let sorted_list = List.sort list ~compare:(fun (_, _, id1) (_, _, id2) -> Int.compare id2 id1) in
            List.map ~f:(fun (k, v, _) -> (k, v)) sorted_list

        let to_kv_list : 'a t -> (key * 'a) list =
          fun map ->
            sort_to_kv_list @@ to_kvi_list map

      end (* of module IdMap.Make*)

    end (* of module IdMap *)

    module ValueMap  = IdMap.Make(ValueVar)
    module TypeMap   = IdMap.Make(TypeVar)
    module ModuleMap = IdMap.Make(ModuleVar)

    type values  = type_expression ValueMap.t
    type types   = type_expression TypeMap.t
    type modules = context ModuleMap.t
    and  context = {
        values  : values  ;
        types   : types   ;
        modules : modules ;
      }
  end (* of module Types *)


  type t = Types.context
  let empty : t = { values = Types.ValueMap.empty ; types = Types.TypeMap.empty ; modules = Types.ModuleMap.empty }

  module PP = struct
    open Format
    open Ast_typed.PP
    open Simple_utils.PP_helpers
    open Types

    let list_sep_scope x = list_sep x (const " | ")
    let value_binding ppf (ev,te) =
      fprintf ppf "%a => %a" expression_variable ev type_expression te
    let type_binding ppf (type_var,type_) =
      fprintf ppf "%a => %a" type_variable type_var type_expression type_

    let rec module_binding ppf (mod_var,type_) =
      fprintf ppf "%a => %a" module_variable mod_var context type_

    and context ppf ({values;types;modules} : Types.context) =
      fprintf ppf "{[ %a; @; %a; %a; ]}"
        (list_sep_scope value_binding ) (ValueMap.to_kv_list  values)
        (list_sep_scope type_binding  ) (TypeMap.to_kv_list   types)
        (list_sep_scope module_binding) (ModuleMap.to_kv_list modules)

  end (* of module PP *)
  let pp =  PP.context

  (* Not commutative as a shadows b*)
  let union : t -> t -> t = fun a b ->
    Types.{values = ValueMap.merge a.values b.values; types = TypeMap.merge a.types b.types ; modules = ModuleMap.merge a.modules b.modules}

  (* TODO: generate *)
  let get_types  : t -> Types.types  = fun { values=_ ; types ; modules=_ } -> types
  (* TODO: generate *)
  let get_modules : t -> Types.modules = fun { values=_ ; types=_ ; modules } -> modules


  (* TODO: generate : these are now messy, clean them up. *)
  let add_value : t -> Ast_typed.expression_variable -> Ast_typed.type_expression -> t = fun c ev te ->
    let values = Types.ValueMap.add c.values ev te in
    {c with values}

  let add_type : t -> Ast_typed.type_variable -> Ast_typed.type_expression -> t = fun c tv te ->
    let types = Types.TypeMap.add c.types tv te in
    {c with types}

  (* we represent for_all types as themselves because we don't have typechecking yet *)
  let add_type_var : t -> Ast_typed.type_variable -> unit -> t = fun c tv () ->
    add_type c tv (Ast_typed.t_variable tv ())

  (* we use type_var while we don't have kind checking *)
  let add_kind : t -> Ast_typed.type_variable -> unit -> t = fun c tv () ->
    add_type_var c tv ()
  let add_module : t -> Ast_typed.module_variable -> t -> t = fun c mv te ->
    let modules = Types.ModuleMap.add c.modules mv te in
    {c with modules}

  let get_value (e:t)  = List.Assoc.find ~equal:Ast_typed.ValueVar.equal @@ Types.ValueMap.to_kv_list e.values
  let get_type (e:t)   = List.Assoc.find ~equal:Ast_typed.TypeVar.equal @@ Types.TypeMap.to_kv_list e.types
  let get_module (e:t) = List.Assoc.find ~equal:Ast_typed.ModuleVar.equal @@ Types.ModuleMap.to_kv_list e.modules

  let get_type_vars : t -> Ast_typed.type_variable list  = fun { values=_ ; types ; modules=_ } -> fst @@ List.unzip @@ Types.TypeMap.to_kv_list types

  let rec context_of_module_expr : outer_context:t -> Ast_typed.module_expr -> t = fun ~outer_context me ->
    match me.wrap_content with
    | M_struct declarations -> (
      let f : t -> Ast_typed.declaration -> t = fun acc d ->
        match Location.unwrap d with
        | Declaration_constant {binder;expr;attr={public;_}} ->
           if public then add_value acc binder.var expr.type_expression
           else acc
        | Declaration_type {type_binder;type_expr;type_attr={public;_}} ->
           if public then add_type acc type_binder type_expr
           else acc
        | Declaration_module {module_binder;module_;module_attr={public;_}} ->
           if public then
             let context = context_of_module_expr ~outer_context:(union acc outer_context) module_ in
             add_module acc module_binder context
           else acc
      in
      List.fold ~f ~init:empty declarations
    )
    | M_variable module_binder -> (
      let ctxt_opt = get_module outer_context module_binder in
      match ctxt_opt with
      | Some x -> x
      | None -> empty
    )
    | M_module_path path -> (
      Simple_utils.List.Ne.fold_left path
        ~f:(fun ctxt name ->
          match get_module ctxt name with
          | Some x -> x
          | None -> empty
        )
        ~init:outer_context
    )

  (* Load context from the outside declarations *)
  let init ?env () =
    match env with None -> empty
                 | Some (env) ->
                    let f : t -> Ast_typed.declaration -> t = fun c d ->
                      match Location.unwrap d with
                      | Declaration_constant {binder;expr;attr=_}  -> add_value c binder.var expr.type_expression
                      | Declaration_type {type_binder;type_expr;type_attr=_} -> add_type c type_binder type_expr
                      | Declaration_module {module_binder;module_;module_attr=_} ->
                         let mod_context = context_of_module_expr ~outer_context:c module_ in
                         add_module c module_binder mod_context
                    in
                    Environment.fold ~f ~init:empty env

  open Ast_typed.Types


(*
  for any constructor [ctor] that belong to a sum-type `t` in the context [ctxt] return a 4-uple list:
  1. the declaration name for type `t`
  2. list of abstracted type variables in the constructor parameter (e.g. ['a ; 'b] for `Foo of ('a * int * 'b)`)
  3. type of the constructor parameter (e.g. `'a * int * 'b` for `Foo of ('a * int * 'b)`)
  4. type of the sum-type found in the context
*)
  let rec get_sum: label -> t -> (type_variable * type_variable list * type_expression * type_expression) list =
    fun ctor ctxt ->
        let aux = fun (var,type_) ->
          let t_params, type_ = Ast_typed.Helpers.destruct_type_abstraction type_ in
          match type_.type_content with
          | T_sum m -> (
            match LMap.find_opt ctor m.content with
            | Some {associated_type ; _} -> Some (var,t_params, associated_type , type_)
            | None -> None
          )
          | _ -> None
        in
        let matching_t_sum = match List.filter_map ~f:aux (Types.TypeMap.to_kv_list @@ get_types ctxt) with
        | [] ->
          (* If the constructor isn't matched in the context of values,
            reccursively search for in the context of all the modules in scope *)
          let modules = get_modules ctxt in
          List.fold_left (Types.ModuleMap.to_kv_list modules) ~init:[]
            ~f:(fun res (_,module_) ->
              match res with | [] -> get_sum ctor module_ | lst -> lst
            )
        | lst -> lst
        in
        let general_type_opt = List.find ~f:(fun (_, tvs, _, _) -> not @@ List.is_empty tvs) matching_t_sum in
        match general_type_opt with
          Some general_type -> [general_type]
        | None -> matching_t_sum

  let get_record : _ label_map -> t -> (type_variable option * rows) option = fun lmap e ->
    let lst_kv  = LMap.to_kv_list_rev lmap in
    let rec rec_aux e =
      let aux = fun (_,type_) ->
        match type_.type_content with
        | T_record m -> Simple_utils.Option.(
            let lst_kv' = LMap.to_kv_list_rev m.content in
            let m = map ~f:(fun () -> m) @@ Ast_typed.Misc.assert_list_eq
                                              ( fun (ka,va) (kb,vb) ->
                                                let Label ka = ka in
                                                let Label kb = kb in
                                                let* () = Ast_typed.Misc.assert_eq ka kb in
                                                Ast_typed.Misc.assert_type_expression_eq (va.associated_type, vb.associated_type)
                                              ) lst_kv lst_kv' in
            map ~f:(fun m -> (type_.orig_var,m)) @@ m
                        )
        | _ -> None
      in
      match List.find_map ~f:aux @@ Types.TypeMap.to_kv_list @@ get_types e with
        Some _ as s -> s
      | None ->
         let modules = get_modules e in
         List.fold_left ~f:(fun res (__,module_) ->
             match res with Some _ as s -> s | None -> rec_aux module_
           ) ~init:None (Types.ModuleMap.to_kv_list modules)
    in rec_aux e

end

module App = struct
  type e = { args : type_expression list ; old_expect : type_expression option  }
  type t = { expect : type_expression option ;
             history : e list }
  let pop ({ history ; _ } : t) = match history with
      { args ; _ }  :: _ -> Some args | [] -> None
  let create expect : t = { expect ; history = [] }
  let push expect args ctxt : t =
    let { expect = old_expect ; history } = ctxt in
    { expect ; history = { args ; old_expect } :: history }
  let get_expect ({ expect ; _ } : t) = expect
  let update_expect expect { history ; _ } : t = { expect ; history }
end

type typing_context = Typing.t
type app_context = App.t
type t = app_context * typing_context

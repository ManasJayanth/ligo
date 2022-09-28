module Option = Simple_utils.Option

type 'a t
  [@@deriving eq,compare,yojson,hash,fold,map]

val pp : (Format.formatter -> 'a -> unit) -> Format.formatter -> 'a t -> unit
val fold_map : ('acc -> 'a -> 'acc * 'b) -> 'acc -> 'a t -> 'acc * 'b t

val make : Var.Value_var.t -> 'a -> 'a t
val set_var : 'a t -> Var.Value_var.t -> 'a t

val get_var : 'a t -> Var.Value_var.t
val get_ascr : 'a t -> 'a
val set_ascr : 'a t -> 'b -> 'b t

val apply : (Var.Value_var.t -> 'b) -> 'a t -> 'b

val equal_var : 'a t -> 'b t -> bool



val keep : string -> unit
(** [keep target] registers a ppx to preserve code annotated with [%target]. *)

val remove : string -> unit
(** [remove target] registers a ppx to remove all code annotated with [%target]. *)

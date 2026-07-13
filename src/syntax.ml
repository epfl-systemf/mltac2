(** Syntax helpers. *)

open Names
open Ltac2_plugin

(** {1 Move locations} *)

let at = function
  | `top -> Logic.MoveFirst
  | `bottom -> Logic.MoveLast

let before (id: Id.t) = Logic.MoveBefore id
let after (id: Id.t) = Logic.MoveAfter id

(** {1 Clauses} *)

let (|-) hyps concl: Tac2types.clause =
  { onhyps = hyps; concl_occs = concl }

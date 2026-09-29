open Ltac2
open Syntax
open Std

(** The declarations below are used to test that the syntax DSL compiles
    correctly. *)

(* Silence "unused value" warnings in this file. *)
[@@@warning "-32"]

(** {1 [apply]} *)

(** [apply t] *)
let test_apply (t: constr) =
  apply [term t]

(** [apply t1, t2] *)
let test_apply2 (t1: constr) (t2: constr) =
  apply [term t1; term t2]

(** [apply t with x] *)
let test_apply_with (t: constr) (x: constr) =
  apply [{ (term t) with bindings = Implicit [x]}]

(** [apply t with (1 := x)] *)
let test_apply_with_one (t: constr) (x: constr) =
  apply [{ (term t) with bindings = Explicit [Nth_hyp 1, x]}]

(** [apply t with (x := y)] *)
let test_apply_with_name (t: constr) (x: ident) (y: constr) =
  apply [{ (term t) with bindings = Explicit [Named_hyp x, y]}]

(** [apply t in h] *)
let test_apply_in (t: constr) (h: ident) =
  apply [term t] ~in_hyp_as:(h, None)

(** [apply t in h as _] *)
let test_apply_in_as (t: constr) (h: ident) =
  apply [term t] ~in_hyp_as:(h, Some __)

(** {1 [intro]} *)

(** [intro] *)
let test_intro =
  intro ()

(** [intro x] *)
let test_intro_named (x: ident) =
  intro ~name:x ()

(** [intro x at top] *)
let test_intro_named_at_top (x: ident) =
  intro ~name:x ~where:At_top ()

(** {1 [intros]} *)

(** [intros] *)
let test_intros =
  intros []

(** [intros *] *)
let test_intros_star =
  intros [(@*)]

(** [intros **] *)
let test_intros_star2 =
  intros [(@**)]

(** [intros x] *)
let test_intros_name (x: ident) =
  intros [name x]

(** [intros x y] *)
let test_intros_name2 (x: ident) (y: ident) =
  intros [name x; name y]

(** [intros ?] *)
let test_intros_fresh =
  intros [(??)]

(** [intros ?x] *)
let test_intros_fresh_begins (x: ident) =
  intros [?:x]

(** [intros _] *)
let test_intros_wildcard =
  intros [__]

(** [intros (h1 & h2 & h3)] *)
let test_intros_and_split (h1: simple intropattern) (h2: simple intropattern) (h3: simple intropattern) =
  intros [h1 & h2 & h3]

(** [intros [h1 | h2 | h3]] *)
let test_intros_or_split (h1: any intropattern) (h2: any intropattern) (h3: any intropattern) =
  intros [or_pattern [[h1]; [h2]; [h3]]]

(** [intros [h1 x | h2 | h3]] *)
let test_intros_or_split2 (h1: any intropattern) (x: any intropattern) (h2: any intropattern) (h3: any intropattern) =
  intros [or_pattern [[h1; x]; [h2]; [h3]]]

(** [intros -->] *)
let test_intros_rw =
  intros [(-->)]

(** [intros <--] *)
let test_intros_rw_rtl =
  intros [(<--)]

(** [intros [= p]] *)
let test_intros_eq (p: any intropattern list) =
  intros [(@=) p]

(** {1 [remember]} *)

(** [remember t] *)
let test_remember (t: constr) =
  remember t

(** [remember t as u] *)
let test_remember_as (t: constr) (u: ident) =
  remember t ~as_name:u

(** [remember t eqn:h] *)
let test_remember_eqn (t: constr) (h: naming intropattern) =
  remember t ~eqn:h

(** [remember t in * |- * at 1 2] *)
let test_remember_at (t: constr) =
  remember t ~where:(Everywhere |- At [1; 2])

(** [remember t in * |- * at -1 2] *)
let test_remember_at_neg (t: constr) =
  remember t ~where:(Everywhere |- Everywhere_but [1; 2])

(** {1 [rewrite]} *)

(** [rewrite eq] *)
let test_rewrite (eq: constr) =
  rewrite [(==>) eq]

(** [rewrite eq with (x := y)] *)
let test_rewrite_with (eq: constr) (x: ident) (y: constr) =
  rewrite [(==>) eq ~with_:(Explicit [Named_hyp x, y])]

(** [rewrite -> eq] *)
let test_rewrite_ltr (eq: constr) =
  rewrite [(==>) eq]

(** [rewrite <- eq] *)
let test_rewrite_rtl (eq: constr) =
  rewrite [(<==) eq]

(** [rewrite 2 eq] *)
let test_rewrite_n (eq: constr) =
  rewrite [(==>) ~n:(Exactly 2) eq]

(** [rewrite 2? eq] *)
let test_rewrite_at_most_n (eq: constr) =
  rewrite [(==>) ~n:(At_most 2) eq]

(** [rewrite ? eq] *)
let test_rewrite_star (eq: constr) =
  rewrite [(==>) ~n:Star eq]

(** [rewrite ! eq] *)
let test_rewrite_plus (eq: constr) =
  rewrite [(==>) ~n:Plus eq]

(** {1 [induction] *)

open Induction_clause

(** [induction H] *)
let test_induction (h: hypothesis) =
  induction [on_hyp h]

(** [induction c] *)
let test_induction_constr (c: constr) =
  induction [on_constr (term c)]

(** [induction H using p] *)
let test_induction_using (h: hypothesis) (p: constr_with_bindings) =
  induction [on_hyp h] ~using:p

(** [induction H eqn:x] *)
let test_induction_eqn (h: hypothesis) (x: naming intropattern) =
  induction [on_hyp h ~eqn:x]

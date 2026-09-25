open Ltac2
open Syntax
open Std

(** The declarations below are used to test that the syntax DSL compiles
    correctly. *)

(* Silence "unused value" warnings in this file. *)
[@@@warning "-32"]

(** {1 [apply]} *)

(** [apply t] *)
let test_apply t =
  apply [term t]

(** [apply t1, t2] *)
let test_apply2 t1 t2 =
  apply [term t1; term t2]

(** [apply t with x] *)
let test_apply_with t x =
  apply [{ (term t) with bindings = Implicit [x]}]

(** [apply t with (1 := x)] *)
let test_apply_with_one t x =
  apply [{ (term t) with bindings = Explicit [Nth_hyp 1, x]}]

(** [apply t with (x := y)] *)
let test_apply_with_name t x y =
  apply [{ (term t) with bindings = Explicit [Named_hyp x, y]}]

(** [apply t in h] *)
let test_apply_in t h =
  apply [term t] ~in_hyp_as:(h, None)

(** [apply t in h as _] *)
let test_apply_in_as t h =
  apply [term t] ~in_hyp_as:(h, Some __)

(** {1 [intro]} *)

(** [intro] *)
let test_intro =
  intro ()

(** [intro x] *)
let test_intro_named x =
  intro ~name:x ()

(** [intro x at top] *)
let test_intro_named_at_top x =
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
let test_intros_name x =
  intros [name x]

(** [intros x y] *)
let test_intros_name2 x y =
  intros [name x; name y]

(** [intros ?] *)
let test_intros_fresh =
  intros [(??)]

(** [intros ?x] *)
let test_intros_fresh_begins x =
  intros [?:x]

(** [intros _] *)
let test_intros_wildcard =
  intros [__]

(** [intros (h1 & h2 & h3)] *)
let test_intros_and_split h1 h2 h3 =
  intros [h1 & h2 & h3]

(** [intros [h1 | h2 | h3]] *)
let test_intros_or_split h1 h2 h3 =
  intros [or_pattern [[h1]; [h2]; [h3]]]

(** [intros [h1 x | h2 | h3]] *)
let test_intros_or_split2 h1 x h2 h3 =
  intros [or_pattern [[h1; x]; [h2]; [h3]]]

(** [intros -->] *)
let test_intros_rw =
  intros [(-->)]

(** [intros <--] *)
let test_intros_rw_rtl =
  intros [(<--)]

(** [intros [= p]] *)
let test_intros_eq p =
  intros [(@=) p]

(** {1 [remember]} *)

(** [remember t] *)
let test_remember t =
  remember t

(** [remember t as u] *)
let test_remember_as t u =
  remember t ~as_name:u

(** [remember t eqn:h] *)
let test_remember_eqn t h =
  remember t ~eqn:h

(** [remember t in * |- * at 1 2] *)
let test_remember_at t =
  remember t ~where:(Everywhere |- At [1; 2])

(** [remember t in * |- * at -1 2] *)
let test_remember_at_neg t =
  remember t ~where:(Everywhere |- Everywhere_but [1; 2])

(** {1 [rewrite]} *)

(** [rewrite eq] *)
let test_rewrite eq =
  rewrite [rewriting eq]

(** [rewrite eq with (x := y)] *)
let test_rewrite_with eq x y=
  rewrite [rewriting eq ~with_:(Explicit [Named_hyp x, y])]

(** [rewrite -> eq] *)
let test_rewrite_ltr eq =
  rewrite [rewriting eq ~orient:((-->))]

(** [rewrite <- eq] *)
let test_rewrite_rtl eq =
  rewrite [rewriting eq ~orient:((<--))]

(** [rewrite 2 eq] *)
let test_rewrite_n eq =
  rewrite [rewriting eq ~n:(Exactly 2)]

(** [rewrite 2? eq] *)
let test_rewrite_at_most_n eq =
  rewrite [rewriting eq ~n:(At_most 2)]

(** [rewrite ? eq] *)
let test_rewrite_star eq =
  rewrite [rewriting eq ~n:Star]

(** [rewrite ! eq] *)
let test_rewrite_plus eq =
  rewrite [rewriting eq ~n:Plus]

(** {1 [induction] *)

(** [induction H] *)
let test_induction h =
  induction [induct_on (On_hyp h)]

(** [induction c] *)
let test_induction_constr c =
  induction [induct_on (On_constr c)]

(** [induction H using p] *)
let test_induction_using h p =
  induction [induct_on (On_hyp h)] ~using:p

(** [induction H eqn:x] *)
let test_induction_eqn h x =
  induction [induct_on (On_hyp h) ~eqn:x]

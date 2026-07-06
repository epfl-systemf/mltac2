(** Re-exports of Rocq APIs under their Ltac2 name. *)

open Names
open Ltac2_plugin

(** Built-in types *)
type ident = Id.t
type uint63 = Uint63.t
type pstring = Pstring.t
type evar = Evar.t
type sort = Sorts.t
type cast = Constr.cast_kind
type instance = EConstr.EInstance.t
type constant = Constant.t
type inductive = Ind.t
type constructor = Construct.t
type projection = Projection.t
type pattern = Pattern.constr_pattern
type constr = EConstr.t
type preterm = Ltac_pretype.closed_glob_constr
type binder = Name.t EConstr.binder_annot * EConstr.types
type message = Pp.t
type err = Exninfo.iexn
type iexn = Exninfo.iexn
type exninfo = Exninfo.info

module Constant : sig
  type t = constant

  val equal : t -> t -> bool
  val print : t -> message
end

module Constr : sig
  type t = constr

  val type_ : Environ.env -> Evd.evar_map -> t -> Evd.evar_map * t
  val equal : Evd.evar_map -> t -> t -> bool

  module Binder : sig
    type t = binder
    type relevance = Sorts.relevance

    val make :
      Environ.env ->
      Evd.evar_map ->
      ident option ->
      constr ->
      (t, unit) result

    val unsafe_make :
      Name.t ->
      relevance ->
      constr ->
      t

    val name : t -> Name.t
    val type_ : t -> constr
    val relevance : t -> relevance
  end

  module Relevance : sig
    type t = Binder.relevance

    val equal : Evd.evar_map -> t -> t -> bool

    val relevant : t
    val irrelevant : t
  end

  module Unsafe : sig
    val kind :
      Evd.evar_map ->
      t ->
      ( t,
        t,
        Evd.esorts,
        Evd.einstance,
        Evd.erelevance )
        Constr.kind_of_term

    val make :
      (t, t, Evd.esorts, Evd.einstance, Evd.erelevance) Constr.kind_of_term ->
      t

    val check : Environ.env -> Evd.evar_map -> t -> Evd.evar_map * t
    (** TODO: Document raised exception *)

    val liftn : int -> int -> t -> t

    val substnl : EConstr.Vars.substl -> int -> t -> t

    val closenl : Evd.evar_map -> ident list -> int -> t -> t

    val closednl : Evd.evar_map -> int -> t -> bool

    val noccur_between :
      Evd.evar_map -> int -> int -> t -> bool

    type case = Constr.case_info

    val case :
      Environ.env -> inductive -> (case, unit) result

    module Case : sig
      val equal : case -> case -> bool
      val inductive : case -> inductive
    end
  end

  module Cast : sig
    type t = cast

    val default : t
    val vm : t
    val native : t

    val equal : t -> t -> bool
  end

  module Pretype : sig
    type expected_type = Pretyping.typing_constraint

    module Flags : sig
      type t = Pretyping.inference_flags

      val constr_flags : t

      val set_use_coercion : bool -> t -> t
      val set_use_typeclasses : bool -> t -> t
      val set_allow_evars : bool -> t -> t
      val set_nf_evars : bool -> t -> t
    end

    val expected_istype : expected_type

    val expected_oftype :
      constr -> expected_type

    val expected_without_type_constraint :
      expected_type

    val pretype :
      Environ.env ->
      Evd.evar_map ->
      Flags.t ->
      expected_type ->
      preterm ->
      Evd.evar_map * constr
  end

  val has_evar : Evd.evar_map -> t -> bool
end

module Constructor : sig
  type t = constructor

  val equal : t -> t -> bool

  val inductive : t -> inductive
  val index : t -> int
  val print : t -> message
end

module Control : sig
  val throw : iexn -> 'a Proofview.tactic

  val zero : iexn -> 'a Proofview.tactic

  val plus :
    'a Proofview.tactic ->
    (iexn -> 'a Proofview.tactic) ->
    'a Proofview.tactic

  val once : 'a Proofview.tactic -> 'a Proofview.tactic

  val case :
    'a Proofview.tactic ->
    'a Proofview.case Proofview.tactic

  val numgoals : int Proofview.tactic

  val dispatch :
    unit Proofview.tactic list ->
    unit Proofview.tactic

  val extend :
    unit Proofview.tactic list ->
    unit Proofview.tactic ->
    unit Proofview.tactic list ->
    unit Proofview.tactic

  val enter :
    unit Proofview.tactic -> unit Proofview.tactic

  val focus :
    int ->
    int ->
    'a Proofview.tactic ->
    'a Proofview.tactic

  val shelve : unit Proofview.tactic
  val shelve_unifiable : unit Proofview.tactic

  val unshelve :
    'a Proofview.tactic -> 'a Proofview.tactic

  val new_goal : Proofview_monad.goal -> unit Proofview.tactic
  val cycle : int -> unit Proofview.tactic
  val reorder_goals : Int.t list -> unit Proofview.tactic
  val goal : constr Proofview.tactic
  val hyp : Environ.env -> variable -> (constr, unit) result

  val hyp_value :
    Environ.env ->
    variable ->
    (constr option, unit) result

  val hyps :
    Environ.env ->
    (variable * constr option * constr) list

  val refine :
    (Evd.evar_map -> Evd.evar_map * constr) ->
    unit Proofview.tactic

  val with_holes :
    'a Proofview.tactic ->
    ('a -> 'b Proofview.tactic) ->
    'b Proofview.tactic

  val progress :
    'a Proofview.tactic -> 'a Proofview.tactic

  val abstract :
    ident option ->
    unit Proofview.tactic ->
    unit Proofview.tactic

  val time :
    string option ->
    'a Proofview.tactic ->
    'a Proofview.tactic

  val timeout :
    int -> 'a Proofview.tactic -> 'a Proofview.tactic

  val timeoutf :
    float ->
    'a Proofview.tactic ->
    'a Proofview.tactic

  val check_interrupt : unit Proofview.tactic
  val print_err : err -> message
end

module Env : sig
  val get : Libnames.full_path -> (GlobRef.t, unit) result
  val expand : Libnames.qualid -> GlobRef.t list

  val path : GlobRef.t -> (Libnames.full_path, unit) result

  val instantiate : Environ.env -> Evd.evar_map -> GlobRef.t -> Evd.evar_map * constr
end

module Evar : sig
  type t = evar

  val equal : t -> t -> bool
end

module Float : sig
  type t = Float64.t

  val equal : t -> t -> bool
end

module Fresh : sig
  module Free : sig
    type t = Nameops.Fresh.t

    val empty : t
    val add : ident -> t -> t

    val union : t -> t -> t

    val of_ids : ident list -> t
    val of_constr : Evd.evar_map -> constr -> t
  end

  val next : Free.t -> ident -> ident * Free.t
  val fresh : Free.t -> ident -> ident
end

module Ident : sig
  type t = ident

  val equal : ident -> ident -> bool
  val to_string : ident -> string
  val of_string : string -> ident option
end

module Ind : sig
  type t = inductive
  type data = inductive * Declarations.mutual_inductive_body

  val equal : t -> t -> bool

  val data : Environ.env -> t -> data

  val repr : data -> t
  val index : t -> int
  val nblocks : data -> int

  val nconstructors : data -> int

  val get_block : data -> int -> data option

  val get_constructor : data -> int -> constructor option

  val nparams : data -> int
  val nparams_uniform : data -> int

  val get_projections : data -> projection array option

  val constructor_nargs : data -> int array
  val constructor_ndecls : data -> int array

  val print : t -> message
end

module Message : sig
  val print : message -> unit
  val empty : message
  val of_string : string -> message
  val to_string : message -> string
  val of_int : int -> message
  val of_ident : ident -> message
  val of_constr : Environ.env -> Evd.evar_map -> constr -> message
  val of_lconstr : Environ.env -> Evd.evar_map -> constr -> message

  val of_preterm : Environ.env -> Evd.evar_map -> preterm -> message
  val of_lpreterm : Environ.env -> Evd.evar_map -> preterm -> message

  val of_exninfo : exninfo -> message

  val concat : message -> message -> message
  val force_new_line : message
  val break : int -> int -> message
  val space : message
  val hbox : message -> message
  val vbox : int -> message -> message
  val hvbox : int -> message -> message
  val hovbox : int -> message -> message
end

module Module : sig
  type t = ModPath.t

  val equal : t -> t -> bool
  val to_message : t -> message

  val is_modtype : Environ.env -> t -> bool
  val is_functor : Environ.env -> t -> bool
  val is_bound_module : t -> bool
  val is_library : t -> bool
  val is_open : t -> bool

  val parent_module : t -> t option

  val module_of_reference : GlobRef.t -> t

  val current_module : unit -> t
  val loaded_libraries : unit -> t list

  module Field : sig
    type t = Tac2ffi.ModField.t
  end

  val contents : t -> Field.t list option
end

module Pattern : sig
  type context = Constr_matching.context

  val empty_context : context

  val matches : Environ.env -> Evd.evar_map -> pattern -> constr -> Ltac_pretype.patvar_map option

  val matches_subterm : pattern -> constr -> (context * Ltac_pretype.patvar_map) Proofview.tactic

  val matches_goal :
    bool ->
    Tac2match.match_context_hyps list ->
    Tac2match.match_pattern ->
    ((ident * Tac2match.context option option * Tac2match.context option) list *
       Tac2match.context option *
         Ltac_pretype.patvar_map)
      Proofview.tactic

  val instantiate : context -> constr -> constr
end

module Proj : sig
  type t = projection

  val equal : t -> t -> bool

  val ind : t -> inductive
  val index : t -> int

  val unfolded : t -> bool
  val set_unfolded : t -> bool -> t

  val of_constant : constant -> t option
  val to_constant : t -> Projection.Repr.t option

  val print : t -> message
end

module Pstring : sig
  type t = pstring

  val max_length : uint63
  val to_string : t -> string
  val of_string : string -> t option
  val make : uint63 -> uint63 -> t
  val length : t -> uint63
  val get : t -> uint63 -> uint63
  val sub : t -> uint63 -> uint63 -> t
  val cat : t -> t -> t
  val equal : t -> t -> bool
  val compare : t -> t -> int
end

module Rewrite : sig
  module Strategy : sig
    type t = Rewrite.strategy

    val id : t
    val fail : t
    val refl : t
    val progress : t -> t

    val seq : t -> t -> t
    val seqs : t list -> t

    val choice : t -> t -> t
    val choices : t list -> t

    val try_ : t -> t

    val fix_ : Tac2val.closure -> t Proofview.tactic

    val any : t -> t
    val repeat : t -> t
    val one_subterm : t -> t
    val all_subterms : t -> t
    val bottomup : t -> t
    val topdown : t -> t
    val innermost : t -> t
    val outermost : t -> t
    val hints : ident -> t
    val old_hints : ident -> t

    val one_lemma : preterm -> bool -> t

    val lemmas : preterm list -> t

    val fold : constr -> t
    val eval : Redexpr.red_expr -> t
    val matches : pattern -> t

    val tactic :
      (constr ->
       constr ->
       constr option ->
       Rewrite.Result.t Proofview.tactic) ->
      t
  end

  val rewrite_strat :
    Strategy.t ->
    ident option ->
    unit Proofview.tactic
end

module Scheme : sig
  type kind = string

  val lookup : kind -> GlobRef.t -> GlobRef.t option

  val rect_dep : kind
  val rec_dep : kind
  val ind_dep : kind
  val sind_dep : kind
  val ind_nodep : kind
  val rec_nodep : kind
  val rect_nodep : kind
  val sind_nodep : kind
  val eq_dec : kind
  val dec_lb : kind
  val dec_bl : kind
  val beq : kind
  val congr : kind
  val rew_fwd_r_dep : kind
  val rew_r_dep : kind
  val rew_r : kind
  val rew_fwd_dep : kind
  val rew_dep : kind
  val rew : kind
  val sym_involutive : kind
  val sym : kind
  val scase_nodep : kind
  val scase_dep : kind
  val casep_nodep : kind
  val casep_dep : kind
  val case_nodep : kind
  val case_dep : kind
end

module Std : sig
  type hypothesis = Tac2types.quantified_hypothesis
  type bindings = Tac2types.bindings
  type constr_with_bindings = Tac2types.constr_with_bindings
  type occurrences = Tac2types.occurrences
  type hyp_location_flag = Tac2types.hyp_location_flag
  type clause = Tac2types.clause
  type reference = GlobRef.t
  type strength = Genredexpr.strength
  type red_flags = Tac2types.red_flag
  type intro_pattern = Tac2types.intro_pattern
  and intro_pattern_naming = Tac2types.intro_pattern_naming
  and intro_pattern_action = Tac2types.intro_pattern_action
  and or_and_intro_pattern = Tac2types.or_and_intro_pattern
  type destruction_arg = Tac2types.destruction_arg
  type induction_clause = Tac2types.induction_clause
  type assertion = Tac2types.assertion
  type repeat = Equality.multi
  type orientation = Tac2types.orientation
  type rewriting = Tac2types.rewriting
  type evar_flag = Tac2types.evars_flag
  type advanced_flag = Tac2types.advanced_flag
  type move_location = Id.t Logic.move_location
  type inversion_kind = Inv.inversion_kind

  val intros :
    evar_flag ->
    intro_pattern list ->
    unit Proofview.tactic

  val apply :
    advanced_flag ->
    evar_flag ->
    (unit -> constr_with_bindings Proofview.tactic) list ->
    (ident * intro_pattern option) option ->
    unit Proofview.tactic

  val elim :
    evar_flag ->
    constr_with_bindings ->
    constr_with_bindings option ->
    unit Proofview.tactic

  val case :
    evar_flag ->
    constr_with_bindings ->
    unit Proofview.tactic

  val generalize :
    (constr * occurrences * Name.t) list ->
    unit Proofview.tactic

  val assert_ : assertion -> unit Proofview.tactic

  val enough :
    constr ->
    unit Proofview.tactic option option ->
    intro_pattern option ->
    unit Proofview.tactic
  (** TODO: Remove option option. *)

  val pose : Name.t -> constr -> unit Proofview.tactic

  val set :
    evar_flag ->
    (Name.t * constr) Proofview.tactic ->
    clause ->
    unit Proofview.tactic

  val remember :
    evar_flag ->
    Name.t ->
    constr ->
    intro_pattern_naming option ->
    clause ->
    unit Proofview.tactic

  val destruct :
    evar_flag ->
    induction_clause list ->
    constr_with_bindings option ->
    unit Proofview.tactic

  val induction :
    evar_flag ->
    induction_clause list ->
    constr_with_bindings option ->
    unit Proofview.tactic

  val exfalso : unit Proofview.tactic

  module Red : sig
    type t = Redexpr.red_expr

    val red : t
    val hnf : t

    val simpl :
      red_flags ->
      Tac2types.red_context ->
      t Proofview.tactic

    val cbv : red_flags -> t Proofview.tactic
    val cbn : red_flags -> t Proofview.tactic
    val lazy_ : red_flags -> t Proofview.tactic

    val unfold :
      (reference * occurrences) list ->
      t Proofview.tactic

    val fold : constr list -> t

    val pattern : (constr * occurrences) list -> t

    val vm : Tac2types.red_context -> t
    val native : Tac2types.red_context -> t
  end

  val eval_in :
    Red.t ->
    clause ->
    unit Proofview.tactic

  val eval :
    Red.t ->
    constr ->
    constr Proofview.tactic

  val change :
    pattern option ->
    (constr array -> constr Proofview.tactic) ->
    clause ->
    unit Proofview.tactic

  val rewrite :
    evar_flag ->
    rewriting list ->
    clause ->
    (unit -> unit Proofview.tactic) option ->
    unit Proofview.tactic

  val setoid_rewrite :
    orientation ->
    constr_with_bindings Proofview.tactic ->
    occurrences ->
    ident option ->
    unit Proofview.tactic

  val reflexivity : unit Proofview.tactic

  val assumption : unit Proofview.tactic
  val eassumption : unit Proofview.tactic
  val transitivity : constr -> unit Proofview.tactic
  val etransitivity : unit Proofview.tactic
  val cut : constr -> unit Proofview.tactic

  val left :
    evar_flag -> bindings -> unit Proofview.tactic

  val right :
    evar_flag -> bindings -> unit Proofview.tactic

  val constructor : evar_flag -> unit Proofview.tactic

  val split :
    evar_flag -> bindings -> unit Proofview.tactic

  val constructor_n :
    evar_flag -> int -> bindings -> unit Proofview.tactic

  val intros_until :
    hypothesis -> unit Proofview.tactic

  val symmetry : clause -> unit Proofview.tactic

  val rename :
    (ident * ident) list -> unit Proofview.tactic

  val revert : ident list -> unit Proofview.tactic

  val admit : unit Proofview.tactic

  val fix : ident -> int -> unit Proofview.tactic
  val cofix : ident -> unit Proofview.tactic

  val clear : ident list -> unit Proofview.tactic
  val keep : ident list -> unit Proofview.tactic

  val clearbody : ident list -> unit Proofview.tactic

  val exact_no_check :
    constr -> unit Proofview.tactic
  val vm_cast_no_check :
    constr -> unit Proofview.tactic
  val native_cast_no_check :
    constr -> unit Proofview.tactic

  val inversion :
    Inv.inversion_kind ->
    destruction_arg ->
    intro_pattern option ->
    ident list option ->
    unit Proofview.tactic

  val move :
    ident ->
    move_location ->
    unit Proofview.tactic

  val intro :
    ident option ->
    move_location option ->
    unit Proofview.tactic

  val specialize :
    constr_with_bindings ->
    intro_pattern option ->
    unit Proofview.tactic

  val discriminate :
    evar_flag ->
    destruction_arg option ->
    unit Proofview.tactic

  val injection :
    evar_flag ->
    intro_pattern list option ->
    destruction_arg option ->
    unit Proofview.tactic

  val absurd : constr -> unit Proofview.tactic
  val contradiction :
    constr_with_bindings option ->
    unit Proofview.tactic

  val autorewrite :
    bool ->
    unit Proofview.tactic option ->
    ident list ->
    clause ->
    unit Proofview.tactic

  val subst : ident list -> unit Proofview.tactic
  val subst_all : unit Proofview.tactic

  type debug = Hints.debug
  type strategy = Class_tactics.search_strategy

  val trivial :
    debug ->
    reference list ->
    ident list option ->
    unit Proofview.tactic

  val auto :
    debug ->
    int option ->
    reference list ->
    ident list option ->
    unit Proofview.tactic

  val eauto :
    debug ->
    int option ->
    reference list ->
    ident list option ->
    unit Proofview.tactic

  val typeclasses_eauto :
    strategy option ->
    int option ->
    ident list option ->
    unit Proofview.tactic

  val resolve_tc : constr -> unit Proofview.tactic

  val unify :
    constr -> constr -> unit Proofview.tactic

  val congruence :
    int option ->
    constr list option ->
    unit Proofview.tactic

  val simple_congruence :
    int option ->
    constr list option ->
    unit Proofview.tactic

  val f_equal : unit Proofview.tactic
end

module Uint63 : sig
  type t = uint63

  val of_int : int -> t

  val equal : t -> t -> bool
  val compare : t -> t -> int

  val print : t -> message
end

module TransparentState : sig
  type t = TransparentState.t
  type strategy_level = Conv_oracle.level

  val empty : t
  val full : t
  val current : unit -> t Proofview.tactic

  val union : t -> t -> t
  val inter : t -> t -> t
  val diff : t -> t -> t

  val add_constant : constant -> t -> t
  val add_proj : projection -> t -> t
  val add_var : ident -> t -> t

  val remove_constant : constant -> t -> t
  val remove_proj : projection -> t -> t
  val remove_var : ident -> t -> t

  val mem_constant : constant -> t -> bool
  val mem_proj : projection -> t -> bool
  val mem_var : ident -> t -> bool

  val with_strategy :
    strategy_level ->
    GlobRef.t list ->
    'a Proofview.tactic ->
    'a Proofview.tactic
end

module Unification : sig
  type conv_flag = Evd.conv_pb

  val conv :
    Environ.env ->
    Evd.evar_map ->
    conv_flag ->
    TransparentState.t ->
    constr ->
    constr ->
    Evd.evar_map option

  val unify :
    TransparentState.t ->
    constr ->
    constr ->
    unit Proofview.tactic

  val solve_constraints : unit Proofview.tactic
end

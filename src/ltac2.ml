(** Re-exports of Rocq APIs under their Ltac2 name. *)

(** Methods in this file are taken from Ltac2's [Tac2core]
    and [Tac2stdlib] files. *)

open Util
open Names
open Ltac2_plugin
open Tac2types
open Proofview.Notations

let return = Proofview.tclUNIT
let throw = Tac2core.throw

(** {1 Ltac2 APIs} *)

(** {2 Printing} *)

module Ltac2Message = struct
  let print m = Feedback.msg_notice m

  let empty = Pp.mt ()

  let of_int = Pp.int

  let of_string = Pp.str

  let to_string = Pp.string_of_ppcmds

  let of_constr env sigma c =
    Printer.pr_econstr_env env sigma c

  let of_lconstr env sigma c =
    Printer.pr_leconstr_env env sigma c

  let of_preterm env sigma c =
    Printer.pr_closed_glob_env env sigma c

  let of_lpreterm env sigma c =
    Printer.pr_closed_lglob_env env sigma c

  let of_ident = Id.print

  let of_exninfo = CErrors.print_extra

  let concat = Pp.app

  let force_new_line = Pp.fnl ()

  let break i j = Pp.brk (i, j)

  let space = Pp.spc ()

  let hbox = Pp.h

  let vbox = Pp.v

  let hvbox = Pp.hv

  let hovbox = Pp.hov

end

(** {2 Identifiers} *)

module Ltac2Ident = struct
  type t = Id.t
  let equal = Id.equal

  let to_string = Id.to_string

  let of_string s =
    try Some (Id.of_string s)
    with e when CErrors.noncritical e -> None
end

(** {2 Pstring} *)

module Ltac2Pstring = Pstring

(** {2 Terms} *)

module Ltac2Constr = struct
  type t = EConstr.t

  let type_ env sigma c =
    Typing.type_of env sigma c

  let equal sigma c1 c2 =
    EConstr.eq_constr sigma c1 c2

  module Unsafe = struct
    let kind sigma c =
      EConstr.kind sigma c

    let make knd =
      EConstr.of_kind knd

    let check env sigma c =
      let (sigma, _) = Typing.type_of env sigma c in
      (sigma, c)

    let liftn = EConstr.Vars.liftn

    let substnl = EConstr.Vars.substnl

    let closenl sigma ids k c =
      EConstr.Vars.substn_vars sigma k ids c

    let closednl sigma n c =
      EConstr.Vars.closedn sigma n c

    let noccur_between sigma n m c =
      EConstr.Vars.noccur_between sigma n m c

    let case env ind =
      try Ok (Inductiveops.make_case_info env ind Constr.MatchStyle)
      with e when CErrors.noncritical e ->
        Error ()

    type case = Constr.case_info

    module Case = struct
      open Constr

      let equal x y = Ind.UserOrd.equal x.ci_ind y.ci_ind
      let inductive case = case.ci_ind
    end
  end

  module Binder = struct
    type t = Tac2ffi.binder
    type relevance = Sorts.relevance

    let make env sigma na ty =
      match Retyping.relevance_of_type env sigma ty with
      | rel ->
         let na = match na with None -> Anonymous | Some id -> Name id in
         Ok (Context.make_annot na rel, ty)
      | exception (Retyping.RetypeError _) ->
         Error ()

    let unsafe_make na rel ty =
      Context.make_annot na (EConstr.ERelevance.make rel), ty

    let name (bnd, _) =
      bnd.Context.binder_name

    (* type is a reserved keyword *)
    let type_ (_, ty) = ty

    let relevance (na, _) = EConstr.Unsafe.to_relevance na.Context.binder_relevance
  end

  module Cast = struct
    type t = Constr.cast_kind
    let equal = Glob_ops.cast_kind_eq

    let default = Constr.DEFAULTcast
    let vm      = Constr.VMcast
    let native  = Constr.NATIVEcast
  end

  module Pretype = struct
    open Pretyping
    type expected_type = Pretyping.typing_constraint

    module Flags = struct
      type t = Pretyping.inference_flags

      let constr_flags = {
          use_coercions = true;
          use_typeclasses = Pretyping.UseTC;
          solve_unification_constraints = true;
          fail_evar = true;
          expand_evars = true;
          program_mode = false;
          poly = PolyFlags.default;
          undeclared_evars_rr = false;
          unconstrained_sorts = false;
        }

      let set_use_coercion b (flags: t) =
        { flags with use_coercions = b }

      let set_use_typeclasses b flags =
        { flags with use_typeclasses = if b then UseTC else NoUseTC }

      let set_allow_evars b flags =
        { flags with fail_evar = not b }

      let set_nf_evars b flags =
        { flags with expand_evars = b }
    end

    let expected_istype = IsType
    let expected_oftype c = OfType c
    let expected_without_type_constraint = WithoutTypeConstraint

    let pretype env sigma flags expected_type c =
      Pretyping.understand_uconstr ~flags ~expected_type env sigma c
  end

  module Relevance = struct
    type t = Binder.relevance

    let equal sigma r1 r2 =
      EConstr.ERelevance.(equal sigma (make r1) (make r2))

    let relevant = Sorts.Relevant

    let irrelevant = Sorts.Irrelevant
  end

  let has_evar sigma c =
    Evarutil.has_undefined_evars sigma c
end

(** {2 Uint63} *)

module Ltac2Uint63 = struct
  type t = Uint63.t
  let equal = Uint63.equal
  let compare = Uint63.compare

  let of_int = Uint63.of_int

  let print i = Pp.str (Uint63.to_string i)
end

(** {2 Evar} *)

module Ltac2Evar = Evar

(** {2 Float} *)

module Ltac2Float = Float64

(** {2 Meta} *)

module Ltac2Meta = Int

(** {2 Constant} *)

module Ltac2Constant = struct
  type t = Constant.t
  let equal = Constant.UserOrd.equal

  let print c = Nametab.pr_global_env Id.Set.empty (ConstRef c)
end

(** {2 Patterns} *)

module Ltac2Pattern = struct
  type context = Constr_matching.context
  let empty_context = Constr_matching.empty_context

  let matches env sigma pat c =
    try Some (Constr_matching.matches env sigma pat c)
    with Constr_matching.PatternMatchingFailure -> None

  let matches_subterm pat c =
    let open Constr_matching in
    let rec of_ans s = match IStream.peek s with
      | IStream.Nil -> Proofview.tclZERO Constr_matching.PatternMatchingFailure
      | IStream.Cons ({ m_sub = (_, sub); m_ctx }, s) ->
         Proofview.tclOR (return (m_ctx, sub)) (fun _ -> of_ans s)
    in
    (* Use pf_apply to match in the current goal *)
    Tac2core.pf_apply begin fun env sigma ->
      let ans = Constr_matching.match_subterm env sigma (Id.Set.empty,pat) c in
      of_ans ans
    end

  let matches_goal rev hp cp =
    Proofview.Goal.enter_one begin fun gl ->
      let env = Proofview.Goal.env gl in
      let sigma = Proofview.Goal.sigma gl in
      let concl = Proofview.Goal.concl gl in
      Tac2match.match_goal env sigma concl ~rev (hp, cp)
    end

  let instantiate = Constr_matching.instantiate_context
end

(** {2 Control} *)

module Ltac2Control = struct
  let zero (e, info) = Proofview.tclZERO ~info e

  let plus = Proofview.tclOR

  let once = Proofview.tclONCE

  let case = Proofview.tclCASE

  let numgoals = Proofview.numgoals

  let dispatch = Proofview.tclDISPATCH

  let extend = Proofview.tclEXTEND

  let enter = Proofview.tclINDEPENDENT

  (* Eta-expand to remove optional argument. *)
  let focus i j t = Proofview.tclFOCUS i j t

  let cycle = Proofview.cycle

  let shelve = Proofview.shelve

  let shelve_unifiable = Proofview.shelve_unifiable

  let new_goal ev =
    (* TODO: Upstream *)
    Proofview.tclEVARMAP >>= fun sigma ->
    let sigma = Evd.remove_future_goal sigma ev in
    let sigma = Evd.unshelve sigma [ev] in
    Proofview.Unsafe.tclEVARS sigma <*>
      Proofview.Unsafe.tclNEWGOALS [Proofview.with_empty_state ev] <*>
      Proofview.tclUNIT ()

  let is_permutation len l =
    if not (Int.equal len (Array.length l)) then false else
      let items = Array.make len false in
      (* returns true iff [l] (seen as a 1-indexed list) maps ints in [1; len] to [1; len] injectively.
         Thanks to pigeonhole theorem this means [l] is a permutation of [1; len]. *)
      Array.for_all (fun x ->
          if 1 <= x && x <= len && not items.(x-1) then
            let () = items.(x-1) <- true in
            true
          else false)
        l

  let reorder_goals l =
    (* TODO: Upstream *)
    Proofview.Unsafe.tclGETGOALS >>= fun gls ->
    let len = List.length gls in
    let l = Array.of_list l in
    if not (is_permutation len l) then
      assert false
    else
      let gls = Array.of_list gls in
      let gls = List.init len (fun i -> gls.(l.(i) - 1)) in
      Proofview.Unsafe.tclSETGOALS gls

  let unshelve t =
    (* TODO: Upstream *)
    Proofview.with_shelf t >>= fun (gls,v) ->
    let gls = List.map Proofview.with_empty_state gls in
    Proofview.Unsafe.tclGETGOALS >>= fun ogls ->
    Proofview.Unsafe.tclSETGOALS (gls @ ogls) >>= fun () ->
    return v

  let goal =
    Proofview.Goal.enter_one (fun goal -> return (Proofview.Goal.concl goal))

  let hyp env id =
    if Environ.mem_named id env then Ok (EConstr.mkVar id)
    else Error ()

  let hyp_value env id =
    match EConstr.lookup_named id env with
    | d -> Ok (Context.Named.Declaration.get_value d)
    | exception Not_found -> Error ()

  let hyps env =
    let open Context in
    let open Named.Declaration in
    let f = function
      | LocalAssum (id, t) ->
         let t = EConstr.of_constr t in
         id.binder_name, None, t
      | LocalDef (id, c, t) ->
         let c = EConstr.of_constr c in
         let t = EConstr.of_constr t in
         id.binder_name, Some c, t
    in
    List.rev_map f (Environ.named_context env)

  let refine c = Refine.refine ~typecheck:true c

  let with_holes x f = Tacticals.tclRUNWITHHOLES false x f

  let progress = Proofview.tclPROGRESS

  (* Eta-expanded to remove optional arguments. *)
  let abstract id f = Abstract.tclABSTRACT id f

  let time = Proofview.tclTIME

  let timeout = Proofview.tclTIMEOUT

  let timeoutf = Proofview.tclTIMEOUTF

  let check_interrupt = Proofview.tclCHECKINTERRUPT

  let print_err (e, _) = CErrors.print e

  let throw (e, info) = Tac2core.throw ~info e
end

(** {2 Fresh names} *)

module Ltac2Fresh = struct
  module Free = struct
    type t = Nameops.Fresh.t
    let empty = Nameops.Fresh.empty

    let add = Nameops.Fresh.add

    let union = Nameops.Fresh.union

    let of_ids ids = List.fold_right Nameops.Fresh.add ids Nameops.Fresh.empty

    let of_constr sigma c =
      let rec fold accu c =
        match EConstr.kind sigma c with
        | Constr.Var id -> Nameops.Fresh.add id accu
        | _ -> EConstr.fold sigma fold accu c
      in
      fold Nameops.Fresh.empty c
  end

  (* for backwards compat reasons the ocaml and ltac2 APIs
     exchange the meaning of "fresh" and "next" *)
  let next avoid id =
    let id = Namegen.mangle_id id in
    Nameops.Fresh.fresh id avoid

  let fresh avoid id =
    let id = Namegen.mangle_id id in
    Nameops.Fresh.next id avoid
end

(** {2 Environment} *)

module Ltac2Env = struct
  let get path =
    try Ok (Nametab.global_of_path path)
    with Not_found -> Error ()

  let expand = Nametab.locate_all

  let path r =
    try Ok (Nametab.path_of_global r)
    with Not_found -> Error ()

  (* Eta-expanded to remove optional arguments *)
  let instantiate env sigma gr = Evd.fresh_global env sigma gr
end

(** {2 Inductives} *)

module Ltac2Ind = struct
  type t = Ind.t
  type data = t * Declarations.mutual_inductive_body
  let equal = Ind.UserOrd.equal

  let data env ind = ind, Environ.lookup_mind (fst ind) env

  let repr: data -> t = fst
  let index: t -> int = snd

  let nblocks (_, mib) = Array.length mib.Declarations.mind_packets

  let nconstructors ((_, n), mib) =
    Array.length Declarations.(mib.mind_packets.(n).mind_consnames)

  let get_block (ind, mib) n =
    if 0 <= n && n < Array.length mib.Declarations.mind_packets then
      Some ((fst ind, n), mib)
    else None

  let get_constructor ((mind, n), mib) i =
    let open Declarations in
    let ncons = Array.length mib.mind_packets.(n).mind_consnames in
    if 0 <= i && i < ncons then
      (* WARNING: In the ML API constructors are indexed from 1 for historical
         reasons, but Ltac2 uses 0-indexing instead. *)
      Some ((mind, n), i + 1)
    else
      None

  let nparams (_, mib) = mib.Declarations.mind_nparams

  let nparams_uniform (_, mib) = mib.Declarations.mind_nparams_rec

  let get_projections (ind,mib) =
    Declareops.inductive_make_projections ind mib
    |> Option.map (Array.map (fun (p,_) -> Projection.make p false))

  let constructor_nargs ((_,i),mib) =
    let open Declarations in
    mib.mind_packets.(i).mind_consnrealargs

  let constructor_ndecls ((_,i),mib) =
    let open Declarations in
    mib.mind_packets.(i).mind_consnrealdecls

  let print ind = Nametab.pr_global_env Id.Set.empty (IndRef ind)
end

(** {2 Constructor} *)

module Ltac2Constructor = struct
  type t = Construct.t

  let equal = Construct.UserOrd.equal

  let inductive (ind, _) = ind

  let index (_, i) =
    (* WARNING: ML constructors are 1-indexed but Ltac2 constructors are 0-indexed *)
    i-1

  let print ctor =
    Nametab.pr_global_env Id.Set.empty (ConstructRef ctor)
end

(** {2 Schemes} *)

module Ltac2Scheme = struct
  type kind = string

  let lookup = DeclareScheme.lookup_scheme_opt

  let rect_dep = "rect_dep"
  let rec_dep = "rec_dep"
  let ind_dep = "ind_dep"
  let sind_dep = "sind_dep"
  let ind_nodep = "ind_nodep"
  let rec_nodep = "rec_nodep"
  let rect_nodep = "rect_nodep"
  let sind_nodep = "sind_nodep"
  let eq_dec = "eq_dec"
  let dec_lb = "dec_lb"
  let dec_bl = "dec_bl"
  let beq = "beq"
  let congr = "congr"
  let rew_fwd_r_dep = "rew_fwd_r_dep"
  let rew_r_dep = "rew_r_dep"
  let rew_r = "rew_r"
  let rew_fwd_dep = "rew_fwd_dep"
  let rew_dep = "rew_dep"
  let rew = "rew"
  let sym_involutive = "sym_involutive"
  let sym = "sym"
  let scase_nodep = "scase_nodep"
  let scase_dep = "scase_dep"
  let casep_nodep = "casep_nodep"
  let casep_dep = "casep_dep"
  let case_nodep = "case_nodep"
  let case_dep = "case_dep"
end

(** {2 Projection} *)

module Ltac2Proj = struct
  type t = Projection.t
  let equal = Projection.UserOrd.equal
  let ind = Projection.inductive

  let index = Projection.arg

  let unfolded = Projection.unfolded

  let set_unfolded p b = Projection.make (Projection.repr p) b

  let of_constant c =
    Structures.PrimitiveProjections.find_opt c |> Option.map (fun p -> Projection.make p false)

  let to_constant p = Some (Projection.constant p)

  let print p =
    Nametab.pr_global_env Id.Set.empty (ConstRef (Projection.constant p))
end

(** {2 Module} *)

module Ltac2Module = struct
  type t = ModPath.t
  let equal = ModPath.equal

  let to_message m =
    (* XXX use ModPath.print instead? (nametab is ambiguous since there's no single nametab)
       or expose ModPath.print as a separate external? *)
    try Nametab.Modules.pr m
    with Not_found ->
      try Nametab.ModTypes.pr m
      with Not_found ->
        try Nametab.OpenMods.pr (DirOpenModule m)
        with Not_found ->
          try Nametab.OpenMods.pr (DirOpenModtype m)
          with Not_found ->
            CErrors.anomaly Pp.(str "Unknown module or modtype " ++ ModPath.print m)

  let is_openmod m =
    ModPath.subpath m (Global.current_modpath())

  (* Find info about open module [m] in [senv_l] describing the open
     modules of some safe env with current module [senv_m].
     Returns [None] if [m] is the library, [Some v] if [m] is some inner open module. *)
  let rec find_openmod_aux m senv_m senv_l =
    let open ModPath in
    match senv_m, senv_l with
    | MPbound _, _ -> assert false
    | MPfile _, [] -> assert (ModPath.equal m senv_m); None
    | MPfile _, _ :: _ -> assert false
    | MPdot (m0, _), is_modtype :: rest ->
       if ModPath.equal m senv_m then Some is_modtype
       else find_openmod_aux m m0 rest
    | MPdot _, [] -> assert false

  let find_openmod m senv =
    find_openmod_aux m (Safe_typing.current_modpath senv)

  (* Assuming [m] is currently open, tell whether it is modtype. *)
  let open_module_is_modtype m =
    let senv = Global.safe_env() in
    match find_openmod m senv (Safe_typing.module_is_modtype senv) with
    | None -> false
    | Some b -> b

  let open_module_is_functor m =
    let senv = Global.safe_env() in
    match find_openmod m senv (Safe_typing.module_num_parameters senv) with
    | None -> false
    | Some nparams -> not (Int.equal nparams 0)

  let is_modtype m env _ =
    if is_openmod m then open_module_is_modtype m
    else
      try ignore (Environ.lookup_modtype m env); true
      with Not_found -> false

  let is_functor m env _ =
    if is_openmod m then open_module_is_functor m
    else
      let modbody_is_functor m = match Mod_declarations.mod_type m with
        | NoFunctor _ -> false
        | MoreFunctor _ -> true
      in
      match Environ.lookup_module m env with
      | m -> modbody_is_functor m
      | exception Not_found ->
         match Environ.lookup_modtype m env with
         | m -> modbody_is_functor m
         | exception Not_found -> assert false

  let is_bound_module = function
    | MPbound _ -> true
    | MPfile _ | MPdot _ -> false

  let is_library = function
    | MPfile _ -> true
    | MPbound _ | MPdot _ -> false

  let is_open = is_openmod

  let parent_module = function
    | MPdot (m, _) -> Some m
    | MPbound _ | MPfile _ -> None

  open GlobRef
  let module_of_reference = function
    | VarRef _ -> invalid_arg "module_of_reference"
    | ConstRef c -> Constant.modpath c
    | IndRef (mind,_) | ConstructRef ((mind,_),_) -> MutInd.modpath mind

  let current_module () = Global.current_modpath ()

  let loaded_libraries () =
    List.map (fun dp -> MPfile dp) (Library.loaded_libraries())

  module Field = struct
    open Tac2ffi
    open ModField

    type t = ModField.t

    let handle f handler =
      let (handle_submodule, handle_reference, handle_rewrule) = handler in
      match f with
      | Ref x -> handle_reference x
      | Submodule x -> handle_submodule x
      | Rewrule -> handle_rewrule ()
  end

  let openmod_revstruct m senv =
    let rec close senv modtype =
      let curm = Safe_typing.current_modpath senv in
      if ModPath.equal m curm then senv
      else
        let l = match curm with
          | MPdot (_, l) -> l
          | _ -> assert false
        in
        match modtype with
        | [] -> assert false
        | false :: modtype ->
           (* None: type constraint of submodule doesn't matter since we
              will anyway only return "Submodule M" and not look at its
              contents *)
           close (snd @@ Safe_typing.end_module l None senv) modtype
        | true :: modtype -> close (snd @@ Safe_typing.end_modtype l senv) modtype
    in
    let modtype = Safe_typing.module_is_modtype senv in
    let senv = close senv modtype in
    Safe_typing.structure_body_of_safe_env senv

  let contents m =
    let body =
      if is_open m then
        (* XXX not sure what this does with side effects *)
        Some (List.rev (openmod_revstruct m (Global.safe_env())))
      else
        match Environ.lookup_module m (Global.env()) with
        | exception Not_found -> (* modtype *) None
        | body -> match Mod_declarations.mod_type body with
                  | MoreFunctor _ -> (* functor *) None
                  | NoFunctor body -> Some body
    in
    let to_field (lab, f) : Tac2ffi.ModField.t = match (f:_ Declarations.structure_field_body) with
      | SFBconst _ ->
         let kn = KerName.make m lab in
         Ref (ConstRef (Global.constant_of_delta_kn kn))
      | SFBmind _ ->
         let kn = KerName.make m lab in
         Ref (IndRef ((Global.mind_of_delta_kn kn, 0)))
      | SFBrules _ -> Rewrule
      | SFBmodule _ -> Submodule (MPdot (m, lab))
      | SFBmodtype _ -> Submodule (MPdot (m, lab))
    in
    Option.map (List.map to_field) body
end

(** {2 Rewriting} *)

module Ltac2Rewrite = struct
  module Strategy = struct
    type t = Rewrite.strategy

    let id           = Rewrite.Strategies.id
    let fail         = Rewrite.Strategies.fail
    let refl         = Rewrite.Strategies.refl
    let progress     = Rewrite.Strategies.progress
    let seq          = Rewrite.Strategies.seq
    let seqs         = Rewrite.Strategies.seqs
    let choice       = Rewrite.Strategies.choice
    let choices      = Rewrite.Strategies.choices
    let try_         = Rewrite.Strategies.try_
    let fix_         = Tac2tactics.RewriteStrats.fix
    let any          = Rewrite.Strategies.any
    let repeat       = Rewrite.Strategies.repeat
    let one_subterm  = Rewrite.Strategies.one_subterm
    let all_subterms = Rewrite.Strategies.all_subterms
    let bottomup     = Rewrite.Strategies.bottomup
    let topdown      = Rewrite.Strategies.topdown
    let innermost    = Rewrite.Strategies.innermost
    let outermost    = Rewrite.Strategies.outermost
    let hints        = Tac2tactics.RewriteStrats.hints
    let old_hints    = Tac2tactics.RewriteStrats.old_hints
    let one_lemma    = Tac2tactics.RewriteStrats.one_lemma
    let lemmas       = Tac2tactics.RewriteStrats.lemmas
    let fold         = Rewrite.Strategies.fold
    let eval         = Rewrite.Strategies.reduce
    let matches      = Rewrite.Strategies.matches

    let tactic = Tac2tactics.wrap_tactic_call
  end

  let rewrite_strat = Tac2tactics.rewrite_strat
end

(** {2 Transparent state} *)

module Ltac2TransparentState = struct
  type t = TransparentState.t
  type strategy_level = Conv_oracle.level

  open TransparentState

  let empty = TransparentState.empty
  let full = TransparentState.full
  let current = Tac2tactics.current_transparent_state

  let union ts1 ts2 =
    { tr_var = Id.Pred.union ts1.tr_var ts2.tr_var ;
      tr_cst = Cpred.union ts1.tr_cst ts2.tr_cst ;
      tr_prj = PRpred.union ts1.tr_prj ts2.tr_prj }

  let inter ts1 ts2 =
    { tr_var = Id.Pred.inter ts1.tr_var ts2.tr_var ;
      tr_cst = Cpred.inter ts1.tr_cst ts2.tr_cst ;
      tr_prj = PRpred.inter ts1.tr_prj ts2.tr_prj }

  let diff ts1 ts2 =
    { tr_var = Id.Pred.diff ts1.tr_var ts2.tr_var ;
      tr_cst = Cpred.diff ts1.tr_cst ts2.tr_cst ;
      tr_prj = PRpred.diff ts1.tr_prj ts2.tr_prj }

  let add_constant c ts =
    { tr_var = ts.tr_var ;
      tr_cst = Cpred.add c ts.tr_cst ;
      tr_prj = ts.tr_prj }

  let add_proj p ts =
    { tr_var = ts.tr_var ;
      tr_cst = ts.tr_cst ;
      tr_prj = PRpred.add (Projection.repr p) ts.tr_prj }

  let add_var v ts =
    { tr_var = Id.Pred.add v ts.tr_var ;
      tr_cst = ts.tr_cst ;
      tr_prj = ts.tr_prj }

  let remove_constant c ts =
    { tr_var = ts.tr_var ;
      tr_cst = Cpred.remove c ts.tr_cst ;
      tr_prj = ts.tr_prj }

  let remove_proj p ts =
    { tr_var = ts.tr_var ;
      tr_cst = ts.tr_cst ;
      tr_prj = PRpred.remove (Projection.repr p) ts.tr_prj }

  let remove_var v ts =
    { tr_var = Id.Pred.remove v ts.tr_var ;
      tr_cst = ts.tr_cst ;
      tr_prj = ts.tr_prj }

  let mem_constant c ts = Cpred.mem c ts.tr_cst
  let mem_proj p ts = PRpred.mem (Projection.repr p) ts.tr_prj
  let mem_var v ts = Id.Pred.mem v ts.tr_var

  let with_strategy level grs tac = Tac2tactics.with_strategy level grs (fun () -> tac)
end

(** {2 Unification} *)

module Ltac2Unification = struct
  type conv_flag = Evd.conv_pb

  let conv env sigma pb ts c1 c2 =
    Reductionops.infer_conv ~pb ~ts env sigma c1 c2

  let unify = Tac2tactics.evarconv_unify

  let solve_constraints = Refine.solve_constraints
end

(** {2 Standard tactics} *)

module Ltac2Std = struct
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

  let intros = Tac2tactics.intros_patterns

  let apply = Tac2tactics.apply

  let elim = Tac2tactics.elim
  let case = Tac2tactics.general_case_analysis

  let generalize = Tac2tactics.generalize

  let assert_ = Tac2tactics.assert_
  let enough c tac ipat =
    Tac2tactics.forward false tac ipat c

  let pose na c = Tactics.letin_tac None na c None Locusops.nowhere

  let set ev p cl =
    Proofview.tclEVARMAP >>= fun sigma ->
    p >>= fun (na, c) ->
    Tac2tactics.letin_pat_tac ev None na (Some sigma, c) cl

  let remember ev na c eqpat cl =
    let eqpat = Option.default IntroAnonymous eqpat in
    Proofview.tclEVARMAP >>= fun sigma ->
    Tac2tactics.letin_pat_tac ev (Some (true, eqpat)) na (Some sigma, c) cl

  let destruct = Tac2tactics.induction_destruct false
  let induction = Tac2tactics.induction_destruct true

  let exfalso = Tactics.exfalso

  module Red = struct
    type t = Redexpr.red_expr

    let red = Genredexpr.Red
    let hnf = Genredexpr.Hnf
    let simpl = Tac2tactics.simpl
    let cbv = Tac2tactics.cbv
    let cbn = Tac2tactics.cbn
    let lazy_ = Tac2tactics.lazy_
    let unfold = Tac2tactics.unfold
    let fold cs = Genredexpr.Fold cs
    let pattern = Tac2tactics.pattern

    let vm = Tac2tactics.vm
    let native = Tac2tactics.native
  end

  let eval_in = Tac2tactics.reduce_in
  let eval = Tac2tactics.reduce_constr

  let change = Tac2tactics.change
  let rewrite = Tac2tactics.rewrite
  let setoid_rewrite = Tac2tactics.setoid_rewrite

  let inversion = Tac2tactics.inversion

  let reflexivity = Tactics.intros_reflexivity

  let move = Tactics.move_hyp

  let intro id mv =
    let mv = Option.default Logic.MoveLast mv in
    Tactics.intro_move id mv

  let specialize = Tac2tactics.specialize

  let assumption = Tactics.assumption
  let eassumption = Eauto.e_assumption

  let transitivity c = Tactics.intros_transitivity (Some c)
  let etransitivity = Tactics.intros_transitivity None

  let cut = Tactics.cut

  let left = Tac2tactics.left_with_bindings
  let right = Tac2tactics.right_with_bindings

  let intros_until = Tactics.intros_until

  let exact_no_check = Tactics.exact_no_check
  let vm_cast_no_check = Tactics.vm_cast_no_check
  let native_cast_no_check = Tactics.native_cast_no_check

  let constructor ev = Tactics.any_constructor ev None
  let constructor_n ev n bnd = Tac2tactics.constructor_tac ev None n bnd

  let symmetry = Tac2tactics.symmetry

  let split = Tac2tactics.split_with_bindings
  let rename = Tactics.rename_hyp

  let revert = Generalize.revert
  let admit = Proofview.give_up

  let fix = FixTactics.fix
  let cofix = FixTactics.cofix

  let clear = Tactics.clear
  let keep = Tactics.keep
  let clearbody = Tactics.clear_body

  let discriminate = Tac2tactics.discriminate
  let injection = Tac2tactics.injection

  let absurd = Contradiction.absurd
  let contradiction = Tac2tactics.contradiction

  let autorewrite all by ids cl =
    (* Thunk the tactic *)
    let by = Option.map (fun by -> fun () -> by) by in
    Tac2tactics.autorewrite ~all by ids cl

  let subst = Equality.subst
  let subst_all = Equality.subst_all ()

  type debug = Hints.debug
  type strategy = Class_tactics.search_strategy

  let trivial = Tac2tactics.trivial
  let auto = Tac2tactics.auto
  let eauto = Tac2tactics.eauto
  let typeclasses_eauto = Tac2tactics.typeclasses_eauto

  let resolve_tc = Class_tactics.resolve_tc

  let unify = Tac2tactics.unify

  let congruence = Tac2tactics.congruence
  let simple_congruence = Tac2tactics.simple_congruence

  let f_equal = Tac2tactics.f_equal
end

(** {1 Ltac2 API} *)

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

module Constant         = Ltac2Constant
module Constr           = Ltac2Constr
module Constructor      = Ltac2Constructor
module Control          = Ltac2Control
module Env              = Ltac2Env
module Evar             = Ltac2Evar
module Float            = Ltac2Float
module Fresh            = Ltac2Fresh
module Ident            = Ltac2Ident
module Ind              = Ltac2Ind
module Message          = Ltac2Message
module Module           = Ltac2Module
module Pattern          = Ltac2Pattern
module Proj             = Ltac2Proj
module Pstring          = Ltac2Pstring
module Rewrite          = Ltac2Rewrite
module Scheme           = Ltac2Scheme
module Std              = Ltac2Std
module Uint63           = Ltac2Uint63
module TransparentState = Ltac2TransparentState
module Unification      = Ltac2Unification

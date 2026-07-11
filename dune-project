(lang dune 3.17)
(using coq 0.10)

(generate_opam_files true)
(subst disabled) ;; Work-around for Dune 3.17 subst bug: https://github.com/ocaml/dune/issues/11045

(name mltac2)
(authors "Dario Halilovic" "Pierre-Marie Pédrot")
(maintainers "Dario Halilovic")
(license LGPL-2.1-only)

(homepage "https://github.com/epfl-systemf/mltac2")
(source
 (github epfl-systemf/mltac2))
(bug_reports "https://github.com/epfl-systemf/mltac2/issues")

(package
 (name mltac2)
 (synopsis "Ltac2 APIs in OCaml")
 (depends
   (rocq-runtime (>= 9.2))
   ppx_optcomp))

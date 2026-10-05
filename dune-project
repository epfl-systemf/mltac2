(lang dune 3.17)

(generate_opam_files true)

;; Work-around for Dune 3.17 subst bug: https://github.com/ocaml/dune/issues/11045
;; LATER: bump to Dune 3.21 once we no longer use Rocq 9.2 in CI
(subst disabled)

(name rocq-mltac2)
(version 1.0.0)
(authors "Dario Halilovic" "Pierre-Marie Pédrot")
(maintainers "Dario Halilovic")
(license LGPL-2.1-only)

(homepage "https://github.com/epfl-systemf/mltac2")
(source
 (github epfl-systemf/mltac2))
(bug_reports "https://github.com/epfl-systemf/mltac2/issues")

(package
 (name rocq-mltac2)
 (synopsis "Ltac2 APIs in OCaml")
 (depends
   (coq-core (>= 9.0)) ;; Use coq-core to obtain coqc compatibility binaries
   (dune (< 3.24)) ;; Dune 3.24 removes "%{coq:version}" variables
   ppx_optcomp))

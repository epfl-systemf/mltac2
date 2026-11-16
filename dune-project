(lang dune 3.21)

(generate_opam_files true)

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
 (description "MLtac2 is a simple library that packages part of the Ltac2 APIs \
for use in OCaml plugins.

MLtac2 provides:

1. A set of meta-programming APIs for interacting with Rocq that are guaranteed to be **stable across Rocq versions**;
2. A simple entry-point for meta-programming and discovering Rocq APIs;
3. Standard tactics from Ltac2 with Ltac2-like syntax (`Syntax` module).

MLtac2 strives to guarantee *source compatibility*, i.e., code written using MLtac2 \
will work on later Rocq versions with no changes. We thus keep one version of the \
Ltac2 APIs per Rocq version, and MLtac2 chooses the correct version at compile-time \
for your version of Rocq.

In the future, we may add new functions to the API, but we do not modify the signature \
of existing functions from the API. The only exception to this rule is that **optional \
arguments** may be added to functions to implement new features. It is thus recommended \
to not annotate the type of partially applied functions from MLtac2.")
 (tags
  ("category:Miscellaneous/Rocq Extensions"
   "keyword:ocaml"
   "keyword:tactic"
   "keyword:ltac2"))
 (depends
   (ocaml (>= 4.14))
   (rocq-core (>= 9.0))
   ppx_optcomp))

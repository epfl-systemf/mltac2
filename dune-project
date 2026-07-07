(lang dune 3.21)

(name mltac2)

(generate_opam_files true)

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
   rocq-runtime))

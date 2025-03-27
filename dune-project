(lang dune 3.0)
(generate_opam_files true)

(name ancient)
(authors "Richard Jones et.al.")
(maintainers "Fabrice Le Fessant <fabrice.le_fessant@ocamlpro.com>")
(homepage "https://github.com/OCamlPro/ocaml-ancient")
(bug_reports "https://github.com/OCamlPro/ocaml-ancient/issues")

(package
  (name ancient)
  (synopsis "Use data structures larger than available memory")
  (description "\
This module allows you to use in-memory data structures which are
larger than available memory and so are kept in swap.  If you try this
in normal OCaml code, you'll find that the machine quickly descends
into thrashing as the garbage collector repeatedly iterates over
swapped memory structures.  This module lets you break that
limitation.  Of course the module doesn't work by magic :-) If your
program tries to access these large structures, they still need to be
swapped back in, but it is suitable for large, sparsely accessed
structures.

Secondly, this module allows you to share those structures between
processes.  In this mode, the structures are backed by a disk file,
and any process that has read/write access that disk file can map that
file in and see the structures.")
  (license "LGPL-2.1-or-later WITH OCaml-LGPL-linking-exception"))

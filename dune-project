(lang dune 2.8)
(generate_opam_files true)

(name ppx_shared)
(source (github art-w/ppx_shared))
(license MIT)
(authors "Arthur Wendling")
(maintainers "art.wendling@gmail.com")
(version 0.1)

(package
  (name ppx_shared)
  (synopsis "Interleaved client/server code extraction")
  (depends
    (ocaml (>= "4.08"))
    (ppxlib (>= "0.23.0"))))

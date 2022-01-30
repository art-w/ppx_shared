When writing client/server applications, it's convenient to share selected code between the two. You may be able to achieve this by extracting the common code in a shared library. But for exploratory programming, it can be useful to define the client and server interleaved in the same files.

This ppx rewriter provides `%client` and `%server` ppx annotations:

```ocaml
let%client c = "client only"
let%server s = "server only"

let shared_by_default x = x
```

From which you can extract two distinct versions:

<table>
<tr>
<th><code>(pps ppx_shared.client)</code></th>
<th><code>(pps ppx_shared.server)</code></th>
</tr>
<tr><td>

```ocaml
let c = "client only"

let shared_by_default x = x
```

</td><td>

```ocaml
let s = "server only"

let shared_by_default x = x
```

</td></tr></table>

Since the code is duplicated, this allows the client and server to be compiled with different libraries or even compilers (for example `js_of_ocaml`).

See **[`example.ml`](examples/example.ml)** for annotating expressions, modules, types, or even blocks of code:

- `let%client x = ...`, `val%client x : ...`, `module%client M = ...`, `type%client t = ...` for definitions available only on the client
- `[%%client let x = 1 let y = 2]` for multiple definitions
- `instr ;%client rest` if the instruction `instr` must only evaluate on the client
- `(expr [@client other])` to compute `expr` on the server and `other` on the client
- `(typ [@client: other])` to specify the type `typ` on the server and `other` on the client
- `open M [@client Alt]` to open the module `M` on the server and `Alt` on the client

Finally, you can replace `%client` by `%server` to exchange the semantic!

Integration with dune requires a bit of care, as it doesn't like to reuse the same module in two different contexts. A simple solution is to create directories for the client and/or server, with a `dune` file responsible for importing the modules from a shared `src/` directory:

```lisp
(executable
  (name example)
  (preprocess (pps ppx_shared.client)))

; replicate the sources!
(copy_files ../src/*.ml)
(copy_files ../src/*.mli)

; or one by one with:
(rule (copy ../src/origin.ml dest.ml))
```

This ppx is inspired by the [Eliom syntax extension for Ocsigen](https://ocsigen.org/eliom/latest/manual/ppx-syntax), with a few differences:

- Code is assumed to be shared by the client and server by default: there is no explicit `%shared` annotations
- No runtime mechanism is provided for exchanging values between the client and the server, as this depends on your protocol. You can explicitly annotate expressions to smooth this communication, assuming some suitable definition of `send` and `receive`:

  ```ocaml
  let msg = send "hello from the server" [@client receive ()] in ...
  ```

This ppx is also similar to [ppx_inline_test](https://github.com/janestreet/ppx_inline_test) as you could use the `%client` annotation to specify unit tests (that will not be present in the final "server" version of the code). See [`ppx_shared_client.ml`](src/ppx_shared_client.ml) for how you can use `ppx_shared` as a library to create your own ppx with custom aliases:

```ocaml
let () =
  Ppx_shared.keep "release" ; (* to keep all code annotated by [%release] *)
  Ppx_shared.remove "debug" (* to remove all code annotated by [%debug] *)
```

```ocaml
let%debug check name cond = (* a custom assert only available in debug mode *)
  if not cond then failwith name

let%debug () = check "root" (sqrt 4.0 = 2.0)
```

let%client var = "client only"
let%server var = "server only"

let () = Printf.printf "let binding: %s\n%!" var

[%%client
let client_only = "client only"
let () = Printf.printf "block client: %s\n%!" client_only]

[%%server
let server_only = "server only"
let () = Printf.printf "block server: %s\n%!" server_only]

let expr = String.uppercase_ascii ("server" [@client "client"])
let () = Printf.printf "expression: %s\n%!" expr

let () =
  Printf.printf "instruction: server\n%!" ;%server
  Printf.printf "instruction: client\n%!" ;%client
  ()

module%client Client = struct
  let module_name = "module Client"
end

module%server Server = struct
  let module_name = "module Server"
end

open Server [@client Client]

let () = Printf.printf "open: %s\n%!" module_name

open Client [@server Server]

let () = Printf.printf "open: %s\n%!" module_name

module Included = struct
  include Client [@server Server]

  let () = Printf.printf "include: %s\n%!" module_name
end

module Sig : sig
  val%client client : string
  val%server server : string

  val both : string
end = struct
  let%client client = "client"
  let%server server = "server"

  let both = "both"
end

let%client () = Printf.printf "Sig.client = %S and %S\n%!" Sig.client Sig.both
let%server () = Printf.printf "Sig.server = %S and %S\n%!" Sig.server Sig.both

module Alt = struct
  let value1 = "client1"
  let value2 = "client2"
end [@server
      let value1 = "server1"
      let value2 = "server2"]

let () = Printf.printf "Alt.value = %S and %S\n%!" Alt.value1 Alt.value2

type%client client = Client

type both = Both of (client[@server: unit])

let mixed_type = Both (() [@client Client])

let%client to_string = function
  | Both Client -> "client"

let%server to_string = function
  | Both () -> "server"

let () = Printf.printf "to_string mixed_type: %S\n%!" (to_string mixed_type)

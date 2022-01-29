let erased_str ~loc ~path:_ payload =
  { Ppxlib_ast.Ast.pstr_desc =
      Pstr_attribute
        { attr_name = { loc; txt = "erased" }
        ; attr_payload = PStr payload
        ; attr_loc = loc
        }
  ; pstr_loc = loc
  }

let erased_sig ~loc ~path:_ payload =
  { Ppxlib_ast.Ast.psig_desc =
      Psig_attribute
        { attr_name = { loc; txt = "erased" }
        ; attr_payload = PSig payload
        ; attr_loc = loc
        }
  ; psig_loc = loc
  }

let erase_str target =
  Ppxlib.Extension.declare
    target
    Ppxlib.Extension.Context.structure_item
    Ppxlib.Ast_pattern.(pstr __)
    erased_str

let erase_sig target =
  Ppxlib.Extension.declare
    target
    Ppxlib.Extension.Context.signature_item
    Ppxlib.Ast_pattern.(psig __)
    erased_sig

let remove target =
  Ppxlib.Driver.register_transformation
    target
    ~extensions:[ erase_str target; erase_sig target ]

let kept_str ~loc ~path:_ payload =
  match payload with
  | [ payload ] -> payload
  | _ ->
    let open Ppxlib_ast.Ast in
    let pstr_desc =
      Pstr_include
        { pincl_mod =
            { pmod_desc = Pmod_structure payload; pmod_loc = loc; pmod_attributes = [] }
        ; pincl_loc = loc
        ; pincl_attributes = []
        }
    in
    { pstr_desc; pstr_loc = loc }

let kept_sig ~loc ~path:_ payload =
  match payload with
  | [ payload ] -> payload
  | _ ->
    let open Ppxlib_ast.Ast in
    let psig_desc =
      Psig_include
        { pincl_mod =
            { pmty_desc = Pmty_signature payload; pmty_loc = loc; pmty_attributes = [] }
        ; pincl_loc = loc
        ; pincl_attributes = []
        }
    in
    { psig_desc; psig_loc = loc }

let keep_str target =
  Ppxlib.Extension.declare
    target
    Ppxlib.Extension.Context.structure_item
    Ppxlib.Ast_pattern.(pstr __)
    kept_str

let keep_sig target =
  Ppxlib.Extension.declare
    target
    Ppxlib.Extension.Context.signature_item
    Ppxlib.Ast_pattern.(psig __)
    kept_sig

let contains_attr target attrs =
  List.find_opt
    (fun my_attr ->
      let open Ppxlib_ast.Ast in
      String.equal my_attr.attr_name.txt target)
    attrs

let map_exprs target =
  object
    inherit Ppxlib.Ast_traverse.map as super

    method! expression expr =
      let expr = super#expression expr in
      match contains_attr target expr.pexp_attributes with
      | None -> expr
      | Some attr ->
        (match attr.attr_payload with
        | PStr [ { pstr_desc = Pstr_eval (expr, _); _ } ] -> expr
        | _ -> expr)

    method! core_type expr =
      let expr = super#core_type expr in
      match contains_attr target expr.ptyp_attributes with
      | None -> expr
      | Some attr ->
        (match attr.attr_payload with
        | PTyp expr -> expr
        | _ -> expr)

    method! module_type expr =
      let expr = super#module_type expr in
      match contains_attr target expr.pmty_attributes with
      | None -> expr
      | Some attr ->
        (match attr.attr_payload with
        | PSig s -> { expr with pmty_desc = Pmty_signature s }
        | _ -> expr)

    method! module_expr expr =
      let expr = super#module_expr expr in
      match contains_attr target expr.pmod_attributes with
      | None -> expr
      | Some attr ->
        (match attr.attr_payload with
        | PStr
            [ { pstr_desc = Pstr_eval ({ pexp_desc = Pexp_construct (id, None); _ }, _)
              ; _
              }
            ] -> { expr with pmod_desc = Pmod_ident id }
        | PStr s -> { expr with pmod_desc = Pmod_structure s }
        | _ -> expr)
  end

let keep target =
  let map_exprs = map_exprs target in
  Ppxlib.Driver.register_transformation
    target
    ~extensions:[ keep_str target; keep_sig target ]
    ~impl:map_exprs#structure
    ~intf:map_exprs#signature

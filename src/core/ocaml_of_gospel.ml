module W = Warnings
open Ppxlib
open Gospel
open Fmt
open Builder
module Ident = Identifier.Ident

module M = struct
  [@@@ocaml.warning "-32"]

  let return a = (a, [])
  let put a = ((), [ a ])
  let value = fst

  let ( let* ) (x, xs) f =
    let y, ys = f x in
    (y, xs @ ys)

  let ( and* ) (x, xs) (y, ys) = ((x, y), xs @ ys)

  let sequence =
    let rec aux = function
      | [] -> return []
      | x :: xs ->
          let* y = x and* ys = aux xs in
          return (y :: ys)
    in
    aux

  let map f xs = List.map f xs |> sequence
  let some a = Some a |> return
end

let rec pattern p =
  let open Tterm in
  match p.p_node with
  | Pwild -> ppat_any
  | Pvar v -> pvar (str "%a" Ident.pp v.vs_name)
  | Papp (l, pl) when Symbols.is_fs_tuple l -> ppat_tuple (List.map pattern pl)
  | Papp (l, pl) ->
      let args =
        match pl with
        | [] -> None
        | [ x ] -> Some (pattern x)
        | _ -> Some (ppat_tuple (List.map pattern pl))
      in
      let name =
        if Ident.equal Identifier.cons l.ls_name then "::"
        else Fmt.str "%a" Ident.pp l.ls_name
      in
      ppat_construct (lident name) args
  | Por (p1, p2) -> ppat_or (pattern p1) (pattern p2)
  | Pas (p, v) -> ppat_alias (pattern p) (noloc (str "%a" Ident.pp v.vs_name))
  | Pinterval (c1, c2) -> ppat_interval (Pconst_char c1) (Pconst_char c2)
  | Pconst c -> ppat_constant c

type bound = Inf of expression | Sup of expression

let rec bounds ~context ~loc (var : Symbols.vsymbol) (t1 : Tterm.term)
    (t2 : Tterm.term) =
  let unsupported () =
    raise W.(Error (Unsupported "ill formed quantification", loc))
  in
  (* [comb] extracts a bound from an the operator [f] and expression [e].
     [right] indicates if [e] is on the right side of the operator. *)
  let comb ~right (f : Symbols.lsymbol) e =
    match f.ls_name.id_str with
    | "infix >=" -> if right then Inf e else Sup e
    | "infix <=" -> if right then Sup e else Inf e
    | "infix <" -> if right then Sup (epred e) else Inf (esucc e)
    | "infix >" -> if right then Inf (esucc e) else Sup (epred e)
    | _ -> unsupported ()
  in
  let bound = function
    | Tterm.Tapp (f, [ { t_node = Tvar vs; _ }; t ])
      when vs.vs_name = var.vs_name ->
        comb ~right:true f (term ~context t)
    | Tterm.Tapp (f, [ t; { t_node = Tvar vs; _ } ])
      when vs.vs_name = var.vs_name ->
        comb ~right:false f (term ~context t)
    | _ -> unsupported ()
  in
  match (bound t1.t_node, bound t2.t_node) with
  | Inf start, Sup stop | Sup stop, Inf start -> (start, stop)
  | _ -> unsupported ()

and term ~context (t : Tterm.term) : expression =
  let term = term ~context in
  let loc = t.t_loc in
  let unsupported m = raise (W.Error (W.Unsupported m, loc)) in
  match t.t_node with
  | Tvar { vs_name; _ } -> evar (str "%a" Ident.pp vs_name)
  | Tconst c -> econst c
  | Tfield (t, f) -> pexp_field (term t) (lident f.ls_name.id_str)
  | Tapp (fs, []) when Symbols.(ls_equal fs fs_bool_true) -> [%expr true]
  | Tapp (fs, []) when Symbols.(ls_equal fs fs_bool_false) -> [%expr false]
  | Tapp (fs, tlist) when Symbols.is_fs_tuple fs ->
      List.map term tlist |> pexp_tuple
  | Tapp (ls, tlist) when Context.is_function ls context ->
      let f = Context.find_function ls context in
      eapply (evar f) (List.map term tlist)
  | Tapp (ls, tlist) when Symbols.(ls_equal ls fs_apply) ->
      let f, args =
        match tlist with
        | [] -> assert false
        | x :: xs -> (term x, List.map term xs)
      in
      eapply f args
  | Tapp (ls, tlist) -> (
      Context.translate_stdlib ls context |> function
      | Some f -> eapply (evar f) (List.map term tlist)
      | None ->
          let func = ls.ls_name.id_str in
          if ls.ls_constr then
            (if tlist = [] then None
             else Some (List.map term tlist |> pexp_tuple))
            |> pexp_construct (lident func)
          else kstr unsupported "function application `%s`" func)
  | Tif (i, t, e) -> [%expr if [%e term i] then [%e term t] else [%e term e]]
  | Tlet (x, t1, t2) ->
      let x = str "%a" Ident.pp x.vs_name in
      [%expr
        let [%p pvar x] = [%e term t1] in
        [%e term t2]]
  | Tcase (t, ptl) ->
      List.map
        (fun (p, g, t) ->
          case ~guard:(Option.map term g) ~lhs:(pattern p) ~rhs:(term t))
        ptl
      |> pexp_match (term t)
  | Tlambda (ps, t) ->
      efun (List.map (fun p -> (Nolabel, pattern p)) ps) (term t)
  | Tquant
      ( (Tterm.(Tforall | Texists) as quant),
        [ var ],
        Tterm.
          {
            t_node =
              Tbinop
                ( ((Timplies | Tand | Tand_asym) as op),
                  { t_node = Tbinop ((Tand | Tand_asym), t1, t2); _ },
                  p );
            _;
          } ) ->
      (match (quant, op) with
      | Tforall, Timplies | Texists, (Tand | Tand_asym) -> ()
      | _, _ -> unsupported "ill formed quantification");
      let start, stop = bounds ~context ~loc var t1 t2 in
      let p = term p in
      let quant =
        evar
          (if quant = Tforall then "Ortac_runtime.Z.forall"
           else "Ortac_runtime.Z.exists")
      in
      let x = str "%a" Ident.pp var.vs_name in
      let func = pexp_fun Nolabel None (pvar x) p in
      eapply quant [ start; stop; func ]
  | Tquant (_, _, _) -> unsupported "quantification"
  | Tbinop (op, t1, t2) -> (
      match op with
      | Tterm.Tand ->
          let vt1 = gen_symbol ~prefix:"__t1" () in
          let vt2 = gen_symbol ~prefix:"__t2" () in
          [%expr
            let [%p pvar vt1] = [%e term t1] in
            let [%p pvar vt2] = [%e term t2] in
            [%e evar vt1] && [%e evar vt2]]
      | Tterm.Tand_asym -> [%expr [%e term t1] && [%e term t2]]
      | Tterm.Tor ->
          let vt1 = gen_symbol ~prefix:"__t1" () in
          let vt2 = gen_symbol ~prefix:"__t2" () in
          [%expr
            let [%p pvar vt1] = [%e term t1] in
            let [%p pvar vt2] = [%e term t2] in
            [%e evar vt1] || [%e evar vt2]]
      | Tterm.Tor_asym -> [%expr [%e term t1] || [%e term t2]]
      | Tterm.Timplies -> [%expr (not [%e term t1]) || [%e term t2]]
      | Tterm.Tiff -> [%expr [%e term t1] = [%e term t2]])
  | Tnot t -> [%expr not [%e term t]]
  | Told _ -> unsupported "old operator"
  | Ttrue -> [%expr true]
  | Tfalse -> [%expr false]

let term_with_catch ~context t =
  let exp = term ~context t in
  [%expr
    try [%e exp]
    with e ->
      raise (Ortac_runtime.Partial_function (e, [%e elocation t.t_loc]))]

let core_type_of_ty_with_subst ~context subst ty =
  let open Ttypes in
  let lident_of_tysymbol ts =
    (match Context.translate_tystdlib ts context with
    | Some ty -> ty
    | None -> Fmt.str "%a" Ident.pp ts.ts_ident)
    |> Builder.lident
  in
  let rec aux ty =
    match ty.ty_node with
    | Tyvar v ->
        let v = Fmt.str "%a" Ident.pp v.tv_name in
        Option.value ~default:(Builder.ptyp_var v) (subst v)
    | Tyapp (ts, args) ->
        let args = List.map aux args in
        if is_ts_tuple ts then Builder.ptyp_tuple args
        else Builder.ptyp_constr (lident_of_tysymbol ts) args
  in
  aux ty

let core_type_of_tysymbol ~context ts =
  let lid =
    (match Context.translate_tystdlib ts context with
    | Some ty -> ty
    | None -> Fmt.str "%a" Ident.pp ts.Ttypes.ts_ident)
    |> Builder.lident
  in
  let args =
    List.map
      (fun tv -> Builder.ptyp_var (Fmt.str "%a" Ident.pp tv.Ttypes.tv_name))
      ts.ts_args
  in
  Builder.ptyp_constr lid args

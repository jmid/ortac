open Terms__Lib_rtac
open Common

let bool_ops () =
  check_success "lazy bool no exception" (fun () -> lazy_bool 42 |> ignore);
  check_raises_gospel "not lazy bool or" (fun () -> not_lazy_or 42 |> ignore);
  check_raises_gospel "not lazy bool and" (fun () -> not_lazy_and 42 |> ignore)

let scopes () =
  check_success "override variable in let binding" (fun () ->
      scope1 42 |> ignore)

let logic () =
  check_success "forall in if" (fun () -> if_forall 3 |> ignore);
  check_success "equivalence" equiv;
  check_success "exists" exists_

let suite =
  ( "Terms",
    [
      ("boolean operators", `Quick, bool_ops);
      ("scopes", `Quick, scopes);
      ("logic", `Quick, logic);
    ] )

(* This file is generated by ortac qcheck-stm,
   edit how you run the tool instead *)
[@@@ocaml.warning "-26-27-69-32-38"]
open Sut_in_type
module Ortac_runtime = Ortac_runtime_qcheck_stm
module SUT =
  (Ortac_runtime.SUT.Make)(struct type sut = int t
                                  let init () = make 16 0 end)
module ModelElt =
  struct
    type nonrec elt = {
      contents: int list }
    let init =
      let i = 16
      and a_1 = 0 in
      {
        contents =
          (try
             Ortac_runtime.Gospelstdlib.List.init
               (Ortac_runtime.Gospelstdlib.integer_of_int i) (fun j -> a_1)
           with
           | e ->
               raise
                 (Ortac_runtime.Partial_function
                    (e,
                      {
                        Ortac_runtime.start =
                          {
                            pos_fname = "sut_in_type.mli";
                            pos_lnum = 7;
                            pos_bol = 263;
                            pos_cnum = 288
                          };
                        Ortac_runtime.stop =
                          {
                            pos_fname = "sut_in_type.mli";
                            pos_lnum = 7;
                            pos_bol = 263;
                            pos_cnum = 312
                          }
                      })))
      }
  end
module Model = (Ortac_runtime.Model.Make)(ModelElt)
module Spec =
  struct
    open STM
    module QCheck =
      struct
        include QCheck
        module Gen = struct include Gen
                            let int = small_signed_int end
      end
    type _ ty +=  
      | Integer: Ortac_runtime.integer ty 
    let integer = (Integer, Ortac_runtime.string_of_integer)
    type _ ty +=  
      | SUT: SUT.elt ty 
    let sut = (SUT, (fun _ -> "<sut>"))
    type sut = SUT.t
    let init_sut = SUT.create 0
    type state = Model.t
    let init_state = Model.create 0 ()
    type cmd =
      | Make of int * int 
    let show_cmd cmd__001_ =
      match cmd__001_ with
      | Make (i, a_1) ->
          Format.asprintf "protect (fun () -> %s %a %a)" "make"
            (Util.Pp.pp_int true) i (Util.Pp.pp_int true) a_1
    let cleanup _ = ()
    let arb_cmd _ =
      let open QCheck in
        make ~print:show_cmd
          (let open Gen in
             oneof
               [((pure (fun i -> fun a_1 -> Make (i, a_1))) <*>
                   small_signed_int)
                  <*> small_signed_int])
    let next_state cmd__002_ state__003_ =
      match cmd__002_ with
      | Make (i, a_1) ->
          if
            (try
               Ortac_runtime.Gospelstdlib.(>=)
                 (Ortac_runtime.Gospelstdlib.integer_of_int i)
                 (Ortac_runtime.Gospelstdlib.integer_of_int 0)
             with
             | e ->
                 raise
                   (Ortac_runtime.Partial_function
                      (e,
                        {
                          Ortac_runtime.start =
                            {
                              pos_fname = "sut_in_type.mli";
                              pos_lnum = 6;
                              pos_bol = 245;
                              pos_cnum = 256
                            };
                          Ortac_runtime.stop =
                            {
                              pos_fname = "sut_in_type.mli";
                              pos_lnum = 6;
                              pos_bol = 245;
                              pos_cnum = 262
                            }
                        })))
          then
            let t_1__005_ =
              let open ModelElt in
                {
                  contents =
                    (try
                       Ortac_runtime.Gospelstdlib.List.init
                         (Ortac_runtime.Gospelstdlib.integer_of_int i)
                         (fun j -> a_1)
                     with
                     | e ->
                         raise
                           (Ortac_runtime.Partial_function
                              (e,
                                {
                                  Ortac_runtime.start =
                                    {
                                      pos_fname = "sut_in_type.mli";
                                      pos_lnum = 7;
                                      pos_bol = 263;
                                      pos_cnum = 288
                                    };
                                  Ortac_runtime.stop =
                                    {
                                      pos_fname = "sut_in_type.mli";
                                      pos_lnum = 7;
                                      pos_bol = 263;
                                      pos_cnum = 312
                                    }
                                })))
                } in
            Model.push (Model.drop_n state__003_ 0) t_1__005_
          else state__003_
    let precond cmd__010_ state__011_ =
      match cmd__010_ with | Make (i, a_1) -> true
    let postcond _ _ _ = true
    let run cmd__012_ sut__013_ =
      match cmd__012_ with
      | Make (i, a_1) ->
          Res
            ((result sut exn),
              (let res__014_ = protect (fun () -> make i a_1) () in
               ((match res__014_ with
                 | Ok res -> SUT.push sut__013_ res
                 | Error _ -> ());
                res__014_)))
  end
module STMTests = (Ortac_runtime.Make)(Spec)
let check_init_state () = ()
let ortac_show_cmd cmd__016_ state__017_ last__019_ res__018_ =
  let open Spec in
    let open STM in
      match (cmd__016_, res__018_) with
      | (Make (i, a_1), Res ((Result (SUT, Exn), _), t_1)) ->
          let lhs =
            if last__019_
            then "r"
            else
              (match t_1 with
               | Ok _ -> "Ok " ^ (SUT.get_name state__017_ 0)
               | Error _ -> "_")
          and shift = match t_1 with | Ok _ -> 1 | Error _ -> 0 in
          Format.asprintf "let %s = protect (fun () -> %s %a %a)" lhs "make"
            (Util.Pp.pp_int true) i (Util.Pp.pp_int true) a_1
      | _ -> assert false
let ortac_postcond cmd__006_ state__007_ res__008_ =
  let open Spec in
    let open STM in
      let new_state__009_ = lazy (next_state cmd__006_ state__007_) in
      match (cmd__006_, res__008_) with
      | (Make (i, a_1), Res ((Result (SUT, Exn), _), t_1)) ->
          (match if
                   try
                     Ortac_runtime.Gospelstdlib.(>=)
                       (Ortac_runtime.Gospelstdlib.integer_of_int i)
                       (Ortac_runtime.Gospelstdlib.integer_of_int 0)
                   with
                   | e ->
                       raise
                         (Ortac_runtime.Partial_function
                            (e,
                              {
                                Ortac_runtime.start =
                                  {
                                    pos_fname = "sut_in_type.mli";
                                    pos_lnum = 6;
                                    pos_bol = 245;
                                    pos_cnum = 256
                                  };
                                Ortac_runtime.stop =
                                  {
                                    pos_fname = "sut_in_type.mli";
                                    pos_lnum = 6;
                                    pos_bol = 245;
                                    pos_cnum = 262
                                  }
                              }))
                 then None
                 else
                   Some
                     (Ortac_runtime.report "Sut_in_type" "make 16 0"
                        (Either.left "Invalid_argument") "make"
                        [("i >= 0",
                           {
                             Ortac_runtime.start =
                               {
                                 pos_fname = "sut_in_type.mli";
                                 pos_lnum = 6;
                                 pos_bol = 245;
                                 pos_cnum = 256
                               };
                             Ortac_runtime.stop =
                               {
                                 pos_fname = "sut_in_type.mli";
                                 pos_lnum = 6;
                                 pos_bol = 245;
                                 pos_cnum = 262
                               }
                           })])
           with
           | None -> (match t_1 with | Ok t_1 -> None | _ -> None)
           | _ ->
               (match t_1 with
                | Error (Invalid_argument _) -> None
                | _ ->
                    if
                      (try
                         Ortac_runtime.Gospelstdlib.(>=)
                           (Ortac_runtime.Gospelstdlib.integer_of_int i)
                           (Ortac_runtime.Gospelstdlib.integer_of_int 0)
                       with
                       | e ->
                           raise
                             (Ortac_runtime.Partial_function
                                (e,
                                  {
                                    Ortac_runtime.start =
                                      {
                                        pos_fname = "sut_in_type.mli";
                                        pos_lnum = 6;
                                        pos_bol = 245;
                                        pos_cnum = 256
                                      };
                                    Ortac_runtime.stop =
                                      {
                                        pos_fname = "sut_in_type.mli";
                                        pos_lnum = 6;
                                        pos_bol = 245;
                                        pos_cnum = 262
                                      }
                                  })))
                    then None
                    else
                      Some
                        (Ortac_runtime.report "Sut_in_type" "make 16 0"
                           (Either.left "Invalid_argument") "make"
                           [("i >= 0",
                              {
                                Ortac_runtime.start =
                                  {
                                    pos_fname = "sut_in_type.mli";
                                    pos_lnum = 6;
                                    pos_bol = 245;
                                    pos_cnum = 256
                                  };
                                Ortac_runtime.stop =
                                  {
                                    pos_fname = "sut_in_type.mli";
                                    pos_lnum = 6;
                                    pos_bol = 245;
                                    pos_cnum = 262
                                  }
                              })])))
      | _ -> None
let _ =
  QCheck_base_runner.run_tests_main
    (let count = 1000 in
     [STMTests.agree_test ~count ~name:"Sut_in_type STM tests" 0
        check_init_state ortac_show_cmd ortac_postcond])

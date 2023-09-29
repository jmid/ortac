type !'a t
(*@ mutable model contents : 'a list *)

val create : unit -> 'a t
(*@ q = create ()
    ensures q.contents = [] *)

val add : 'a -> 'a t -> unit
(*@ add a q
    modifies q
    ensures q.contents = a :: old q.contents *)

val take : 'a t -> 'a
(*@ a = take q
    modifies q
    raises Failure _ -> q.contents = []
    ensures match q.contents with
      | [] -> true
      | q_hd::q_tail -> a = q_hd /\ q.contents = q_tail  *)

(* z3-og -- hand-rolled SMT stack. Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
   Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
   LICENSE v1.0 -- see LICENSE at the repository root. Commercial
   exploitation requires separate written authorisation; publication,
   access, download, visibility, or possession is not authorisation. *)
(* Congruence closure over ground terms.
 *
 * Method (standard, cf. Nieuwenhuis & Oliveras, "Fast Congruence
 * Closure" style saturation, simplified for a trusted kernel):
 *
 *   1. Register every subterm of every assumption and of the query
 *      in a union-find keyed by term identifier.
 *   2. Union the two sides of every assumed equality.
 *   3. Saturate: group all compound terms by a signature made of
 *      their head constructor and the current class representatives
 *      of their children; union any two terms that share a
 *      signature.  Repeat until a full pass makes no union.
 *
 * The set of registered terms is finite and each union strictly
 * decreases the number of classes, so saturation terminates.  At
 * the fixpoint, class membership decides ground EUF entailment. *)

type uf =
  { parent : (int, int) Hashtbl.t
  ; rank : (int, int) Hashtbl.t
  }

let uf_create () = { parent = Hashtbl.create 64; rank = Hashtbl.create 64 }

let uf_add uf i =
  if not (Hashtbl.mem uf.parent i) then begin
    Hashtbl.add uf.parent i i;
    Hashtbl.add uf.rank i 0
  end

let rec uf_find uf i =
  let p = Hashtbl.find uf.parent i in
  if p = i then i
  else begin
    let r = uf_find uf p in
    Hashtbl.replace uf.parent i r;
    r
  end

(* Returns [true] iff a merge actually happened. *)
let uf_union uf a b =
  let ra = uf_find uf a and rb = uf_find uf b in
  if ra = rb then false
  else begin
    let ka = Hashtbl.find uf.rank ra and kb = Hashtbl.find uf.rank rb in
    if ka < kb then Hashtbl.replace uf.parent ra rb
    else begin
      Hashtbl.replace uf.parent rb ra;
      if ka = kb then Hashtbl.replace uf.rank ra (ka + 1)
    end;
    true
  end

(* Split the assumption list into equalities and disequalities.
   Raises [Invalid_argument] on any other shape. *)
let split_assumptions assumptions =
  List.fold_left
    (fun (eqs, diseqs) t ->
      match Term.node t with
      | Term.Eq (a, b) -> ((a, b) :: eqs, diseqs)
      | Term.Not inner ->
          (match Term.node inner with
           | Term.Eq (a, b) -> (eqs, (a, b) :: diseqs)
           | _ ->
               invalid_arg
                 "Checker: assumption is a negation but not of an equality")
      | _ ->
          invalid_arg
            "Checker: assumption is neither an equality nor a disequality")
    ([], []) assumptions

(* A closed problem: the union-find at its congruence fixpoint, the
   registered terms, the recorded disequalities, and whether the
   assumption set already collapses (is inconsistent). *)
type closure =
  { uf : uf
  ; terms : Term.term list
  ; diseqs : (Term.term * Term.term) list
  ; inconsistent : bool
  }

let binary_sig uf tag a b =
  Printf.sprintf "%s:%d:%d" tag (uf_find uf (Term.id a)) (uf_find uf (Term.id b))

let signature uf t =
  match Term.node t with
  | Term.Var _ | Term.Const _ | Term.ConstInt _ -> None
  | Term.App (fname, _, args) ->
      Some
        (Printf.sprintf "app:%s:%s" fname
           (String.concat "," (List.map (fun a -> string_of_int (uf_find uf (Term.id a))) args)))
  | Term.Eq (a, b) -> Some (binary_sig uf "eq" a b)
  | Term.And (a, b) -> Some (binary_sig uf "and" a b)
  | Term.Add (a, b) -> Some (binary_sig uf "add" a b)
  | Term.Mul (a, b) -> Some (binary_sig uf "mul" a b)
  | Term.Lt (a, b) -> Some (binary_sig uf "lt" a b)
  | Term.Not a -> Some (Printf.sprintf "not:%d" (uf_find uf (Term.id a)))

let build_closure assumptions extra_terms =
  let eqs, diseqs = split_assumptions assumptions in
  let registry : (int, Term.term) Hashtbl.t = Hashtbl.create 64 in
  let register t =
    List.iter
      (fun s -> Hashtbl.replace registry (Term.id s) s)
      (Term.subterms t)
  in
  List.iter register assumptions;
  List.iter register extra_terms;
  let terms = Hashtbl.fold (fun _ t acc -> t :: acc) registry [] in
  let uf = uf_create () in
  List.iter (fun t -> uf_add uf (Term.id t)) terms;
  List.iter (fun (a, b) -> ignore (uf_union uf (Term.id a) (Term.id b))) eqs;
  (* Congruence saturation to fixpoint. *)
  let changed = ref true in
  while !changed do
    changed := false;
    let sigtab : (string, int) Hashtbl.t = Hashtbl.create 64 in
    List.iter
      (fun t ->
        match signature uf t with
        | None -> ()
        | Some sgn ->
            (match Hashtbl.find_opt sigtab sgn with
             | None -> Hashtbl.add sigtab sgn (Term.id t)
             | Some other ->
                 if uf_union uf (Term.id t) other then changed := true))
      terms
  done;
  (* Inconsistency: a recorded disequality collapsed into one class,
     or two distinct integer literals ended up in one class. *)
  let diseq_collapsed =
    List.exists
      (fun (a, b) -> uf_find uf (Term.id a) = uf_find uf (Term.id b))
      diseqs
  in
  let literal_collapsed =
    let by_class : (int, int) Hashtbl.t = Hashtbl.create 16 in
    List.exists
      (fun t ->
        match Term.node t with
        | Term.ConstInt n ->
            let r = uf_find uf (Term.id t) in
            (match Hashtbl.find_opt by_class r with
             | None -> Hashtbl.add by_class r n; false
             | Some m -> m <> n)
        | _ -> false)
      terms
  in
  { uf; terms; diseqs; inconsistent = diseq_collapsed || literal_collapsed }

let same_class c a b = uf_find c.uf (Term.id a) = uf_find c.uf (Term.id b)

let entails_eq assumptions lhs rhs =
  let c = build_closure assumptions [ lhs; rhs ] in
  c.inconsistent || same_class c lhs rhs

let consistent assumptions =
  let c = build_closure assumptions [] in
  not c.inconsistent

(* Does class of [t] contain an integer literal?  If so, which. *)
let literal_in_class c t =
  let r = uf_find c.uf (Term.id t) in
  List.fold_left
    (fun acc u ->
      match acc with
      | Some _ -> acc
      | None ->
          (match Term.node u with
           | Term.ConstInt n when uf_find c.uf (Term.id u) = r -> Some n
           | _ -> None))
    None c.terms

let entails_diseq assumptions lhs rhs =
  let c = build_closure assumptions [ lhs; rhs ] in
  if c.inconsistent then true
  else if same_class c lhs rhs then false
  else begin
    (* Transport of a recorded disequality across classes. *)
    let transported =
      List.exists
        (fun (d1, d2) ->
          (same_class c lhs d1 && same_class c rhs d2)
          || (same_class c lhs d2 && same_class c rhs d1))
        c.diseqs
    in
    if transported then true
    else begin
      (* Distinct integer literals denote distinct values. *)
      match (literal_in_class c lhs, literal_in_class c rhs) with
      | Some n, Some m -> n <> m
      | _ -> false
    end
  end

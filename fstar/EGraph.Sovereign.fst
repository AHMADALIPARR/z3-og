(* z3-og -- hand-rolled SMT stack. Copyright (c) 2026 Ahmad Ali Parr. Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE LICENSE v1.0 -- see LICENSE at the repository root. Commercial exploitation requires separate written authorisation; publication, access, download, visibility, or possession is not authorisation. *)

module EGraph.Sovereign

(* A small, actually-verified E-graph core.

   This module rebuilds the owner-supplied sketch of the same name.
   The sketch kept these type shapes but shipped two placeholders:
   a soundness lemma whose statement was the trivial proposition,
   and a union operation that returned its input unchanged.  Neither
   is carried over.  What is here instead:

     - the same operator / e-node / e-class / state types;
     - an explicit representative lookup, [repr_of], defined by a
       first-match scan of the class list;
     - [verified_union], which really merges: when both classes are
       present, both are rewritten to carry the first class's
       representative (canonical-representative merge);
     - machine-checked lemmas stating that the merge happened
       ([union_merges]) and that merging never touches the node
       store ([union_nodes]).

   Representation note: classes live in a plain list and lookup is a
   linear first-match scan, mirroring the flat, index-based spirit of
   the sketch while keeping every operation a structural recursion
   on the list.  That is what makes the merge lemmas provable by
   induction with no axioms and no proof placeholders: the two
   helper lemmas below ([find_class_set_repr_same] and
   [find_class_set_repr_other]) are proved by induction on the class
   list, and [union_merges] is assembled from them.

   Deliberately not included: the sketch's rewrite-soundness lemma.
   Stated over a real denotational semantics for [op] it would be a
   genuine theorem; stated the way the sketch stated it, it proved
   nothing.  It is future work, recorded here rather than faked.
   The [rewrite_rule] type is kept for that purpose. *)

open FStar.List.Tot

type enode_id = nat
type eclass_id = nat

(* First-principles operator set *)
type op =
  | Const : bool -> op
  | Var : nat -> op
  | Node : string -> list eclass_id -> op

(* An E-Node points to an operator and a bounded list of argument equivalence classes *)
type enode = {
  id: enode_id;
  op: op;
  eclass: eclass_id;
}

(* E-Class containing a canonical representative and its parent references *)
type eclass = {
  class_id: eclass_id;
  repr: enode_id;
  parents: list enode_id;
}

(* A rewrite rule is a relation between two terms *)
type rewrite_rule = {
  lhs: op;
  rhs: op;
}

(* E-Graph state: node store, class store, fresh-id counter *)
noeq type egraph_state = {
  nodes: list enode;
  classes: list eclass;
  next_id: nat;
}

(* First-match lookup of a class by id *)
let rec find_class (classes: list eclass) (c: eclass_id) : option eclass =
  match classes with
  | [] -> None
  | cl :: rest ->
      if cl.class_id = c then Some cl else find_class rest c

(* The representative of a class in a state, if the class is present *)
val repr_of (g: egraph_state) (c: eclass_id) : option enode_id
let repr_of g c =
  match find_class g.classes c with
  | Some cl -> Some cl.repr
  | None -> None

(* Rewrite the representative of class [c] to [r]; other classes untouched *)
let rec set_repr (classes: list eclass) (c: eclass_id) (r: enode_id) : list eclass =
  match classes with
  | [] -> []
  | cl :: rest ->
      if cl.class_id = c
      then { cl with repr = r } :: rest
      else cl :: set_repr rest c r

(* Lookup after rewriting the same class: the class is found with the
   new representative, and presence is unchanged *)
let rec find_class_set_repr_same (cs: list eclass) (c: eclass_id) (r: enode_id)
  : Lemma (find_class (set_repr cs c r) c ==
           (match find_class cs c with
            | Some cl -> Some ({ cl with repr = r })
            | None -> None))
  = match cs with
    | [] -> ()
    | cl :: rest ->
        if cl.class_id = c then () else find_class_set_repr_same rest c r

(* Lookup after rewriting a different class: the result is unchanged *)
let rec find_class_set_repr_other (cs: list eclass) (c: eclass_id) (c': eclass_id) (r: enode_id)
  : Lemma (requires c' <> c)
          (ensures find_class (set_repr cs c r) c' == find_class cs c')
  = match cs with
    | [] -> ()
    | cl :: rest ->
        if cl.class_id = c then ()
        else if cl.class_id = c' then ()
        else find_class_set_repr_other rest c c' r

(* Merge two classes.  When both are present, both are rewritten to
   the first class's representative.  When either is absent there is
   nothing sound to merge, and the state is returned unchanged. *)
val verified_union (g: egraph_state) (c1 c2: eclass_id) : Tot egraph_state
let verified_union g c1 c2 =
  match repr_of g c1, repr_of g c2 with
  | Some r1, Some _ ->
      { g with classes = set_repr (set_repr g.classes c1 r1) c2 r1 }
  | _ -> g

(* The merge really happens: after [verified_union g c1 c2], whenever
   both classes were present beforehand, the representatives of [c1]
   and [c2] in the resulting state are both the representative [c1]
   had before -- in particular they are equal. *)
val union_merges (g: egraph_state) (c1 c2: eclass_id) (r1 r2: enode_id)
  : Lemma (requires repr_of g c1 == Some r1 /\ repr_of g c2 == Some r2)
          (ensures repr_of (verified_union g c1 c2) c1 == Some r1 /\
                   repr_of (verified_union g c1 c2) c2 == Some r1)
let union_merges g c1 c2 r1 r2 =
  assert (verified_union g c1 c2 ==
          { g with classes = set_repr (set_repr g.classes c1 r1) c2 r1 });
  if c1 = c2 then begin
    find_class_set_repr_same (set_repr g.classes c1 r1) c1 r1;
    find_class_set_repr_same g.classes c1 r1
  end else begin
    find_class_set_repr_same (set_repr g.classes c1 r1) c2 r1;
    find_class_set_repr_same g.classes c1 r1;
    find_class_set_repr_other (set_repr g.classes c1 r1) c2 c1 r1;
    find_class_set_repr_other g.classes c1 c2 r1
  end

(* Merging never touches the node store *)
val union_nodes (g: egraph_state) (c1 c2: eclass_id)
  : Lemma (ensures (verified_union g c1 c2).nodes == g.nodes)
let union_nodes g c1 c2 =
  match repr_of g c1, repr_of g c2 with
  | Some _, Some _ -> ()
  | _ -> ()

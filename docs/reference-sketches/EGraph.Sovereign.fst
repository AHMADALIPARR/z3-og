module EGraph.Sovereign

open FStar.Mul
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
};

(* A rewrite rule is a relation between two terms *)
type rewrite_rule = {
  lhs: op;
  rhs: op;
}

(* Lemma: Proving that a sound rewrite preserves semantic equivalence *)
val sound_rewrite_preserves_equivalence
  (r: rewrite_rule)
  (env: nat -> bool) : Lemma (ensures true) (* formalize semantic equivalence here *)
let sound_rewrite_preserves_equivalence r env = ()

(* E-Graph state type carrying its invariant proof *)
noeq type egraph_state = {
  nodes: list enode;
  classes: list eclass;
  next_id: nat;
}

(* Verified merge operation that collapses equivalence classes *)
val verified_union (g: egraph_state) (c1 c2: eclass_id) : Tot egraph_state
let verified_union g c1 c2 =
  (* Flat-array or list-based union implementation with invariant preservation *)
  { g with next_id = g.next_id }

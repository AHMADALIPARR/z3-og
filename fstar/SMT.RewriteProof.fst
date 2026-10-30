module SMT.RewriteProof

(* Explicit boolean XOR operator *)
let bxor (a b: bool) : bool =
  (a && not b) || (not a && b)

(* Symbolic expression AST *)
type bexp =
  | BConst : bool -> bexp
  | BVar : nat -> bexp
  | BNot : bexp -> bexp
  | BXor : bexp -> bexp -> bexp

(* Semantics evaluation function under a variable environment *)
let rec eval (env: nat -> bool) (e: bexp) : bool =
  match e with
  | BConst b -> b
  | BVar v -> env v
  | BNot e1 -> not (eval env e1)
  | BXor e1 e2 -> bxor (eval env e1) (eval env e2)

(*
  Soundness Lemma: Proves that rewriting `e ^ false` to `e`
  preserves semantic equivalence across all variable environments.
*)
val xor_false_sound (env: nat -> bool) (e: bexp) : Lemma
  (ensures eval env (BXor e (BConst false)) == eval env e)

let rec xor_false_sound env e =
  match e with
  | BConst b ->
      // Base case verified automatically by SMT backend
      assert (bxor b false == b)
  | BVar v ->
      assert (bxor (env v) false == env v)
  | BNot e1 ->
      // Inductive step on nested unary expressions
      xor_false_sound env e1
  | BXor e1 e2 ->
      // Inductive step on binary sub-terms
      xor_false_sound env e1;
      xor_false_sound env e2

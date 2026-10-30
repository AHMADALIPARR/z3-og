(* z3-og -- hand-rolled SMT stack. Copyright (c) 2026 Ahmad Ali Parr.
   Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
   LICENSE v1.0 -- see LICENSE at the repository root. Commercial
   exploitation requires separate written authorisation; publication,
   access, download, visibility, or possession is not authorisation. *)
(** The congruence-closure checker: a decision procedure for ground
    entailment in EUF (equality with uninterpreted functions).

    Assumptions are given as ground terms, each of which must be
    either an equality [Eq (a, b)] or a disequality
    [Not (Eq (a, b))]; any other shape raises [Invalid_argument].

    The checker registers every subterm of every assumption and of
    the query, unions the sides of each assumed equality in a
    union-find, and then saturates under congruence: whenever two
    compound terms have the same head constructor and pairwise
    congruent children, they are merged.  Saturation runs to a
    fixpoint, which for ground terms is a complete decision
    procedure: two ground terms are in the same class at the
    fixpoint iff the equalities entail their equality. *)

(** [entails_eq assumptions lhs rhs] decides whether the ground
    equalities among [assumptions] entail [lhs = rhs] by congruence
    closure.  If the assumption set is inconsistent (some assumed
    disequality has both sides in one congruence class), every
    entailment holds and this returns [true]. *)
val entails_eq : Term.term list -> Term.term -> Term.term -> bool

(** [entails_diseq assumptions lhs rhs] decides whether
    [assumptions] entail [lhs <> rhs].  This is the standard ground
    congruence-closure disequality reasoning, and it is deliberately
    conservative: two terms merely sitting in different classes is
    {e not} enough (in pure EUF, unproven equality is not
    disequality).  A disequality is returned as entailed only when it
    is recorded soundly, namely when at least one of these holds:

    - an assumed disequality [c <> d] is recorded with [lhs]
      congruent to one side and [rhs] congruent to the other
      (disequalities are transported across congruence classes);
    - [lhs] and [rhs] are congruent to two distinct integer
      literals (distinct numerals denote distinct integers);
    - the assumption set is inconsistent (ex falso quodlibet),
      including an assumed equality between distinct integer
      literals. *)
val entails_diseq : Term.term list -> Term.term -> Term.term -> bool

(** [consistent assumptions] is [true] iff the assumption set does
    not force any recorded disequality's sides into one class and
    does not equate two distinct integer literals. *)
val consistent : Term.term list -> bool

# Reference sketches — owner-supplied, verbatim

These Rust fragments were supplied by the owner on 2026-10-29 as the
memory-management foundation for the v2 CDCL(T) engine (see
`docs/ARCHITECTURE-CDCLT.md`). They are filed **verbatim, as given** —
design sketches that fix the flat-arena memory model, not build
inputs. (The Sovereign license header was prepended to each file on
2026-10-30 at the owner's order; bodies are exactly as given.) The v2 kernel is C99 (Option A); these sketches are the
reference the C99 structures are checked against.

- `sat_arena.rs` — flat SAT arena: clause literal store, clause
  metadata, watch lists, assignments, trail, antecedents;
  two-watched-literal propagation.
- `sat_arena_analyze.rs` — the arena extension (levels, seen flags,
  decision level) and the First-UIP conflict analysis + learned-clause
  insertion.
- `egraph.rs` — E-graph structures (ENode/EClass/EGraph, hash-consing
  chain) with `find` (path compression) and `union`. Filed exactly as
  supplied, including the `pub}$` typo in `EClass` — sketches are not
  edited after the fact; corrections belong to the C99 implementation
  and its contract.
- `flat_array_grid.rs` — packed-u64 flat-array grid (Wolfram rule
  evaluation) supplied in the same stream; a memory-pattern sketch
  (word-parallel state, double buffer, zero allocation), not part of
  the solver core.

Known sketch-level issues, noted for the C99 port (not fixed here —
the sketches stay verbatim):

- `propagate` uses `trail_cursor` as both the propagation head and
  the append point in `assign`; the C99 design separates trail length
  from the propagation head (qhead), and bounds the loop by trail
  length, not by the backing array's capacity.
- `analyze_conflict` caps the learned clause at 256 literals and
  silently drops overflow; the contract requires capacity exhaustion
  to surface as `unknown`/resource error, never a truncated clause.
- The watch table is a fixed `[ClauseId; 256]` per literal;
  overflow behaviour is unspecified in the sketch. The contract
  requires explicit capacity checks.
- `EGraph::union` does not yet rebuild parent hash keys (the sketch
  says so itself); congruence maintenance is contract §2 work.

- `symbolic_arena.rs` — symbolic expression arena (Const/Var/Not/And/
  Or/Xor over u32 expression IDs) for compiling flat-array transition
  predicates into Boolean constraints.
- `symbolic_compile.rs` — Tseitin compilation from the symbolic arena
  into SatArena clauses (memoized, one variable per unique node).
- `wolfram_stencil.rs` — XOR stencil builder for elementary rules.
- `EGraph.Sovereign.fst` — F* specification of the verified E-graph
  layer (operator set, e-nodes/e-classes, rewrite rules, merge
  operation), the formal counterpart of `egraph.rs`.

Corrections offered for the symbolic compiler sketches (noted here,
not edited into the verbatim files):

- In `symbolic_compile.rs` the arm labelled `And` emits the clause set
  for **Or**: `(l1 -> out)`, `(l2 -> out)`, `(out -> l1 | l2)` is
  exactly `out <-> (l1 | l2)`. Counterexample for AND: l1=true,
  l2=false, out=true satisfies all three emitted clauses but violates
  AND. The AND set is `(out -> l1)`, `(out -> l2)`,
  `(l1 & l2 -> out)`. The `Or` arm is still `todo!()`. The XOR clause
  set checks out as written.
- `wolfram_stencil.rs` as written builds `curr ^ (left ^ right)`,
  which is exactly **Rule 90** — one rule, not a general rule
  compiler. A general elementary-rule compiler needs the full
  8-neighbourhood minterm expansion (or the rule's algebraic normal
  form). The working general compiler for the current baseline is
  `tools/rulec.c`, verified exhaustively at small width.
- `compile_to_cnf` calls `sat.alloc_var()`, which the SatArena sketch
  does not define yet; the C99 port must add variable allocation to
  the arena contract.
- In `EGraph.Sovereign.fst`, `sound_rewrite_preserves_equivalence`
  as supplied proves `ensures true` (vacuous until semantic
  equivalence is formalised, as its own comment says), and
  `verified_union` returns the state unmerged. Both are specification
  placeholders, recorded as such.

- `flat_array_grid.mojo`, `egraph.mojo` — Mojo ports of the flat grid
  and the E-graph, supplied in the same stream. Filed verbatim; **not
  executed** — no Mojo toolchain is installed in this workspace.
  Note: `egraph.mojo`'s `find` uses path compression; the CDCL(T)
  contract (ARCHITECTURE-CDCLT.md section 5) requires rollback-safe
  union-find in the solver's EUF, so compression there must be
  recorded on the rollback trail or dropped.

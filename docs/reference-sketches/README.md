# Reference sketches — owner-supplied, verbatim

These Rust fragments were supplied by the owner on 2026-10-29 as the
memory-management foundation for the v2 CDCL(T) engine (see
`docs/ARCHITECTURE-CDCLT.md`). They are filed **verbatim, as given** —
design sketches that fix the flat-arena memory model, not build
inputs. The v2 kernel is C99 (Option A); these sketches are the
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

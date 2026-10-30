# ARCHITECTURE — z3-og v2: deterministic CDCL(T), bare-metal memory model

Status: **implementation contract, locked 2026-10-29 before any code
changes.** The d285017 baseline (DPLL + batch theory check) stays the
reference implementation until the gate in §8 is met. Owner-supplied
Rust memory-management sketches that fix the memory model are filed
verbatim in `docs/reference-sketches/`.

## 0. Direction (Option A)

Bare-metal CDCL(T) with zero runtime allocation during search.
Deterministic execution, cache locality, hardware-level control.

- The SAT control path runs on the **CPU**. SASS is NVIDIA GPU machine
  code; GPU/CUDA/PTX is an optional separate backend for measurable
  parallel workloads, never a dependency of correctness.
- Core language: **strict C99**, freestanding-compatible, no required
  libc calls, explicit platform interface (`platform.h`). (A `#pragma`
  does not make C freestanding; `#[no_std]` is Rust, not C.)
- The existing C11 implementation remains the reference baseline;
  performance changes are checked against its known behaviour.

Target layout:

```
z3-og/
├── core/    arena.c (fixed-capacity allocator), vectors.c, platform.h
├── sat/     clauses.c, watches.c, propagate.c, analyze.c, backtrack.c, cdcl.c
├── theory/  euf.c (rollback congruence closure), lia.c (exact integers), interface.c
├── bv/      bitblast.c, simd_x86.c (AVX2/AVX-512), simd_arm.c (NEON)
├── proof/   emit.c (proof certificates)
└── arch/    x86_64/, aarch64/
```

## 1. Memory model

- Caller-supplied memory; one preallocated arena (illustrative 64 MiB
  partition across clauses / trail / watches / theory / proof —
  example capacities, not measured usage).
- **Offsets replace pointers** in persistent solver structures; every
  clause, variable, and watch list is indexed by raw u32 integers in
  contiguous flat arrays.
- Bump allocation for immutable records; reusable scratch buffers;
  explicit capacity checks everywhere. Learned-clause deletion
  recycles arena space without general-purpose malloc/free.
- **No allocation during propagation or backjumping.**
- Resource exhaustion returns `unknown`, never `unsat`.

## 2. SAT engine — CDCL orchestrator (C, flat arrays, integer IDs)

| Component | Implementation |
|---|---|
| Variable assignment | `int8_t value[nvars]` |
| Decision levels | `uint32_t level[nvars]` |
| Implication reasons | `int32_t reason[nvars]` |
| Trail | contiguous literal vector |
| Propagation | two-watched literals |
| Conflict analysis | First-UIP resolution |
| Backtracking | nonchronological backjumping |
| Branching | deterministic VSIDS, fixed tie-breaking |
| Restarts | deterministic Luby sequence |
| Clause storage | flat arena, offset-based references |

Two-watched literals avoid full-clause rescans on most assignments;
they do not guarantee constant-time propagation in every case.
VSIDS (Variable State Independent Decaying Sum) is an activity-based
branching heuristic, not a guarantee of optimal decisions.

## 3. Packed AST and arena

A 64-bit packed expression node: OpCode 8 bits, LeftChildIdx 28 bits,
RightChildIdx 28 bits.

```c
#include <stdint.h>
typedef uint64_t Expr;
#define EXPR_MAKE(op, l, r) \
    (((uint64_t)(op) << 56) | \
     ((uint64_t)(l) << 28) | \
     (uint64_t)(r))
#define EXPR_OP(e) ((uint8_t)((e) >> 56))
#define EXPR_LEFT(e) (((e) >> 28) & 0x0FFFFFFFu)
#define EXPR_RIGHT(e) ((e) & 0x0FFFFFFFu)
```

Field widths are validated before packing. Side tables hold sorts,
symbols, constants, and variable-arity applications. A packed AST is
not automatically an E-graph: equivalence classes and congruence
maintenance require the additional structures of §5.

## 4. Tseitin CNF pipeline

Postorder traversal with memoized node-to-literal mappings. Each
Boolean subexpression gets a representative SAT variable; definitional
clauses are emitted once per unique node; the root literal is
asserted. Bit-vectors are first lowered into Boolean gates (or a
width-aware bit-blasting pipeline); Tseitin then keeps CNF size
linear in the generated gate graph, not necessarily in the original
high-level bit-vector expression.

## 5. Theory engine — EUF (rollback congruence closure)

- Union-Find with union-by-size; **reversible** parent changes through
  a rollback trail. Unrestricted path compression is avoided unless
  its mutations are also recorded for rollback.
- Signature tables indexed by function symbol and argument equivalence
  classes; parent-use lists for detecting newly congruent
  applications.
- Explicit equality and disequality constraints.
- Explanation forests for reconstructing equality proofs.
- Theory conflict clauses returned to CDCL.
- The E-graph sketch (`docs/reference-sketches/egraph.rs`) fixes the
  node/class layout: hash-consed E-nodes, per-class parent lists,
  union-find parent pointer.

## 6. Integer arithmetic — QF_LIA (exact)

Normalized integer coefficients, strict-inequality normalization,
overflow-safe arithmetic (checked overflow or exact multiprecision).
The existing Fourier–Motzkin implementation remains as a
correctness-oriented baseline; the production path needs integer-aware
reasoning (branch-and-bound or cutting planes). Rational feasibility
is **not** integer satisfiability — the regression case
`2x + 3y = 12, x < y, x > 0` (LIA-unsat) is preserved.

## 7. CDCL(T) interaction

Theory conflicts become SAT-level learned clauses; one coordinated
search. The theory interface exposes operations equivalent to:

```
theory_push(level);
theory_assert(literal);
theory_propagate(&implied);
theory_explain(literal, &reason);
theory_check(&conflict);
theory_pop(level);
```

Every theory propagation or conflict carries a valid explanation in
terms of asserted Boolean abstraction literals.

Solving loop (architectural skeleton, as specified):

```c
SolveResult solve(Solver *s)
{
    for (;;) {
        Conflict c = propagate_boolean(s);
        if (!c.valid)
            c = propagate_theories(s);
        if (c.valid) {
            if (decision_level(s) == 0)
                return SOLVE_UNSAT;
            LearnedClause learned =
                analyze_first_uip(s, c);
            backjump(s, learned.backjump_level);
            ClauseId id = add_learned_clause(s, learned);
            enqueue_asserting_literal(s, id);
            continue;
        }
        if (all_variables_assigned(s)) {
            TheoryResult t = theory_final_check(s);
            if (t == THEORY_SAT)
                return SOLVE_SAT;
            if (t == THEORY_UNKNOWN)
                return SOLVE_UNKNOWN;
            integrate_theory_conflict(s, t);
            continue;
        }
        Literal next = select_vsids_variable(s);
        new_decision_level(s);
        enqueue_decision(s, next);
    }
}
```

The skeleton is not drop-in code: the implementation must also handle
resource exhaustion, theory propagation explanations, and incremental
state restoration.

Implementation boundary — the SAT engine stays independent of the
theory engines:

```
SAT core
  +-- Boolean propagation
  +-- Conflict analysis
  +-- Clause learning
  +-- Theory interface
        +-- EUF
        +-- QF_LIA
        +-- Future QF_BV
```

## 8. Verification contract

The OCaml kernel checks evidence; it does not trust the solver.

- Deterministic proof format emitted by the C solver (`proof/emit.c`).
- The kernel verifies **Boolean resolution steps, theory lemmas, and
  the final contradiction** for `unsat`.
- A model evaluator independently validates `sat` assignments.
- Current baseline state (honest, 2026-10-29): the C solver emits no
  proof evidence and the kernel checks only directly supplied
  assertions — see `STATUS.md`. This contract is the work that closes
  that gap.

### Critical invariants

| Subsystem | Required invariant |
|---|---|
| AST | every child reference is valid and sort-correct |
| CNF | Boolean encoding preserves satisfiability |
| Watches | every live clause maintains valid watch state |
| CDCL | learned clauses follow from existing constraints |
| First-UIP | learned clause is asserting after backjump |
| EUF | merges are reversible and explainable |
| LIA | arithmetic is exact and integer-sound |
| Theory interface | every conflict has a valid Boolean explanation |
| Result | `sat` has a valid model; `unsat` has a valid derivation |

**Architectural invariant:** no theory solver may inject an
unexplained clause, no unsupported fragment may produce a definitive
result, and no `unsat` result may be described as independently
certified without a successfully checked proof.

## 9. Build order and replacement gate

1. Replace the DPLL search loop with CDCL: First-UIP, watched
   literals, clause learning — verified independently first.
2. Integrate rollback EUF with explanation generation.
3. Connect QF_LIA through the same theory interface.
4. Add proof-producing conflict explanations.
5. Wire the OCaml kernel to the solver's proof output.
6. Differential-test against Z3, then fuzz and minimize disagreements.

**Gate for replacing the baseline:** the d285017 test battery stays
green — 13 solver regressions, the 81-file differential corpus, 14
cryptographic vectors, 35 OCaml kernel tests — and, before the DPLL
implementation is replaced, adversarial SAT instances, randomized CNF
differential tests, and proof replay are added.

## 10. Hardware acceleration — scope note

SIMD (AVX2/AVX-512, NEON) accelerates bit-vector preprocessing, scans,
and bulk operations **where benchmarks justify it**. Parallel unit
propagation across hardware pipelines is a throughput research
direction for the optional backend. Per-decision latency on a CPU is
bounded below by memory latency (a single L1 hit is ~4 cycles), so
sub-nanosecond *per-decision* latency is not a CPU-reachable figure
and is not a contract target; deterministic behaviour and checked
results are.

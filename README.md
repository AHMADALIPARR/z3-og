# z3-og

**A clean-stack remake of the original-style Z3** — the 2015-era
architecture (`util / ast / parsers / sat / smt / solver / shell`),
rebuilt from scratch: a custom SMT core, hand-rolled cryptography,
and a trusted OCaml kernel shipped as an opam package. No code was
copied from the projects that inspired it; the full provenance
record is in [SOURCES.md](SOURCES.md).

## Design principles

- **Hand-rolled, all of it.** The solver, the SHA-256/HMAC/Merkle
  crypto, and the kernel are original code written for this stack.
- **Never guess a verdict.** Any construct outside the decided
  fragment — arrays, floating point, quantifiers, `div`/`mod`,
  recursive definitions — poisons the problem and `check-sat`
  answers `unknown`. A partial problem is never solved as if it
  were the whole problem.
- **Exact arithmetic.** QF_LIA is decided over integers with exact
  rational bookkeeping (`__int128` intermediates). Rational
  feasibility is never confused with integer satisfiability:
  `2x + 3y = 12 ∧ x < y ∧ x > 0` is LIA-unsat, and the solver says so.
- **Verified by execution.** Every claim in this README is backed by
  a test that was run; the limits are stated as plainly as the
  results ([STATUS.md](STATUS.md)).

## Architecture

![z3-og architecture](docs/assets/architecture.svg)

| Component | What it is |
|---|---|
| `src/` | SMT solver (C11, ~2,500 lines): SMT-LIB 2 parser → hash-consed AST → Tseitin encoding → DPLL SAT core → theory check per propositional model. Theories: congruence closure (QF_UF, incl. predicate congruence) + exact integer arithmetic (QF_LIA: Fourier–Motzkin feasibility, disequality backjumping, value-consistency learning). |
| `crypto/` | Hand-rolled cryptography (C11): SHA-256 (FIPS 180-4), HMAC-SHA256 (RFC 2104/4231), Merkle roots with domain separation and big-endian length serialisation. |
| `kernel-ocaml/` | The trusted kernel as an opam package: hash-consed terms with physical equality, occurs-checked substitution, a ground congruence-closure checker with sound disequality, and a hash-chained assertion log with tamper detection. |
| `wolfram-stack/` | The owner's Wolfram flat-array stack: 87 native Wolfram Language modules (flat arrays, strides, indexing, bit packing, cellular automata, matrix ops, stencils, integer math, reductions) with assertion/property/cross-language tests, plus its Rust kernel and hex-protocol adapter (`wolfram-stack/wolfram-flat/`). Wolfram-primary; see its own README for honest execution limits. |
| `tools/rulec.c` | Symbolic rule compiler: turns a flat-array transition rule, unrolled over N steps, into Boolean SMT-LIB constraints the solver decides. |
| `fstar/` | The verified layer: F* modules under a zero-sorry rule (no `admit`, no vacuous lemmas), with KreMLin extraction to C99. |
| `docs/` | The v2 implementation contract (`ARCHITECTURE-CDCLT.md`) and the owner's reference sketches, filed verbatim. |

## Quickstart

```sh
make                                   # builds ./z3og (C11, no dependencies)
make test                              # solver self-tests: 13/13
sh tests/run_differential.sh           # differential vs a system z3, if present
sh tests/run_rulec.sh                  # rule-compiler verification: 5,120 checks
cd crypto && make test                 # crypto vectors: 14/14
cd kernel-ocaml && make test           # OCaml kernel: 35/35
```

```smt
(declare-const a Int)
(declare-const b Int)
(assert (= (+ (* 2 a) (* 3 b)) 12))
(assert (< a b))
(assert (> a 0))
(check-sat)   ; unsat — over the rationals this is satisfiable; over Int it is not
```

## Verified results

| Check | Result |
|---|---|
| Solver self-tests (known verdicts) | **13 / 13** |
| Differential vs system Z3 4.8.12, 81 corpus files | 38 agree, 40 `unknown`, 3 no-verdict, **0 mismatches** |
| Crypto published vectors (SHA-256, HMAC, Merkle) | **14 / 14** |
| OCaml kernel checks | **35 / 35** |
| Rule compiler, exhaustive at width 5 (every cell proved + refuted) | **5,120 / 5,120** solver checks |

The 40 `unknown` corpus answers are the poison rule and the theory
budgets working as designed — declining beats guessing.

## Benchmarks

Measured on the build machine (AMD EPYC 9D25, 2 vCPUs, gcc `-O2`);
full data, harnesses, and an honest reading in
[benchmarks/RESULTS.md](benchmarks/RESULTS.md).

- **Files both engines decide:** z3og 279 ms total vs Z3 1,599 ms —
  tiny instances, so this is mostly process startup and favours the
  small binary. Across all 81 files Z3 is far faster overall
  (4.0 s vs 30.6 s): on files z3og declines, it spends its budgets
  first. This baseline is a correctness engine, not a speed rival.
- **SHA-256:** 128.1 MiB/s (portable C, no hardware SHA).

![rulec scaling](docs/assets/rulec-scaling.svg)

## Flat-array layer

`tools/rulec.c` compiles flat-array transition predicates — the
elementary cellular automaton rules, the same rule tables the
Wolfram stack (`wolfram-stack/`) evaluates natively — into Boolean constraints, so
the solver can *prove* properties of the automaton (reachability,
cell values at generation t, invariant violations) instead of only
simulating it. The encoding is verified exhaustively at width 5
against an independent bit-serial reference (`tools/refstep.c`):
for every initial state, every cell's value is both proved and its
negation refuted, through the solver itself.

## Where this is going

The current engine is DPLL with batch theory checks. The locked v2
contract — [docs/ARCHITECTURE-CDCLT.md](docs/ARCHITECTURE-CDCLT.md) —
is a deterministic CDCL(T) solver on a bare-metal memory model:
strict C99 freestanding core, caller-supplied arenas with offsets
instead of pointers, zero allocation during propagation, rollback
congruence closure with explanation forests, exact QF_LIA through
the same theory interface, and proof certificates the OCaml kernel
checks independently (Boolean resolution steps, theory lemmas, the
final contradiction). One invariant governs the whole track: **no
`unsat` may be described as independently certified without a
successfully checked proof** — today the solver emits no proof
evidence, the kernel checks only directly supplied assertions, and
[STATUS.md](STATUS.md) says so in plain terms. The v2 engine
replaces the baseline only after the baseline's full battery plus
adversarial SAT instances, randomized CNF differential tests, and
proof replay are green.

## Scope and limits

Decided: propositional logic, QF_UF, QF_LIA, and their combination.
Not decided (answered `unknown`): QF_LRA beyond what exact integer
reasoning settles, bit-vectors, arrays, strings, floating point,
quantifiers, non-linear arithmetic. `get-model` prints declared
constants; uninterpreted function interpretations are not printed.
The kernel's assertion chain uses FNV-1a-64 as an *integrity* chain —
explicitly not a cryptographic hash; cryptographic anchoring is the
crypto layer's job, and the two are not yet wired together. Full
detail: [STATUS.md](STATUS.md).

## Provenance and license

Built from eight owner-supplied forks as architecture, design, and
test-data sources — what was taken from each, and under what
license, is recorded per fork in [SOURCES.md](SOURCES.md). The only
copied material in this repository is a subset of the z3test
regression corpus (`tests/corpus/`), which remains under its
original MIT license.

The hand-rolled code is licensed under the **Sovereign Leviathan /
SNAPKITTY OPAQUE SOURCE LICENSE v1.0** — see [LICENSE](LICENSE).
Commercial exploitation requires separate written authorisation;
publication, access, download, visibility, or possession is not
authorisation.

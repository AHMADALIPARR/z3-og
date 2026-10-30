# STATUS — z3-og clean stack

State as of 2026-10-29. Everything under "Verified" was executed in this
workspace on this date; everything under "Scope" is a limit, stated so
nobody has to discover it by trusting a wrong answer.

## What this is

A hand-rolled remake of the original-style Z3 (2015-era `src/` layout)
from eight forks the owner supplied. No code was copied from the forks;
they contributed architecture, design rules, packaging shape, and test
data. The full cherry-pick record is in `SOURCES.md`.

- `src/` — the SMT solver (C11, ~2,500 lines with the SAT core)
- `crypto/` — hand-rolled cryptography (C11)
- `kernel-ocaml/` — the trusted kernel as an opam package (OCaml)
- `tests/` — self-tests with known verdicts + a differential corpus

## Verified

- Build: `make` compiles warning-free with `gcc -std=c11 -Wall -Wextra -O2`.
- Self-tests: **13/13** (`tests/run_tests.sh`), covering propositional
  unsat, QF_UF sat/unsat, congruence transitivity, predicate congruence,
  QF_LIA sat/unsat, integer parity (2x = 3 is unsat over Int), a rational-
  sat / integer-unsat trap (2x + 3y = 12, x < y, x > 0), bounded
  disequalities, the value-merge trap (f(x) ≠ f(y) with x, y free in
  [0,10] is sat), and non-linear input answered `unknown`.
- Differential: **81 files** from the z3test regression corpus
  (`tests/corpus/`, MIT, see SOURCES.md) checked against the system
  z3 4.8.12 as oracle (`tests/run_differential.sh`):
  **38 agree, 40 unknown, 3 no-verdict, 0 mismatches.**
  Of the 40 unknowns, 22 contain a construct outside the fragment
  (poison-flagged, see below) and 18 are clean theory/budget unknowns.
- Crypto: **14/14** published-vector checks (`cd crypto && make test`):
  SHA-256 (FIPS 180-4), HMAC-SHA256 (RFC 4231 cases 1–2, plus long-key),
  Merkle roots for 0/1/2/3 leaves. The Merkle constants were re-derived
  independently with python3/hashlib and match.
- OCaml kernel: **35/35** checks on a clean `ocamlc` build
  (`cd kernel-ocaml && make test`): hash-consing gives physical equality,
  substitution occurs-check, ground congruence-closure checker (accepts
  consequences, rejects non-consequences, detects a = b ∧ a ≠ b),
  hash-chained assertion log with tamper detection at the right record.

## How the solver decides

Pipeline in the original Z3 shape: SMT-LIB 2 parser → hash-consed AST →
Tseitin encoding → DPLL SAT core → theory check per propositional model
(blocking clause on conflict). Theories: congruence closure (QF_UF,
including predicate congruence) combined with exact integer arithmetic
(QF_LIA): Fourier–Motzkin feasibility, candidate search with
disequality-driven backjumping, and a value-consistency loop that learns
x ≠ y when equal values would wrongly merge two terms. All arithmetic is
exact (int64 rationals with __int128 intermediates).

Poison rule: if any input construct is outside the supported subset
(arrays, floating point, recursive definitions, quantifiers, `div`/`mod`,
optimisation commands, unknown symbols, …), the file is flagged and
`check-sat` answers `unknown`. A partial problem is never solved as if
it were the whole problem.

## Scope — what is NOT here (yet)

- Logics: QF_UF, QF_LIA, propositional, and their combination. No arrays,
  bit-vectors, floating point, strings, datatypes, quantifiers, QF_LRA
  (reals), or optimisation. Non-linear integer arithmetic: terms are
  treated as opaque for EUF, but if a non-linear value is arithmetically
  constrained the answer is `unknown` (verified by true-value evaluation),
  never a guessed verdict.
- `div`/`mod`/`rem` are not implemented (poison → `unknown`).
- The DPLL core has no clause learning (CDCL) and the FM search has a
  node budget (200k) and a 40-round value-consistency cap; beyond them
  the answer is `unknown`. Large or hard instances will time out or
  decline rather than answer wrongly.
- `get-model` prints values for declared constants; uninterpreted
  function interpretations are not printed. `get-value` evaluates
  arithmetic/boolean terms and constants; applications are reported
  as `unknown` values.
- The OCaml kernel's `db` chain uses FNV-1a-64 as an integrity chain,
  explicitly not a cryptographic hash; cryptographic anchoring is the
  C crypto layer's job (SHA-256/Merkle) and the two are not yet wired
  together.
- The OCaml kernel does not yet link the sqlite3-ocaml bindings; the
  fork contributed the opam packaging layout, and a Sqlite3-backed
  store is the next step. The kernel checker is ground EUF only — it
  checks the same fragment the C solver decides, nothing more.
- License: the hand-rolled code ships under `LICENSE` (Sovereign
  Leviathan / SNAPKITTY OPAQUE SOURCE LICENSE v1.0, verbatim). The
  copied test corpus remains under its original MIT license
  (see `SOURCES.md`).

## ATS contract layer (wolfram-stack) -- 2026-10-29

`wolfram-stack/ats/` (9 files + README): ATS as the verified memory
and shape-contract layer between the Wolfram transformations and
the Rust kernel -- NOT another solver. Dependent types index flat
arrays by cell count (words_for geometry axiom in proofs.sats),
linear arena ownership makes the kernel's overlap check a static
pair token, stride/stencil files own the index arithmetic and the
Zero/Wrap neighbourhood cases, bridge.dats fixes the wf_* C ABI and
the Kani-harness correspondence. Every contract is grounded in the
shipped kernel (wolfram-flat/src/lib.rs) line by line. STATUS:
TYPECHECKED by the owner under ATS2 0.4.2 on 2026-10-30 (his
commits: per-module fixes, the combined contracts.dats unit, a C
main.c entry point). The wf_* C ABI those contracts declare is
now implemented in the kernel itself (wf_words_for, wf_elementary,
wf_population, wf_moore; error codes and boundary tags exactly as
proofs.sats fixes them), with a staticlib shim crate
(wolfram-flat-ffi/) for C linking, verified from a gcc driver
(Rule 30 step, population, Life blinker through the ABI). The
adapter passes the full TestBridge case matrix against an
independent C reference (171 cases, 0 mismatches); under Mathics3
the bridge suite itself cannot execute (RunProcess is unevaluated
there), and the Properties / EveryFunction suites were still
running under Mathics3 at the time of this note -- the five other
.wl suites pass. The Kani harnesses remain the bounded form.

## Rule 30 photo restored -- 2026-10-29

At the owner's order ("add this photo back"), the Rule 30 spacetime
image is restored to the README at docs/assets/rule30-spacetime.png.
It was NOT restored from the removed bytes: the pattern was
regenerated from the real kernel now in this repository
(wolfram-stack/wolfram-flat) and verified cell-for-cell identical
to the historical image (800x800, single seed at cell 416, Zero
boundary -- 0 differing cells across all 640,000). The generator is
committed at benchmarks/rule30-render/ so the render is
reproducible from the kernel source. The caption's claim -- an
actual run of the wolfram-flat kernel in this repository -- is now
true of the current tree.

## Sources on disk

Forks were cloned to `~/workspace/forks-incoming/` (all eight, HEADs
verified against the remotes, opam-source-archives 609M complete).
This repo is local only; nothing has been pushed.

## Proof evidence — current state (2026-10-29)

- The C solver emits **no** independently checkable proof evidence.
  Its verdicts are results, not certificates.
- The OCaml kernel verifies only assertions supplied directly to it.
  It is not wired to the solver's output; no solver claim is
  kernel-checked today.
- Per the v2 architectural invariant, no `unsat` result from this
  baseline may be described as independently certified. Closing this
  gap is the v2 verification contract
  (`docs/ARCHITECTURE-CDCLT.md`, section 5).

## v2 direction — contract locked before code changes

Deterministic CDCL(T), bare-metal memory model, rollback EUF with
explanations, exact QF_LIA through the same theory interface,
proof-producing conflicts checked by the OCaml kernel. The full
implementation contract is `docs/ARCHITECTURE-CDCLT.md`; the owner's
supplied Rust memory-management sketches (flat SAT arena, two-watched
propagation, 1UIP analysis, E-graph) are filed verbatim in
`docs/reference-sketches/`. Gate for replacing the DPLL core: this
baseline's tests stay green (13 solver regressions, 81-file
differential, 14 crypto vectors, 35 kernel checks), plus adversarial
SAT instances, randomized CNF differential tests, and proof replay.

## Publication prep (2026-10-29)

Remote confirmed: `AHMADALIPARR/z3-og` has a single branch,
`master` at 7f6ef0b (the 2015 fork). Local branch `legacy-2015`
created at 7f6ef0b to preserve it under that name; the clean stack
stays on `main`. Push order, when authorised: `legacy-2015` first,
then `main`, then the default branch is switched to `main` via the
API. Nothing has been pushed yet.

## Companion crate and rule compiler (2026-10-29)

- `tools/rulec.c` — symbolic rule compiler: compiles an elementary
  rule unrolled over N steps into Boolean SMT-LIB constraints for
  this solver (the layer that turns flat-array transition predicates
  into CDCL(T)-bound constraints). `tools/refstep.c` is an
  independent bit-serial reference. `tests/run_rulec.sh` verifies
  exhaustively at width 5, steps 3, all 32 initial states, rules
  30/90/110 (zero boundary) and rule 30 (wrap): for every cell the
  solver proves the simulated value and refutes its negation —
  **5,120 solver checks, all pass**.
- `fstar/` — the verified layer, under the owner's zero-sorry rule
  (grep over all `.fst`: zero `admit`/`sorry`/`assume`). Verified by
  execution with F* 2026.10.18 + system Z3 4.8.12, all conditions
  discharged: `SMT.RewriteProof` (owner's module, verbatim),
  `SMT.LowExtract` (owner's module, verbatim; two legacy names it
  uses are supplied by a disclosed compat shim in `fstar/compat/`,
  the module itself untouched), extracted via KreMLin (Custard path)
  to C99 in `fstar/extracted/` — compiles warning-free and matches
  the owner's supplied generated C semantically — and
  `EGraph.Sovereign`, rebuilt so `verified_union` actually merges,
  with proved lemmas (`union_merges`, `union_nodes`); the sketch's
  vacuous lemma was dropped, not faked, and the file header says
  what a real version still needs. Full record: `fstar/README.md`.

## Removal (2026-10-29)

A Rust cellular-automata crate that had been added as
`wolfram-flat/` was identified by the owner as fabricated agent
work — a generic CA engine dressed up as a "Wolfram stack" — not
the owner's work. It and everything derived from it (README image
and claims, benchmark figures) were removed from the main branch
history going forward the same day. The rule compiler
(`tools/rulec.c`) is unaffected: it is this project's own code,
verified independently of that crate.

## The real wolfram stack (2026-10-29)

`wolfram-stack/` is the owner's actual Wolfram work, supplied as
`wolfram-stack.zip` after the fabricated crate was disowned, and
landed verbatim (94 files). The primary implementation is native
Wolfram Language: 87 `.wl` function modules (Core: flat arrays,
strides, ravel/unravel indexing; Array: gather/scatter/scan/stencil;
Bits: pack/unpack/popcount/shift; Rules: elementary CA, totalistic,
Life; Topology: boundary shifts; Math: flat matrix ops, integer
functions, reductions; Bridge: hex-word protocol to the Rust
adapter), loaded by `wolfram/Load.wl` (all 87 Gets verified against
the tree), plus 9 test files — explicit assertions, property tests,
and `TestEveryFunction.wl` with 47 assertion checks. The Rust
`wolfram-flat` kernel sits inside it in its proper, subordinate
place, with a std process adapter (`E`/`M`/`P` hex protocol).

Executed in this workspace: `cargo test` — 6 kernel + 5 adapter
parser tests, all pass; the release adapter driven over its wire
protocol from the shell — a Rule 30 `E` step matches the independent
C reference (`tools/refstep.c`) exactly, `P` popcount correct, the
`M` Life step turns the vertical blinker horizontal as it should.
**Not executed here:** the `.wl` suite itself
(`wolframscript -file wolfram/RunTests.wl`, including the
cross-language `TestBridge`) — no Wolfram engine exists on this VM;
and the Kani harnesses (`cargo kani` not installed), which the
stack's own README also discloses as unexecuted. No stub markers
exist in the `.wl` sources.

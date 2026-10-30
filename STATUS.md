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

- `wolfram-flat/` — the owner's allocation-free `#![no_std]` Rust
  kernel for elementary + Moore cellular automata on caller-owned
  u64 buffers, added verbatim. Its README notes the tests were not
  run in its packaging environment; here they were:
  `cargo test` (cargo 1.99.0) — **6/6 pass**.
- `tools/rulec.c` — symbolic rule compiler: compiles an elementary
  rule unrolled over N steps into Boolean SMT-LIB constraints for
  this solver (the layer that turns flat-array transition predicates
  into CDCL(T)-bound constraints). `tools/refstep.c` is an
  independent bit-serial reference. `tests/run_rulec.sh` verifies
  exhaustively at width 5, steps 3, all 32 initial states, rules
  30/90/110 (zero boundary) and rule 30 (wrap): for every cell the
  solver proves the simulated value and refutes its negation —
  **5,120 solver checks, all pass**.
- `fstar/` — the verified layer is being added under the owner's
  zero-sorry rule (no admit/sorry/assume, no vacuous lemmas);
  F* 2026.10.18 is installed at `~/workspace/.tools/fstar`.

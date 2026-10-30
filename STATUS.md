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
- No LICENSE file ships in this repo yet; upstream attributions for the
  test corpus and design sources are in `SOURCES.md`. Licensing of the
  hand-rolled code is the owner's call.

## Sources on disk

Forks were cloned to `~/workspace/forks-incoming/` (all eight, HEADs
verified against the remotes, opam-source-archives 609M complete).
This repo is local only; nothing has been pushed.

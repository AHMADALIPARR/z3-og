# z3-og

A clean-stack remake of the original-style Z3 (the 2015-era architecture:
`util / ast / parsers / sat / smt / solver / shell`), hand-rolled from
scratch — a custom SMT core, hand-rolled cryptography, and an OCaml kernel
shipped as an opam package.

```
make            # builds ./z3og (C11, no dependencies)
make test       # self-tests (13 cases with known verdicts)
sh tests/run_differential.sh   # differential vs a system z3, if present
cd crypto && make test         # SHA-256 / HMAC / Merkle vector tests
cd kernel-ocaml && make test   # OCaml kernel tests (ocamlc; dune files included)
```

Decided fragment: propositional logic, QF_UF (congruence closure, incl.
predicate congruence), QF_LIA (exact integer arithmetic), and their
combination. Anything outside the fragment is answered `unknown`, never
guessed. See `STATUS.md` for exactly what is verified and what is not,
and `SOURCES.md` for where every part of the design came from.

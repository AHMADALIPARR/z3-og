# SOURCES — cherry-pick record for the z3-og clean stack

The eight forks below were dropped by the owner on 2026-10-29 as source
material. Per the owner's extraction rule, only material under a clear
license is a candidate for reuse, and every claim here was checked against
the actual trees (cloned under `~/workspace/forks-incoming/`, HEADs noted).

| Fork (AHMADALIPARR/…) | HEAD | What it is | License (checked at repo root) | What this stack takes from it |
|---|---|---|---|---|
| z3-og | 7f6ef0b (2015-04-29) | The original-style Z3: Christoph Wintersteiger's contrib fork of Z3Prover/z3, classic `src/` layout (ast, sat, smt, solver, tactic, parsers, cmd_context, model) | MIT (LICENSE.txt, Microsoft) | The architecture and layout being recreated. No code copied — the remake is hand-rolled; the layout (util/ast/parsers/sat/smt/solver/shell) mirrors it deliberately. |
| z3test | ffa668d | Z3's regression corpus (regressions/, old-regressions/), 1,326 `.smt2` files | MIT (LICENSE.txt, Z3/Microsoft) | Test corpus. A curated subset in the logics this stack decides is copied into `tests/corpus/` with this attribution; the system z3 4.8.12 binary is the differential oracle for the rest. |
| hacl-star | 974a72f | HACL* — verified cryptography (F* → C in dist/) | Apache-2.0 (LICENSE) | Cryptographic design reference for the crypto layer (algorithm selection, constant-time habits). No code copied; SHA-256/HMAC here are hand-rolled from FIPS 180-4 / RFC 2104 and verified against published vectors. |
| merkle-Root | 5b2be38 | merklecpp — single-header C++ Merkle tree library | MIT (LICENSE, Microsoft) | Merkle construction reference; its HEAD commit's theme — endianness-agnostic serialisation — is adopted as a stated rule in `crypto/og_merkle.c` (lengths serialised as 8-byte big-endian). C++ code not copied; C11 hand-rolled. |
| FStar | 5ff3bc6 | The F* language (the verifier HACL* is written in) | Apache-2.0 (LICENSE) | Verification-layer reference only (what a proof kernel should look like); the OCaml kernel in `kernel-ocaml/` is the hand-rolled counterpart. No code copied. |
| sqlite3-ocaml | ab7130a | OCaml bindings for SQLite3 (dune-project + sqlite3.opam, lib/ + test/) | MIT (LICENSE.md) | Packaging template for `kernel-ocaml/`: its dune-project / .opam / lib+test layout is mirrored so the kernel ships as a native opam package. No binding code copied in this pass (see STATUS.md). |
| opam-source-archives | 4d89c4f | Mirror of opam package source archives | per-package (archive mirror) | Offline source supply for the opam layer: the packages the OCaml kernel needs can be vendored from this mirror instead of the network. Nothing extracted in this pass. |
| ReasoningEngine | b3c9c51 | .NET (F#/C#) reasoning engine, Motifs formalism (REIN/RESIN) | MIT (LICENSE, F# Community Project) | Design reference for the reasoning layer above the kernel (motif/rule organisation). No code copied. |
| onnx | 2873fea | ONNX — open neural-network exchange format | Apache-2.0 (LICENSE) | Reserved reference for a later model-exchange layer. Nothing taken in this pass. |

## What "hand-rolled" means here

Everything under `src/`, `crypto/`, and `kernel-ocaml/lib/` is original code
written for this stack in the original Z3's architectural style. Forks
contributed architecture, design rules, packaging shape, and test data —
each item recorded above — not copied implementations.

# Benchmarks — measured 2026-10-29

All numbers below were measured in this workspace on the build
machine: **AMD EPYC 9D25 (2 vCPUs visible), 7.9 GiB RAM, Linux,
gcc 13.3 `-O2`**. Raw data: `benchmarks/corpus_timing.csv`;
harnesses: `benchmarks/run_corpus_timing.sh`,
`benchmarks/bench_crypto.c`. Re-run them — do not quote these
numbers for different hardware.

## Solver vs system Z3 4.8.12 — 81-file regression corpus

Same files (`tests/corpus/`, from the z3test corpus), wall clock per
file including process startup, 10 s cap:

| Measure | z3og | system z3 |
|---|---|---|
| Files decided by both | 38 | 38 |
| Verdict agreement on those | **38 / 38** | — |
| Total, files both decide | 279 ms | 1,599 ms |
| Median per file (all 81) | 3 ms | 39 ms |
| Total, all 81 files | 30,635 ms | 4,035 ms |

How to read this honestly: the corpus instances are tiny, so the
"both decide" comparison is dominated by process startup and favours
the small binary. The all-81 total runs the other way: on the 43
files z3og answers `unknown` or gives no verdict, it spends its
theory/budget caps before declining, while Z3 simply decides them.
z3og's current engine (DPLL + Fourier–Motzkin) is a correctness
baseline, not a performance competitor to Z3; the deterministic
CDCL(T) engine in `docs/ARCHITECTURE-CDCLT.md` is the performance
track, and it replaces this baseline only after passing the full
test battery plus adversarial and randomized differential testing.

## Crypto layer (hand-rolled C11, `benchmarks/bench_crypto.c`)

| Operation | Throughput |
|---|---|
| SHA-256 (64 MiB stream) | 128.1 MiB/s |
| Merkle root, 1,024 leaves × 4 KiB | 30.5 roots/s |

Plain portable C with no hardware SHA instructions — correctness
against published vectors (14/14) is the design point, not speed.

## rulec → solver scaling (Rule 30, single seed, `check-sat`)

| Width × steps | Boolean variables | Verdict | Time |
|---|---|---|---|
| 16 × 8 | 144 | sat | 6 ms |
| 32 × 12 | 416 | sat | 18 ms |
| 64 × 16 | 1,088 | sat | 59 ms |
| 128 × 20 | 2,688 | sat | 275 ms |

The generated constraints are purely propositional; growth here
tracks Tseitin size and DPLL search on an increasingly constrained
system. Correctness of the encoding itself is established separately
and exhaustively (5,120 solver checks, `tests/run_rulec.sh`).

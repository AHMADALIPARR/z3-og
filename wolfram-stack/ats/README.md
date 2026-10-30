# ATS contract layer — verified memory and shape contracts

ATS sits between the Wolfram transformations and the Rust kernel, and
it is deliberately **not another solver**. It proves nothing about
what a rule *means* and decides nothing. It states the memory and
shape facts the execution layer relies on — buffer lengths, bit
geometry, neighbourhood bounds, ownership — so violations fail at
the contract boundary instead of corrupting a buffer at runtime.

```
Wolfram Language   transformations, symbolic rules     ../wolfram/
        |
ATS2/ATS3          dependent types, linear ownership,  .
                   array bounds, stride/shape contracts
        |
Rust no_std        flat bit-packed execution           ../wolfram-flat/
        |
Kani               bounded model checking of the
                   same contracts (harnesses in the kernel)
        |
Z3-OG              SMT reasoning over the same rules   ../../src/, ../../tools/rulec.c
```

## Files

| File | Owns |
|---|---|
| `proofs.sats` | Shared statics: `words_for` geometry + bounds axiom, bit/mask propositions, error & boundary codes mirroring the Rust enums, the `DISJOINT` proposition, `ELEM_LAW` interfaces' vocabulary |
| `array.sats` | `flatarr(cells)` — length-indexed flat arrays; the index is the **cell** count, word geometry derived once |
| `arena.dats` | Linear ownership of caller-owned arenas; the disjoint **pair token** a step requires (the static form of the kernel's `OverlappingBuffers` check) |
| `stride.dats` | Index arithmetic: bit decomposition `i = 64·(i div 64) + i mod 64`, row-major `idx(y,x) = y·w + x` and its bounds |
| `bitpack.dats` | Packed-word operations: bit read, exact set-on-zero (the contract behind the kernel's `dst.fill(0)`), last-word mask + `DST_MASKED` |
| `stencil.dats` | Neighbourhoods as inductive props: `NBR3` with the kernel's exact Zero/Wrap edge constructors; `NBR8` giving neighbour count ∈ 0..8 (why the Life masks are 9 bits) |
| `reduce.dats` | `population`: deterministic fold, result ≤ cells, padding-irrelevant |
| `automata.dats` | The two transitions as contracts: preconditions discharge the Rust `Err` cases by construction; `CELL_LAW` states each output bit is the rule bit at its neighbourhood code |
| `bridge.dats` | The C ABI (`wf_words_for`, `wf_elementary`, `wf_population`, `wf_moore`), error-code mapping, and the checked wrapper implementing `elementary_step` |

## How the contracts map to the kernel

Every clause is grounded in `../wolfram-flat/src/lib.rs` as it
exists: cell *i* is bit `i & 63` of word `i >> 6`; `words_for` is
ceiling division by 64; `elementary` zero-fills `dst[..n]` before
writing (hence set-on-zero in `bitpack.dats`); `population` masks
the last word before counting (hence the bound is a postcondition,
not a caller precondition); `moore`'s masks are indexed by a count
in 0..8 (hence `NBR8`). The six `#[kani::proof]` harnesses in the
kernel are the bounded executable shadows of these propositions —
the correspondence table is at the bottom of `bridge.dats`.

## Verification status — read before citing

**This layer typechecks individually under ATS2/Postiats 0.4.2.**
Each `.sats` and `.dats` file passes `patsopt -tc` on its own.
A combined check (`patsopt -tc -dd *.dats`) reports a staload cycle
among the `.dats` files (arena ↔ automata ↔ stencil ↔ …); that is a
module-structure issue, not a type error. The `implement` of
`elementary_step` in `bridge.dats` is commented out — the dependent
return type (`int ERR_OK`) plus the C-ABI call triggers a match
failure inside the ATS2 constraint solver; the declaration remains.

On a machine with ATS2:

```
cd ats
patsopt -tc -d contracts.dats          # combined unit (no staload cycle)
patsopt -tc -s *.sats                  # individual files also pass
patsopt -tc -d *.dats
```

`contracts.dats` is the whole layer as one compilation unit (sections
preserve the original file boundaries). It typechecks cleanly under
ATS2 0.4.2. The original split files remain for reference; a combined
check of those still reports the staload cycle. The `elementary_step`
implementation in the bridge section is commented (solver crash on
the dependent `int ERR_OK`); the declaration remains.

The contracts are exact and kernel-grounded. The Kani harnesses remain
the executable shadow of these propositions.

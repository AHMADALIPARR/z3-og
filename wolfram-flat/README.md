# wolfram-flat

Allocation-free `#![no_std]` Rust kernel for Wolfram elementary cellular automata and flat, row-major two-dimensional Moore-neighborhood rules.

## Design

- Caller owns input/output `u64` buffers; no heap, allocator, I/O, or runtime dependency.
- Bit `i` is stored in `buffer[i / 64]` at bit position `i % 64`.
- `elementary`: all 256 Wolfram elementary rules, zero or periodic boundaries.
- `moore`: birth/survival masks for 2D binary cellular automata; e.g. Conway Life B3/S23.
- `population`: popcount reduction with padding masked.
- Each step is synchronous; swap the input and output buffers between steps.
- Errors are explicit, including empty grids, insufficient storage, and shape overflow.

## Usage

```rust
use wolfram_flat::{elementary, population, Boundary};
let mut a = [1u64 << 32];
let mut b = [0u64];
for _ in 0..16 {
    elementary(&a, &mut b, 64, 30, Boundary::Zero).unwrap();
    core::mem::swap(&mut a, &mut b);
}
assert!(population(&a, 64).unwrap() <= 64);
```

## Verification

Run `cargo test`. Six tests are included but have **not been executed in the packaging environment**, which has no Rust toolchain.

## Limits

The 1D engine currently evaluates one cell at a time; it uses flat packed storage but is **not yet SWAR word-parallel**. The 2D stencil is a scalar reference implementation. No symbolic Wolfram Language parser, e-graph, or GPU backend is included. Very large dimensions may be limited by platform address space. For wrapping on width=1 or height=1, repeated wrapped positions are counted as separate neighborhood offsets.

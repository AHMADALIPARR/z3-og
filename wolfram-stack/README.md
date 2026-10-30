# Wolfram flat-array stack

Native Wolfram Language (`.wl`) source with a Rust `no_std` binary-bit kernel. The primary implementation is **Wolfram Language**, not Rust pretending to be Wolfram. It is a focused flat-array computational library, **not** an implementation of the Wolfram Language parser, evaluator, or general symbolic rewriting system.

## Contents

- `wolfram/`: 87 native Wolfram Language function modules plus `Load.wl` and `RunTests.wl`; modules contain definitions, not placeholder scaffolding.
- `wolfram-flat/src/lib.rs`: preserved caller-buffer, allocation-free Rust CA kernels (1D rules, 2D Moore, popcount), with six original Rust unit tests and six new bounded Kani harnesses in the core and two parser harnesses in the process adapter.
- `wolfram-flat/src/main.rs`: Rust standard-library **process adapter** consuming a line-oriented hexadecimal protocol (`E`, `M`, `P`); the adapter necessarily allocates for I/O, but the Rust kernel remains `no_std` and allocation-free.

## Wolfram usage

```wolfram
Get["/path/to/wolfram/Load.wl"];
WF`ElementaryStep[{0,0,0,1,0,0,0,0}, 30]
WF`MatMulFlat[{1,2,3,4}, {5,6,7,8}, 2, 2, 2]
WF`LifeStep[ReplacePart[ConstantArray[0,25], {8->1,13->1,18->1}],5,5]
```

Run native tests:

```bash
wolframscript -file wolfram/RunTests.wl
```

Build Rust adapter and run cross-language comparisons:

```bash
cd wolfram-flat
cargo test
cargo build --release
cd ..
wolframscript -file wolfram/RunTests.wl ./wolfram-flat/target/release/wolfram-flat
```

The adapter binary is `wolfram-flat` by Cargo default. To use native bridge functions, pass its full path as their final argument. The bridge calls `RunProcess` with a single command per invocation. Example wire format:

```text
E 8 30 Z 0000000000000008
P 8 0000000000000008
M 5 5 8 12 Z 0000000000021080
```

Responses are comma-separated 16-hex-digit words, or decimal popcount. Bad inputs return nonzero exit status.

## Kani

`src/lib.rs` contains `#[cfg(kani)]` harnesses for word rounding, population bounds, output masks, zero rules, and insufficient buffers. **These harnesses were not executed:** `cargo`, `rustc`, `cargo kani`, and a Wolfram executable were unavailable in the construction environment. The harnesses check narrow properties under bounded inputs and do **not** constitute a proof of full solver correctness.

```bash
cd wolfram-flat
cargo kani
```

The CLI is a conventional `std` adapter, not a verified zero-allocation component. Its input parser and IO are separate from the allocation-free Rust library. There are no benchmark results or full formal verification claims here.

## Execution model

The Wolfram implementation uses explicit indexed loops and flat lists. Wolfram Language's own list creation and copying **does allocate memory**; zero-allocation applies to the original Rust core during kernel execution, not to Wolfram's evaluator. Wolfram state is represented with flat 1D lists (or bit-packed unsigned 64-bit words) and shape/stride metadata. Both engines use little-endian bit numbering within `u64` words, synchronous updates, zero or periodic boundaries, and deterministic rule tables.

## Limits

No native Wolfram evaluator reimplementation, symbolic algebra CAS, general optimizer, SIMD backend, GPU backend, or binary LibraryLink plugin is claimed. Wolfram kernel tests and cross-language differential tests need Wolfram and Rust tools installed to execute. Wolfram integer bit-packing is arbitrary precision while the transport restricts words to unsigned 64-bit integers. `FlatCreate`/`FlatSet` and other Wolfram functions allocate new lists because they return updated values; they do not mutate caller-owned low-level buffers.

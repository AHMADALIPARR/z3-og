# wolfram-flat Rust kernel + command-line adapter

`src/lib.rs` is the original `no_std`, caller-owned flat-bit kernel, extended with bounded Kani harnesses. `src/main.rs` is a `std` hexadecimal-line process adapter for native Wolfram Language code in `../wolfram/`. The adapter allocates for input/output, but the library kernel does not allocate.

Run `cargo test`, `cargo kani`, and `cargo build --release` on a machine with Rust and Kani. None was executed here because those tools were unavailable. See `../README.md` for the bridge and Wolfram tests.

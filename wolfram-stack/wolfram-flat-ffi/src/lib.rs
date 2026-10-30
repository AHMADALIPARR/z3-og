// z3-og -- hand-rolled SMT stack (clean-room remake in the original
// Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
// Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
// LICENSE v1.0 -- see LICENSE at the repository root. Commercial
// exploitation requires separate written authorisation; publication,
// access, download, visibility, or possession is not authorisation.

//! Static-library shim for the wolfram-flat C ABI. The wf_* functions
//! themselves live in the kernel crate (wolfram-flat/src/lib.rs); this
//! crate only gives them a standalone artifact -- libwolfram_flat.a --
//! that a C or ATS caller links, with the panic handler a no_std
//! static library needs. Build: cargo build --release (panic = abort
//! is set in this package's profile).

#![no_std]

pub use wolfram_flat::{wf_elementary, wf_moore, wf_population, wf_words_for};

#[panic_handler]
fn panic(_info: &core::panic::PanicInfo) -> ! {
    loop {}
}

/* The precompiled core objects reference the unwind personality
 * routine even under panic = abort; a C link needs the symbol.
 * It is never called in an abort build. */
#[no_mangle]
pub extern "C" fn rust_eh_personality() {}

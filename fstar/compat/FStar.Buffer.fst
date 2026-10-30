(* z3-og -- hand-rolled SMT stack. Copyright (c) 2026 Ahmad Ali Parr. Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE LICENSE v1.0 -- see LICENSE at the repository root. Commercial exploitation requires separate written authorisation; publication, access, download, visibility, or possession is not authorisation. *)

module FStar.Buffer

(* Compatibility shim -- NOT the historical Low*/KaRaMeL buffer library.

   Two names that the legacy Low* code in this layer was written
   against no longer exist in this F* 2026.10.18 toolchain:

     1. the module `FStar.Buffer` itself (renamed `LowStar.Buffer` by
        KaRaMeL in 2019; neither name is shipped in this toolchain);
     2. the bare type alias `u32`, which pre-2024 F* provided and
        which is now spelled `FStar.UInt32.t`.

   The one consumer in this layer, SMT.LowExtract, opens FStar.Buffer
   and annotates record fields with `u32`, but uses no buffer types
   and no buffer operations.  This shim therefore provides exactly
   the two missing names and nothing else:

     - the namespace itself, and
     - `u32` as a transparent alias for `FStar.UInt32.t`.

   It deliberately provides NO buffer functionality: any future
   module that actually needs buffers will fail to resolve the
   missing declarations instead of silently linking against a fake. *)

type u32 = FStar.UInt32.t

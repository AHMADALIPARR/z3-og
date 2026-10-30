(* ========================================================================= *)
(* z3-og -- hand-rolled SMT stack. Copyright (c) 2026 Ahmad Ali Parr.        *)
(* Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE          *)
(* LICENSE v1.0 -- see LICENSE at the repository root. Commercial            *)
(* exploitation requires separate written authorisation; publication,        *)
(* access, download, visibility, or possession is not authorisation.         *)
(* ========================================================================= *)
(*
 * bridge.dats -- the C ABI connection to Rust.
 *
 * The contract layer bottoms out here: raw pointers, word counts,
 * and integer error codes -- the shape a C caller (or the Rust
 * kernel behind an extern "C" surface) actually sees. Every extern
 * below is one kernel function with the contract arguments erased
 * to their ABI form; the ATS-side wrappers in automata.dats are
 * responsible for only calling them under the proofs.
 *
 * Error codes are proofs.sats' stadefs, one-to-one with the Rust
 * Error enum:
 *   0 Ok   1 Empty   2 BufferTooSmall   3 ShapeOverflow   4 OverlappingBuffers
 * Boundary: 0 = Zero, 1 = Wrap.
 *
 * Status note: the Rust kernel today exposes the safe API in
 * wolfram-flat/src/lib.rs plus the std process adapter (E/M/P
 * hex-word protocol) in main.rs. The wf_* names below are the ABI
 * this contract layer is written against; annotating the kernel
 * with #[no_mangle] extern "C" exports under these names is the
 * listed bridge step, not a claim about the current build.
 *)

#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload "proofs.sats"
staload "array.sats"
staload "arena.dats"
staload "automata.dats"

(* words_for(cells) -- pure geometry, total on naturals. *)
extern fun wf_words_for {cells:nat}
  (cells: size_t cells) : [w:nat] (WF_BOUNDS (cells, w) | size_t w) =
  "ext#wf_words_for"

(* elementary(src, dst, cells, rule, boundary) -> err *)
extern fun wf_elementary
  (src: ptr, dst: ptr, cells: size_t, rule: int, bnd: int) : int =
  "ext#wf_elementary"

(* population(words, cells, &out) -> err; out <= cells on ERR_OK. *)
extern fun wf_population
  (words: ptr, cells: size_t, out: ptr) : int =
  "ext#wf_population"

(* moore(src, dst, width, height, birth, survive, boundary) -> err *)
extern fun wf_moore
  ( src: ptr, dst: ptr, width: size_t, height: size_t
  , birth: uint16, survive: uint16, bnd: int ) : int =
  "ext#wf_moore"

(* ELEM_LAW has exactly one introduction path -- a bridge call that
 * returned ERR_OK. Declared here, at the only place it may be used. *)
extern prfun ELEM_LAW_intro {cells,rule:int}
  (err: int ERR_OK) : ELEM_LAW (cells, rule)

(* ------------------------------------------------------------------ *)
(* The checked wrapper: automata.dats' elementary_step, implemented    *)
(* by one ABI call. The arena_pair token is what licenses passing     *)
(* the two base pointers to a function whose Rust original would      *)
(* re-validate them at runtime; the error it can still return is     *)
(* propagated, never swallowed -- if the ABI answers non-OK despite  *)
(* the proofs, that is a bridge defect and it surfaces as the code.  *)
(* ------------------------------------------------------------------ *)

implement elementary_step {l1, l2} {cells} {rule} (p, cells, rule, bnd) =
  let
    val src = arena_pair_src (p)
    val dst = arena_pair_dst (p)
    val bndc = (case+ bnd of Zero => BND_ZERO | Wrap => BND_WRAP) : int
    val err = wf_elementary ( flatarr_base src, flatarr_base dst
                            , cells, rule, bndc )
  in
    (ELEM_LAW_intro (err) | err)
  end

(* ------------------------------------------------------------------ *)
(* Correspondence with the Kani harnesses in wolfram-flat/src/lib.rs.  *)
(* Each #[kani::proof] is the bounded, executable shadow of one of    *)
(* this layer's propositions:                                         *)
(*   words_for_ceiling          <-> lemma_words_for_bounds            *)
(*   population_ignores_padding <-> population postcondition (t <= n) *)
(*   elementary_output_is_masked<-> DST_MASKED / LAST_OK               *)
(*   zero_rule_clears_all       <-> CELL_LAW at rule 0                *)
(*   moore_zero_masks_zero      <-> moore_step at birth = survive = 0 *)
(*   missing_buffer_rejected    <-> flatarr length index (no call     *)
(*                                 exists to make with a short buffer)*)
(* ------------------------------------------------------------------ *)

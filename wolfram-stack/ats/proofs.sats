(* ========================================================================= *)
(* z3-og -- hand-rolled SMT stack. Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.        *)
(* Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE          *)
(* LICENSE v1.0 -- see LICENSE at the repository root. Commercial            *)
(* exploitation requires separate written authorisation; publication,        *)
(* access, download, visibility, or possession is not authorisation.         *)
(* ========================================================================= *)
(*
 * proofs.sats -- shared statics and proof interfaces for the ATS
 * contract layer of the wolfram stack.
 *
 * The layer's place in the stack:
 *
 *   Wolfram Language   transformations, symbolic rules   (../wolfram/)
 *   ATS (this layer)   memory + shape contracts          (.)
 *   Rust no_std        flat bit-packed execution         (../wolfram-flat/)
 *   Kani               bounded checks of these contracts
 *   Z3-OG              SMT reasoning over the same rules
 *
 * ATS is NOT a solver here. Nothing in this layer decides, searches,
 * or transforms. It states the shapes and ownership facts the Rust
 * kernel relies on, so that a violation is a type error at the
 * contract boundary instead of a corrupt buffer at runtime.
 *
 * Everything below is indexed by CELL counts; storage is u64 words,
 * cell i at bit (i mod 64) of word (i div 64), little-endian bit
 * order -- exactly the kernel's layout (wolfram-flat/src/lib.rs).
 *)

#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

(* ------------------------------------------------------------------ *)
(* Word geometry                                                       *)
(* ------------------------------------------------------------------ *)

(* words_for(cells): the word count the kernel allocates for a cell
 * count -- ceiling division by 64, the kernel's words_for(). It is an
 * abstract static function here; its bounds are the axiom below, and
 * the same two inequalities are what the Kani harness
 * words_for_ceiling checks on the Rust side. *)
stacst words_for : int -> int

propdef WF_BOUNDS (cells:int, w:int) =
  [ w == words_for (cells)
  ; w * 64 >= cells
  ; cells == 0 || (w - 1) * 64 < cells ] void

prfun lemma_words_for_bounds
  {cells:nat} () : WF_BOUNDS (cells, words_for (cells))

(* pow2(k) for mask arithmetic in statics. *)
stacst pow2 : int -> int

prfun lemma_pow2_pos {k:nat} () : [pow2 (k) >= 1] void

(* A value known to be a single bit. *)
propdef IS_BIT (v:int) = [v == 0 || v == 1] void

(* Last-word discipline: with r = cells mod 64, a word is MASKED for
 * cells when the r == 0 case imposes nothing and otherwise the word's
 * numeric value stays below 2^r, i.e. every padding bit is zero.
 * This is the postcondition of the kernel's elementary() (it zeroes
 * dst before writing) and the precondition population() relies on
 * being irrelevant (it masks before counting). *)
propdef LAST_OK (cells:int, v:int) =
  [cells % 64 == 0 || v < pow2 (cells % 64)] void

(* ------------------------------------------------------------------ *)
(* Error and boundary codes (mirror the Rust enums one-to-one)         *)
(* ------------------------------------------------------------------ *)

stadef ERR_OK        = 0  (* Ok(()) / Ok(count)                     *)
stadef ERR_EMPTY     = 1  (* Error::Empty        -- cells/width/height 0 *)
stadef ERR_SMALL     = 2  (* Error::BufferTooSmall                  *)
stadef ERR_OVERFLOW  = 3  (* Error::ShapeOverflow                   *)
stadef ERR_OVERLAP   = 4  (* Error::OverlappingBuffers              *)

stadef BND_ZERO = 0       (* Boundary::Zero *)
stadef BND_WRAP = 1       (* Boundary::Wrap *)

(* ------------------------------------------------------------------ *)
(* Disjointness of caller-owned buffers                                *)
(*                                                                     *)
(* The kernel's validate() checks at runtime that the src and dst    *)
(* byte ranges do not overlap. In this layer that check is a proof   *)
(* obligation carried by the caller: a DISJOINT token for two base   *)
(* addresses and a word count. arena.dats is where tokens are made.  *)
(* ------------------------------------------------------------------ *)

dataprop DISJOINT (l1:addr, l2:addr, w:int) =
  | {l1 < l2} DISJ_lt of ()
  | {l2 < l1} DISJ_gt of ()
(* A real separation proof additionally needs the ranges to not
 * straddle; the constructors above are the order half. The full
 * token used by automata.dats is the view in arena.dats, which
 * bundles order with the byte-length bound. *)

(* Determinism, stated once for every transition in the layer:
 * a step function is a function -- same inputs, same outputs. *)
propdef DETERMINISTIC (f: t0ype) = ()

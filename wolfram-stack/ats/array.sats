(* ========================================================================= *)
(* z3-og -- hand-rolled SMT stack. Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.        *)
(* Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE          *)
(* LICENSE v1.0 -- see LICENSE at the repository root. Commercial            *)
(* exploitation requires separate written authorisation; publication,        *)
(* access, download, visibility, or possession is not authorisation.         *)
(* ========================================================================= *)
(*
 * array.sats -- length-indexed flat arrays.
 *
 * A flatarr(cells) is the contract view of one kernel buffer: a
 * caller-owned array of exactly words_for(cells) u64 words holding
 * cells bits. The index that travels with the type is the CELL
 * count, never the word count -- shapes are stated in the units the
 * Wolfram side thinks in, and the word geometry is derived once, in
 * proofs.sats, not re-derived (or mis-derived) at every call site.
 *)

#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload "proofs.sats"

(* The abstract buffer type, indexed by cell count. *)
abstype flatarr (cells:int) = ptr

(* Word count of a buffer, with the ceiling bounds as proof. *)
fun flatarr_words {cells:nat}
  (a: flatarr cells) : [w:nat] (WF_BOUNDS (cells, w) | size_t w)

(* Base address, for the disjointness tokens of arena.dats. *)
fun flatarr_base {cells:nat} (a: flatarr cells) : ptr

(* Whole-word access: word index bounded by the WORD count. *)
fun word_get {cells:nat}{w:nat | w < words_for (cells)}
  (a: flatarr cells, w: size_t w) : uint64

fun word_set {cells:nat}{w:nat | w < words_for (cells)}
  (a: flatarr cells, w: size_t w, v: uint64) : void

(* Cell access: cell index bounded by the CELL count. The result is
 * a bit by construction -- this is the kernel's bit() with its
 * index arithmetic (i div 64, i mod 64) discharged by the type. *)
fun cell_get {cells:pos}{i:nat | i < cells}
  (a: flatarr cells, i: size_t i) : [b:int | b == 0 || b == 1] int b

(* Cell write: value restricted to a bit, index to the cell count.
 * This is the kernel's write_bit(); its OR-into-word behaviour is
 * specified in bitpack.dats (a set is only sound on a zeroed word,
 * which is why the kernel fills dst with 0 before stepping). *)
fun cell_set {cells:pos}{i:nat | i < cells}{b:int | b == 0 || b == 1}
  (a: flatarr cells, i: size_t i, b: int b) : void

(* Zero a whole buffer -- the fill the kernel performs on dst[..n]
 * before every step, and the reason cell_set's OR is exact. *)
fun flatarr_zero {cells:nat} (a: flatarr cells) : void

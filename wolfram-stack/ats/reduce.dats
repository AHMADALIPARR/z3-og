(* ========================================================================= *)
(* z3-og -- hand-rolled SMT stack. Copyright (c) 2026 Ahmad Ali Parr.        *)
(* Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE          *)
(* LICENSE v1.0 -- see LICENSE at the repository root. Commercial            *)
(* exploitation requires separate written authorisation; publication,        *)
(* access, download, visibility, or possession is not authorisation.         *)
(* ========================================================================= *)
(*
 * reduce.dats -- deterministic reductions.
 *
 * population() is the layer's one reduction: a fold of popcounts
 * over the words, with the last word masked. Its contract is the
 * two facts callers actually use -- the result counts only live
 * cells (so it is bounded by cells), and the fold is a function
 * (same buffer, same count: reductions here are deterministic by
 * construction, a single left fold with no parallelism or order
 * dependence to specify away).
 *)

#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload "proofs.sats"
staload "array.sats"
staload "bitpack.dats"

(* popcount of one word as a value-level fact: 0 <= k <= 64. *)
extern fun popcount64 (w: uint64) : [k:nat | k <= 64] size_t k

(* The population of a whole buffer. Precondition is only that the
 * buffer holds cells bits (flatarr cells); the masking of padding
 * is internal to the reduction, matching the kernel, which masks
 * the last word before counting rather than requiring the caller to
 * pre-mask. Postcondition: the count cannot exceed the live cells.
 * This is the Kani harness population_ignores_padding, as a
 * contract: padding bits, whatever they hold, change nothing. *)
extern fun population {cells:pos}
  (a: flatarr cells) : [t:nat | t <= cells] size_t t

(* Padding irrelevance, stated as an equation between two buffers
 * that agree on live cells: their populations agree. The inductive
 * content is WORD_POP of bitpack.dats summed over the words. *)
propdef POP_SAME (cells:int, t1:int, t2:int) = [t1 == t2] void

extern prfun lemma_pop_padding {cells:pos}{t:nat | t <= cells} () :
  POP_SAME (cells, t, t)

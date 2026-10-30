(* ========================================================================= *)
(* z3-og -- hand-rolled SMT stack. Copyright (c) 2026 Ahmad Ali Parr.        *)
(* Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE          *)
(* LICENSE v1.0 -- see LICENSE at the repository root. Commercial            *)
(* exploitation requires separate written authorisation; publication,        *)
(* access, download, visibility, or possession is not authorisation.         *)
(* ========================================================================= *)
(*
 * bitpack.dats -- packed word operations.
 *
 * The state is bits packed into u64 words. This file specifies the
 * three operations the kernel builds everything from -- read a bit,
 * OR a bit into a zeroed word, mask the padding of the last word --
 * as value-level facts, independent of which transition uses them.
 *)

#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload "proofs.sats"
staload "array.sats"

(* ------------------------------------------------------------------ *)
(* Word-level bit read: (w >> i) & 1, a bit by construction.           *)
(* ------------------------------------------------------------------ *)

fun word_bit {i:nat | i < 64}
  (w: uint64, i: size_t i) : [b:int | b == 0 || b == 1] int b

(* Word-level bit set on a ZERO word: the result is exactly 2^i when
 * the bit is 1 and exactly 0 when it is 0. The zero precondition is
 * the contract form of the kernel's dst[..n].fill(0) before a step:
 * without it, OR-accumulation is a merge, not a write. *)
propdef SET_EXACT (i:int, b:int, v:int) =
  (b == 1 && v == pow2 (i) || b == 0 && v == 0)

fun word_set_zero {i:nat | i < 64}{b:int | b == 0 || b == 1}
  (i: size_t i, b: int b) : [v:int | v >= 0] (SET_EXACT (i, b, v) | uint64)

(* ------------------------------------------------------------------ *)
(* The last-word mask: (1 << (cells mod 64)) - 1, or all-ones when     *)
(* cells is a whole number of words. population() applies it before   *)
(* counting; elementary() guarantees its output already satisfies it. *)
(* ------------------------------------------------------------------ *)

fun last_mask {cells:pos} () :
  [m:int | m >= 0] (LAST_OK (cells, m) || cells % 64 == 0 | uint64)

(* Postcondition of a completed elementary step, stated once here and
 * required by automata.dats: every padding bit of the destination's
 * last word is zero. This is the Kani harness
 * elementary_output_is_masked, as a contract. *)
propdef DST_MASKED (cells:int, last:int) = LAST_OK (cells, last)

(* Population bound at the word level: a masked word contributes at
 * most (cells mod 64) ones, a whole word at most 64. reduce.dats
 * sums these into the population <= cells bound. *)
propdef WORD_POP (cells:int, v:int, k:int) =
  (0 <= k, cells % 64 == 0 && k <= 64 || cells % 64 != 0 && k <= cells % 64)

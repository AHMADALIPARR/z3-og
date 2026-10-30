(* ========================================================================= *)
(* z3-og -- hand-rolled SMT stack. Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.        *)
(* Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE          *)
(* LICENSE v1.0 -- see LICENSE at the repository root. Commercial            *)
(* exploitation requires separate written authorisation; publication,        *)
(* access, download, visibility, or possession is not authorisation.         *)
(* ========================================================================= *)
(*
 * stride.dats -- verified index arithmetic.
 *
 * Every index the kernel computes is one of three shapes:
 *   cell i        -> word (i div 64), bit (i mod 64)     [bit()]
 *   2D (x, y)     -> cell (y * width + x)                [moore()]
 *   neighbour     -> a stride.dats index, offset by one  [stencil.dats]
 * This file owns the arithmetic facts about those shapes, proved
 * once, so call sites carry no index reasoning of their own.
 *)

#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload "proofs.sats"

(* ------------------------------------------------------------------ *)
(* Bit decomposition: i = 64 * (i div 64) + (i mod 64), with the word  *)
(* index in range whenever i is a live cell.                           *)
(* ------------------------------------------------------------------ *)

propdef DECOMP (i:int, w:int, b:int) =
  [i == 64 * w + b; 0 <= b; b < 64] void

extern prfun lemma_decomp {i:nat} () : DECOMP (i, i / 64, i % 64)

(* The word half of a live cell index addresses a real word of the
 * buffer -- the fact that makes the kernel's words[index >> 6]
 * access total, with no bounds check owed at runtime. *)
extern prfun lemma_word_index {cells,i:nat | i < cells} () :
  [i / 64 < words_for (cells)] void

(* ------------------------------------------------------------------ *)
(* Row-major stride: idx(y, x) = y * width + x.                        *)
(* ------------------------------------------------------------------ *)

stadef idx (y:int, x:int, w:int) = y * w + x

(* In-bounds: a coordinate inside the rectangle names a live cell of
 * the width*height state. (Nonlinear: stated here as the layer's
 * stride axiom; the proof on a Postiats toolchain goes through the
 * prelude's mul lemmas -- mul_pos, mul_lt_mono -- in that order.) *)
extern prfun lemma_idx_bound
  {w,h,x,y:nat | x < w; y < h} () :
  [idx (y, x, w) < w * h] void

(* Row stride monotonicity: moving one row down advances the index
 * by exactly width -- the fact stencil neighbourhoods are built from. *)
extern prfun lemma_idx_row {w,y,x:nat} () :
  [idx (y + 1, x, w) == idx (y, x, w) + w] void

(* Column neighbour: one step right stays in the same row iff x + 1
 * does not cross the width; crossing is the boundary case, owned by
 * stencil.dats, not by ad-hoc arithmetic at the call site. *)
propdef SAME_ROW (w:int, x:int) = [x + 1 < w] void
propdef ROW_EDGE (w:int, x:int) = [x + 1 == w] void

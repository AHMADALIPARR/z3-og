(* ========================================================================= *)
(* z3-og -- hand-rolled SMT stack. Copyright (c) 2026 Ahmad Ali Parr.        *)
(* Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE          *)
(* LICENSE v1.0 -- see LICENSE at the repository root. Commercial            *)
(* exploitation requires separate written authorisation; publication,        *)
(* access, download, visibility, or possession is not authorisation.         *)
(* ========================================================================= *)
(*
 * stencil.dats -- neighbourhood bounds.
 *
 * A stencil step reads a fixed neighbourhood around each cell and
 * nothing else. This file defines the two neighbourhoods of the
 * kernel -- the elementary triple (left, centre, right) and the
 * Moore 8-neighbourhood -- as inductive propositions mirroring the
 * kernel's boundary match arms exactly. Boundary behaviour (Zero:
 * the neighbour is the constant 0; Wrap: the index folds to the
 * opposite edge) lives here as constructors, so a step function's
 * proof obligation is: every read is one of these cases.
 *)

#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload "proofs.sats"
staload "stride.dats"

(* ------------------------------------------------------------------ *)
(* A neighbour VALUE: either a live cell's bit, or the Zero           *)
(* boundary's constant. (Wrap never produces this case: it folds to   *)
(* a live cell instead -- see the NBR3 / NBR8 wrap constructors.)     *)
(* ------------------------------------------------------------------ *)

dataprop NBR (cells:int, v:int) =
  | {i:nat | i < cells}{b:int | b == 0 || b == 1}
    NBR_cell (cells, b) of ()
  | NBR_zero (cells, 0) of ()

(* ------------------------------------------------------------------ *)
(* The elementary triple for cell i of a cells-wide state.            *)
(* ------------------------------------------------------------------ *)

dataprop NBR3 (cells:int, i:int, l:int, c:int, r:int) =
  (* interior: all three are live cells *)
  | {cells,i:nat | 0 < i; i + 1 < cells}
    {lb,cb,rb:int | lb == 0 || lb == 1; cb == 0 || cb == 1; rb == 0 || rb == 1}
    NBR3_mid (cells, i, lb, cb, rb) of ()
  (* left edge, Zero: left neighbour is the constant 0 *)
  | {cells:nat | cells > 1}{cb,rb:int | cb == 0 || cb == 1; rb == 0 || rb == 1}
    NBR3_left_zero (cells, 0, 0, cb, rb) of ()
  (* left edge, Wrap: left neighbour is cell cells-1 *)
  | {cells:nat | cells > 1}{lb,cb,rb:int | lb == 0 || lb == 1; cb == 0 || cb == 1; rb == 0 || rb == 1}
    NBR3_left_wrap (cells, 0, lb, cb, rb) of ()
  (* right edge, Zero *)
  | {cells:nat | cells > 1}{lb,cb:int | lb == 0 || lb == 1; cb == 0 || cb == 1}
    NBR3_right_zero (cells, cells - 1, lb, cb, 0) of ()
  (* right edge, Wrap: right neighbour is cell 0 *)
  | {cells:nat | cells > 1}{lb,cb,rb:int | lb == 0 || lb == 1; cb == 0 || cb == 1; rb == 0 || rb == 1}
    NBR3_right_wrap (cells, cells - 1, lb, cb, rb) of ()

(* The neighbourhood code the rule table is indexed by: (l<<2)|(c<<1)|r,
 * an index into the rule byte, hence in 0..7 by construction. *)
propdef NCODE (l:int, c:int, r:int, n:int) =
  (n == 4 * l + 2 * c + r, 0 <= n, n <= 7)

prfun lemma_ncode_range {l,c,r:int | l == 0 || l == 1; c == 0 || c == 1; r == 0 || r == 1} () :
  NCODE (l, c, r, 4 * l + 2 * c + r)

(* ------------------------------------------------------------------ *)
(* The Moore neighbourhood: eight NBR values around (x, y) in a       *)
(* width x height state. The count of live neighbours is a sum of    *)
(* eight bits, hence in 0..8 -- which is why the kernel's birth and  *)
(* survive masks are 9 bits wide, and why indexing them by the count *)
(* can never leave the mask.                                          *)
(* ------------------------------------------------------------------ *)

dataprop NBR8 (cells:int, n:int) =
  | {b1,b2,b3,b4,b5,b6,b7,b8:int
    | b1 == 0 || b1 == 1; b2 == 0 || b2 == 1; b3 == 0 || b3 == 1
    ; b4 == 0 || b4 == 1; b5 == 0 || b5 == 1; b6 == 0 || b6 == 1
    ; b7 == 0 || b7 == 1; b8 == 0 || b8 == 1}
    NBR8_make (cells, b1 + b2 + b3 + b4 + b5 + b6 + b7 + b8) of ()

prfun lemma_nbr8_range {cells,n:nat} (pf: NBR8 (cells, n)) : [n <= 8] void

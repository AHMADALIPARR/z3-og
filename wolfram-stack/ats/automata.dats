(* ========================================================================= *)
(* z3-og -- hand-rolled SMT stack. Copyright (c) 2026 Ahmad Ali Parr.        *)
(* Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE          *)
(* LICENSE v1.0 -- see LICENSE at the repository root. Commercial            *)
(* exploitation requires separate written authorisation; publication,        *)
(* access, download, visibility, or possession is not authorisation.         *)
(* ========================================================================= *)
(*
 * automata.dats -- cellular state transitions, as contracts.
 *
 * The two kernel transitions with their full obligation sets:
 * what the caller must establish before the call (non-empty shape,
 * buffers long enough, src/dst a disjoint pair) and what the kernel
 * guarantees after it (destination masked, every output bit the
 * rule applied to a lawful neighbourhood). The transition bodies
 * stay in Rust; this file is the shape they must fit.
 *)

#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload "proofs.sats"
staload "array.sats"
staload "arena.dats"
staload "stencil.dats"
staload "bitpack.dats"

datatype boundary = Zero | Wrap

(* The output-bit law of one cell of the elementary transition:
 * the bit written is bit n of the rule, where n is the NBR3 code of
 * the neighbourhood the bit was read from. *)
propdef CELL_LAW (rule:int, l:int, c:int, r:int, out:int) =
  ( IS_BIT (out)
  , out == (rule / pow2 (4 * l + 2 * c + r)) % 2 )

(* The whole-step law -- every cell of dst satisfies CELL_LAW for
 * the neighbourhood it was read from -- is an abstract proposition:
 * its only introduction rule is a completed, lawful step, which is
 * what the implementations in bridge.dats must produce. *)
stacst ELEM_LAW : (int, int) -> prop

(* elementary(): one simultaneous step of Wolfram rule 0..255.
 *
 * Mirrors the Rust signature
 *   elementary(src, dst, cells, rule: u8, boundary) -> Result<(), Error>
 * with the Result's Err cases discharged by the arguments:
 *   Empty              -- impossible: cells:pos
 *   BufferTooSmall     -- impossible: flatarr cells IS words_for(cells) words
 *   OverlappingBuffers -- impossible: the arena_pair token
 *   ShapeOverflow      -- impossible: words_for bounds are static
 * What remains is ERR_OK, returned as the value, with the masking
 * postcondition as proof. *)
fun elementary_step {l1,l2:addr}{cells:pos}{rule:int | 0 <= rule; rule <= 255}
  ( p: !arena_pair (l1, l2, cells)
  , cells: size_t cells
  , rule: int rule
  , bnd: boundary
  ) : (ELEM_LAW (cells, rule) | int ERR_OK)

(* moore(): one simultaneous Life-like step.
 *   birth, survive: 9-bit masks indexed by neighbour count 0..8
 *   (the count bound is lemma_nbr8_range; a mask index outside
 *   0..8 is unrepresentable in the proof, not merely unchecked).
 * Shape: cells = width * height is a static identity here, so the
 * kernel's checked_mul / ShapeOverflow case is discharged by the
 * type of the state (flatarr (width * height)). *)
fun moore_step {l1,l2:addr}{w,h:pos}
  ( p: !arena_pair (l1, l2, w * h)
  , width: size_t w, height: size_t h
  , birth: uint16, survive: uint16
  , bnd: boundary
  ) : int ERR_OK

(* Multi-step runs are iterated single steps with the pair token
 * re-presented each generation (src and dst swap roles, which the
 * token permits: it is symmetric, arena.dats disjoint_sym). No
 * separate contract is needed -- and none is offered, so a caller
 * cannot batch steps past the per-step postconditions. *)

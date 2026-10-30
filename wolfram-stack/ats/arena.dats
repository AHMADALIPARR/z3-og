(* ========================================================================= *)
(* z3-og -- hand-rolled SMT stack. Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.        *)
(* Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE          *)
(* LICENSE v1.0 -- see LICENSE at the repository root. Commercial            *)
(* exploitation requires separate written authorisation; publication,        *)
(* access, download, visibility, or possession is not authorisation.         *)
(* ========================================================================= *)
(*
 * arena.dats -- linear ownership of memory arenas.
 *
 * The kernel owns nothing: every buffer is caller-owned and passed
 * in. This file makes that discipline a linear type discipline.
 * An arena token is a VIEW -- it must be consumed exactly once --
 * so a buffer cannot be freed twice, lent twice, or silently
 * aliased as both src and dst of a step. The kernel's runtime
 * OverlappingBuffers check becomes, at this layer, an ownership
 * fact established when the arena is split.
 *)

#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload "proofs.sats"
staload "array.sats"

(* ------------------------------------------------------------------ *)
(* The arena view: ownership of words_for(cells) words at address l.   *)
(* ------------------------------------------------------------------ *)

absviewtype arena (l:addr, cells:int)

viewdef arena_v (l:addr, cells:int) = arena (l, cells)

(* Acquire an arena over caller storage. The caller gives up the raw
 * storage view and gets the linear token; release is the only way
 * back. Implemented against the C ABI in bridge.dats. *)
extern fun arena_acquire {l:addr}{cells:pos}
  (base: ptr(l), cells: size_t cells) : arena (l, cells)

extern fun arena_release {l:addr}{cells:pos}
  (a: arena (l, cells)) : void

(* Borrow the contract array out of an arena for the duration of a
 * call. The arena token is consumed and returned -- linear lend,
 * not a copy -- so two live borrows of the same arena cannot exist. *)
extern fun arena_borrow {l:addr}{cells:pos}
  (a: arena (l, cells)) : (arena (l, cells) | flatarr cells)

(* ------------------------------------------------------------------ *)
(* The disjoint pair: what a step actually needs.                      *)
(*                                                                     *)
(* Splitting one arena into two, or pairing two arenas whose byte    *)
(* ranges are known apart, yields a PAIR token. automata.dats        *)
(* requires this token for elementary/moore steps -- which is the    *)
(* static form of the kernel's validate() overlap test:              *)
(*   a < b + bytes && b < a + bytes  ==>  OverlappingBuffers         *)
(* cannot arise for buffers that arrived as a disjoint pair.         *)
(* ------------------------------------------------------------------ *)

absviewtype arena_pair (l1:addr, l2:addr, cells:int)

extern fun arena_pair_separate
  {l1,l2:addr}{cells:pos}
  ( pf: DISJOINT (l1, l2, words_for (cells))
  | a: arena (l1, cells), b: arena (l2, cells)) : arena_pair (l1, l2, cells)

extern fun arena_pair_unpair
  {l1,l2:addr}{cells:pos}
  (p: arena_pair (l1, l2, cells)) : (arena (l1, cells), arena (l2, cells))

extern fun arena_pair_src
  {l1,l2:addr}{cells:pos}
  (p: !arena_pair (l1, l2, cells)) : flatarr cells

extern fun arena_pair_dst
  {l1,l2:addr}{cells:pos}
  (p: !arena_pair (l1, l2, cells)) : flatarr cells

(* Symmetry of separation is free: order is a symmetric fact once
 * the byte ranges are fixed, so the swapped pair needs no new
 * runtime evidence. *)
prfun disjoint_sym {l1,l2:addr}{w:nat}
  .<1>.
  (pf: DISJOINT (l1, l2, w)) : DISJOINT (l2, l1, w) =
  case+ pf of
  | DISJ_lt () => DISJ_gt ()
  | DISJ_gt () => DISJ_lt ()

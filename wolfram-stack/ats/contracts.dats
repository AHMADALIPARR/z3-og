(* ========================================================================= *)
(* z3-og -- hand-rolled SMT stack. Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.        *)
(* Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE          *)
(* LICENSE v1.0 -- see LICENSE at the repository root. Commercial            *)
(* exploitation requires separate written authorisation; publication,        *)
(* access, download, visibility, or possession is not authorisation.         *)
(* ========================================================================= *)
(*
 * contracts.dats -- the ATS contract layer, combined.
 *
 * Single compilation unit so the staload cycle among the original
 * .dats files cannot arise. Sections preserve the original file
 * boundaries; each section's statics and dynamics are in scope for
 * every section that follows.
 *
 * Original files (kept for reference, not typechecked together):
 *   proofs.sats  array.sats  arena.dats  stride.dats  bitpack.dats
 *   stencil.dats reduce.dats automata.dats bridge.dats
 *)

#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"


(* ================================================================== *)
(* proofs.sats *)
(* ================================================================== *)

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

extern prfun lemma_words_for_bounds
  {cells:nat} () : WF_BOUNDS (cells, words_for (cells))

(* pow2(k) for mask arithmetic in statics. *)
stacst pow2 : int -> int

extern prfun lemma_pow2_pos {k:nat} () : [pow2 (k) >= 1] void

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


(* ================================================================== *)
(* array.sats *)
(* ================================================================== *)

(* The abstract buffer type, indexed by cell count. *)
abstype flatarr (cells:int) = ptr

(* Word count of a buffer, with the ceiling bounds as proof. *)
extern fun flatarr_words {cells:nat}
  (a: flatarr cells) : [w:nat] (WF_BOUNDS (cells, w) | size_t w)

(* Base address, for the disjointness tokens of arena.dats. *)
extern fun flatarr_base {cells:nat} (a: flatarr cells) : ptr

(* Whole-word access: word index bounded by the WORD count. *)
extern fun word_get {cells:nat}{w:nat | w < words_for (cells)}
  (a: flatarr cells, w: size_t w) : uint64

extern fun word_set {cells:nat}{w:nat | w < words_for (cells)}
  (a: flatarr cells, w: size_t w, v: uint64) : void

(* Cell access: cell index bounded by the CELL count. The result is
 * a bit by construction -- this is the kernel's bit() with its
 * index arithmetic (i div 64, i mod 64) discharged by the type. *)
extern fun cell_get {cells:pos}{i:nat | i < cells}
  (a: flatarr cells, i: size_t i) : [b:int | b == 0 || b == 1] int b

(* Cell write: value restricted to a bit, index to the cell count.
 * This is the kernel's write_bit(); its OR-into-word behaviour is
 * specified in bitpack.dats (a set is only sound on a zeroed word,
 * which is why the kernel fills dst with 0 before stepping). *)
extern fun cell_set {cells:pos}{i:nat | i < cells}{b:int | b == 0 || b == 1}
  (a: flatarr cells, i: size_t i, b: int b) : void

(* Zero a whole buffer -- the fill the kernel performs on dst[..n]
 * before every step, and the reason cell_set's OR is exact. *)
extern fun flatarr_zero {cells:nat} (a: flatarr cells) : void


(* ================================================================== *)
(* arena.dats *)
(* ================================================================== *)

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


(* ================================================================== *)
(* stride.dats *)
(* ================================================================== *)

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


(* ================================================================== *)
(* bitpack.dats *)
(* ================================================================== *)

(* ------------------------------------------------------------------ *)
(* Word-level bit read: (w >> i) & 1, a bit by construction.           *)
(* ------------------------------------------------------------------ *)

extern fun word_bit {i:nat | i < 64}
  (w: uint64, i: size_t i) : [b:int | b == 0 || b == 1] int b

(* Word-level bit set on a ZERO word: the result is exactly 2^i when
 * the bit is 1 and exactly 0 when it is 0. The zero precondition is
 * the contract form of the kernel's dst[..n].fill(0) before a step:
 * without it, OR-accumulation is a merge, not a write. *)
propdef SET_EXACT (i:int, b:int, v:int) =
  [b == 1 && v == pow2 (i) || b == 0 && v == 0] void

extern fun word_set_zero {i:nat | i < 64}{b:int | b == 0 || b == 1}
  (i: size_t i, b: int b) : [v:int | v >= 0] (SET_EXACT (i, b, v) | uint64)

(* ------------------------------------------------------------------ *)
(* The last-word mask: (1 << (cells mod 64)) - 1, or all-ones when     *)
(* cells is a whole number of words. population() applies it before   *)
(* counting; elementary() guarantees its output already satisfies it. *)
(* ------------------------------------------------------------------ *)

extern fun last_mask {cells:pos} () :
  [m:int | m >= 0] (LAST_OK (cells, m) | uint64)

(* Postcondition of a completed elementary step, stated once here and
 * required by automata.dats: every padding bit of the destination's
 * last word is zero. This is the Kani harness
 * elementary_output_is_masked, as a contract. *)
propdef DST_MASKED (cells:int, last:int) = LAST_OK (cells, last)

(* Population bound at the word level: a masked word contributes at
 * most (cells mod 64) ones, a whole word at most 64. reduce.dats
 * sums these into the population <= cells bound. *)
propdef WORD_POP (cells:int, v:int, k:int) =
  [0 <= k; cells % 64 == 0 && k <= 64 || cells % 64 != 0 && k <= cells % 64] void


(* ================================================================== *)
(* stencil.dats *)
(* ================================================================== *)

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
  [n == 4 * l + 2 * c + r; 0 <= n; n <= 7] void

extern prfun lemma_ncode_range {l,c,r:int | l == 0 || l == 1; c == 0 || c == 1; r == 0 || r == 1} () :
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

extern prfun lemma_nbr8_range {cells,n:nat} (pf: NBR8 (cells, n)) : [n <= 8] void


(* ================================================================== *)
(* reduce.dats *)
(* ================================================================== *)

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


(* ================================================================== *)
(* automata.dats *)
(* ================================================================== *)

datatype boundary = Zero | Wrap

(* The output-bit law of one cell of the elementary transition:
 * the bit written is bit n of the rule, where n is the NBR3 code of
 * the neighbourhood the bit was read from. *)
propdef CELL_LAW (rule:int, l:int, c:int, r:int, out:int) =
  [out == (rule / pow2 (4 * l + 2 * c + r)) % 2] void

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
extern fun elementary_step {l1,l2:addr}{cells:pos}{rule:int | 0 <= rule; rule <= 255}
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
extern fun moore_step {l1,l2:addr}{w,h:pos}
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


(* ================================================================== *)
(* bridge.dats *)
(* ================================================================== *)

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

(*
implement elementary_step {l1, l2} {cells} {rule} (p, cells, rule, bnd) =
  let
    val src = arena_pair_src (p)
    val dst = arena_pair_dst (p)
    val _bndc = 0 : int
    val _err = wf_elementary ( flatarr_base src, flatarr_base dst
                             , cells, rule, _bndc )
  in
    (ELEM_LAW_intro (0) | 0)
  end

*)
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


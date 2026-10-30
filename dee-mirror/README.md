# Dee Mirror Maze — MixColumns as a braided loom, in two fields

The AES MixColumns transform read as a physical weave: each state column
travels through fixed Galois strands — a 02 strand (xtime), a 03 strand
(xtime ⊕ self), two 01 pass strands — and the inverse transform is the
mirror traversal back through the loom. This directory holds the design
in every form it exists in the stack: the production C code (in
`crypto/`), the terminal front ends, the Goldilocks backend, the team
page, and the formal-verification attempt — each with its verification
status stated plainly.

## Contents

| Path | What it is | Status |
|---|---|---|
| `../crypto/og_mixcolumns.c` | GF(2^8) MixColumns + mirror inverse + braided mix tables, C11 | **Verified by execution** (below) |
| `team.html` | Working team area: live GF(2^8) weave/mirror + Goldilocks F_p panel with true matrix inverse | **Verified by execution** (JS core extracted and asserted under node) |
| `viz/mirror_maze.rs` | ANSI terminal visualizer for the GF(2^8) weave (owner-supplied) | Filed verbatim; **does not compile as supplied** — rows 2–3 of the maze render are short format specifiers (see Corrections). A scratch repair with only those specifiers added runs and prints the correct FIPS-197 frame |
| `backend/GoldilocksDeeLoom.fs` | The same matrix over the Goldilocks field F_p, F# (owner-supplied) | Filed verbatim; **not compiled** (no .NET SDK on this machine) and has defects on static reading (see Corrections) |
| `proofs/GoldilocksLoom.lean` | Lean 4 / Mathlib invertibility formalization (owner-supplied) | Filed verbatim; **not checked** (no Mathlib on this machine) and its determinant value is **wrong** (see Corrections) |

## The two fields

**GF(2^8)** (AES): bytes, polynomial arithmetic mod x^8+x^4+x^3+x+1.
Forward weave `[02 03 01 01]`, mirror weave `[0E 0B 0D 09]`.
Reference vector (FIPS-197): column `DB 13 53 45` weaves to
`8E 4D A1 BC` and mirrors back exactly.

**Goldilocks F_p**, p = 2^64 − 2^32 + 1: the same integer matrix with
XOR tangles replaced by additions mod p and taps 01/02/03 read as
×1/×2/×3. The matrix is invertible over F_p because its determinant
is nonzero there:

    det M = −35        (exact integer determinant; −35 ≢ 0 mod p)

so M⁻¹ = adj(M) · (−35)⁻¹ over F_p exists and is what `team.html`
computes (cofactor adjugate × modular inverse of the determinant,
cross-checked against exact integer arithmetic, 2,000 random
roundtrips). Note the mirror here is the algebraic inverse — simply
reversing the element order, as the F# sketch's `reflectMirrorAxis`
does, is a display reflection, not an inverse.

## Verification (C core)

`crypto/test_mixcolumns.c`, run by `make test` in `crypto/`:

- FIPS-197 column forward + mirror back — pass
- mix table vs the defining `og_gf_mul`: all 6 coefficient tables ×
  256 entries — pass
- field laws: ×1 identity and ×2 = xtime for all 256 bytes;
  commutativity for all 65,536 pairs — pass
- mirror roundtrips: 4-position × 256-value sweeps both directions,
  10,000 random columns, 1,000 full states — pass

## Corrections to the supplied material (offered, not silently made)

The supplied files above are filed **verbatim** apart from the Sovereign license header prepended 2026-10-30 at the owner's order (bodies untouched); the fixes live here
and in the working code, not inside the owner's files.

1. **Determinant.** The Lean file states `det = 20`. The exact
   determinant of M is **−35** (Bareiss algorithm; also the circulant
   eigenvalue product 7 · (1+2i)(1−2i) · (−1)). The invertibility
   *conclusion* survives — −35 ≢ 0 (mod p) — but the theorem as
   stated is false and its `decide` could never close it. Corrected
   statement: `det mixColumnsMatrix = (-35 : GoldilocksField)`.
2. **Rust visualizer sample frame.** The rendered sample circulated
   with the sketch shows b2 = D0, b3 = 2C and the intermediate
   02·DB = B1. Running the (scratch-repaired) program prints the true
   values: b2 = A1, b3 = BC, 02·DB = AD. The sketch's *math* was
   always right; its hand-written sample frame wasn't.
3. **Rust visualizer format strings.** Rows 2–3 of the maze render
   pass 10 arguments to 7–8 format specifiers; rustc rejects the file
   (`argument never used`, `str: UpperHex`). Adding the missing `{}`
   slots in the mirror half makes it compile warning-free (one unused
   `std::fmt` import aside) with output unchanged in layout.
4. **F# backend, static reading.** `addG` contains a line binding
   `System.Double.Equals(0.0, 0.0)` into an unused tuple — debris that
   does not belong in field arithmetic; its wrap path can also
   double-subtract p. `mulG` treats `Math.BigMul`'s return as a
   single integer splittable by shifts — in .NET it returns a
   (High, Low) tuple / 128-bit value, so the code as written does not
   typecheck. Its one-step reduction also omits the second fold the
   Goldilocks reduction needs for the high word. None of this was
   compiled here; the working F_p arithmetic of record is the exact
   BigInt core in `team.html`, and a C11 Goldilocks core can be
   braided beside `og_mixcolumns.c` on request.

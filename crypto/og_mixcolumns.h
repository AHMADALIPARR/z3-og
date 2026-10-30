/*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 */
/*
 * og_mixcolumns.h -- AES MixColumns as a braided weave over GF(2^8).
 *
 * The forward transform walks each state column through the fixed
 * coefficient weave [02 03 01 01] over GF(2^8) modulo the AES prime
 * polynomial x^8 + x^4 + x^3 + x + 1 (0x11B). The inverse transform
 * is the mirror traversal: the coefficient weave [0E 0B 0D 09] that
 * undoes the forward paths. Forward and inverse are exact mirrors --
 * inv_mix(mix(a)) == a for every column, proved exhaustively by the
 * tests in test_mixcolumns.c.
 *
 * The "mix table" is the set of per-coefficient multiplication
 * tables for {02, 03, 09, 0B, 0D, 0E}; og_mix_tables_init() braids
 * them from og_gf_mul, and the tests prove every entry against the
 * defining multiplication, so the table can never drift from the
 * field arithmetic it tabulates.
 */
#ifndef OG_MIXCOLUMNS_H
#define OG_MIXCOLUMNS_H

#include <stdint.h>

/* Multiply by x (02) in GF(2^8) mod 0x11B: shift left, reduce. */
uint8_t og_gf_xtime(uint8_t a);

/* General multiplication in GF(2^8) mod 0x11B (shift-and-XOR). */
uint8_t og_gf_mul(uint8_t a, uint8_t b);

/* Coefficient slots in the mix table. */
enum {
    OG_MUL_02 = 0,
    OG_MUL_03 = 1,
    OG_MUL_09 = 2,
    OG_MUL_0B = 3,
    OG_MUL_0D = 4,
    OG_MUL_0E = 5,
    OG_MUL_SLOTS = 6
};

/* Braid the per-coefficient tables. Idempotent; called on first use
 * by the table accessor as well. */
void og_mix_tables_init(void);

/* The 256-entry multiplication table for a coefficient slot
 * (OG_MUL_02 .. OG_MUL_0E): table[x] == og_gf_mul(coeff, x). */
const uint8_t *og_gf_table(int slot);

/* Forward weave: b = [02 03 01 01] x a over GF(2^8), one column. */
void og_mix_column(uint8_t b[4], const uint8_t a[4]);

/* Mirror traversal: b = [0E 0B 0D 09] x a; undoes og_mix_column. */
void og_inv_mix_column(uint8_t b[4], const uint8_t a[4]);

/* Whole 4x4 state, AES layout (column-major: s[4*c + r]). */
void og_mix_state(uint8_t s[16]);
void og_inv_mix_state(uint8_t s[16]);

#endif /* OG_MIXCOLUMNS_H */

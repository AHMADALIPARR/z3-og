/*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Ahmad Ali Parr.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 */
#include "og_mixcolumns.h"

uint8_t og_gf_xtime(uint8_t a) {
    return (uint8_t)((a << 1) ^ ((a & 0x80) ? 0x1B : 0x00));
}

uint8_t og_gf_mul(uint8_t a, uint8_t b) {
    uint8_t p = 0;
    for (int i = 0; i < 8; i++) {
        if (b & 1) p ^= a;
        a = og_gf_xtime(a);
        b >>= 1;
    }
    return p;
}

static const uint8_t k_coeff[OG_MUL_SLOTS] = {0x02, 0x03, 0x09, 0x0B, 0x0D, 0x0E};
static uint8_t g_table[OG_MUL_SLOTS][256];
static int g_tables_ready = 0;

void og_mix_tables_init(void) {
    if (g_tables_ready) return;
    for (int s = 0; s < OG_MUL_SLOTS; s++)
        for (int x = 0; x < 256; x++)
            g_table[s][x] = og_gf_mul(k_coeff[s], (uint8_t)x);
    g_tables_ready = 1;
}

const uint8_t *og_gf_table(int slot) {
    og_mix_tables_init();
    return g_table[slot];
}

static uint8_t mul02(uint8_t x) { return og_gf_table(OG_MUL_02)[x]; }
static uint8_t mul03(uint8_t x) { return og_gf_table(OG_MUL_03)[x]; }
static uint8_t mul09(uint8_t x) { return og_gf_table(OG_MUL_09)[x]; }
static uint8_t mul0B(uint8_t x) { return og_gf_table(OG_MUL_0B)[x]; }
static uint8_t mul0D(uint8_t x) { return og_gf_table(OG_MUL_0D)[x]; }
static uint8_t mul0E(uint8_t x) { return og_gf_table(OG_MUL_0E)[x]; }

void og_mix_column(uint8_t b[4], const uint8_t a[4]) {
    /* The weave: each output byte is one path through the loom --
     * a 02 strand, a 03 strand (xtime ^ self), and two 01 pass
     * strands, XOR-combined; the pattern rotates per row. */
    b[0] = (uint8_t)(mul02(a[0]) ^ mul03(a[1]) ^ a[2] ^ a[3]);
    b[1] = (uint8_t)(a[0] ^ mul02(a[1]) ^ mul03(a[2]) ^ a[3]);
    b[2] = (uint8_t)(a[0] ^ a[1] ^ mul02(a[2]) ^ mul03(a[3]));
    b[3] = (uint8_t)(mul03(a[0]) ^ a[1] ^ a[2] ^ mul02(a[3]));
}

void og_inv_mix_column(uint8_t b[4], const uint8_t a[4]) {
    /* The mirror traversal: reflected through the central plane,
     * the forward strands land on the inverse weave [0E 0B 0D 09]. */
    b[0] = (uint8_t)(mul0E(a[0]) ^ mul0B(a[1]) ^ mul0D(a[2]) ^ mul09(a[3]));
    b[1] = (uint8_t)(mul09(a[0]) ^ mul0E(a[1]) ^ mul0B(a[2]) ^ mul0D(a[3]));
    b[2] = (uint8_t)(mul0D(a[0]) ^ mul09(a[1]) ^ mul0E(a[2]) ^ mul0B(a[3]));
    b[3] = (uint8_t)(mul0B(a[0]) ^ mul0D(a[1]) ^ mul09(a[2]) ^ mul0E(a[3]));
}

void og_mix_state(uint8_t s[16]) {
    for (int c = 0; c < 4; c++) {
        uint8_t b[4];
        og_mix_column(b, s + 4 * c);
        for (int r = 0; r < 4; r++) s[4 * c + r] = b[r];
    }
}

void og_inv_mix_state(uint8_t s[16]) {
    for (int c = 0; c < 4; c++) {
        uint8_t b[4];
        og_inv_mix_column(b, s + 4 * c);
        for (int r = 0; r < 4; r++) s[4 * c + r] = b[r];
    }
}

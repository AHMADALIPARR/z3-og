/*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Ahmad Ali Parr.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 */
/*
 * test_mixcolumns.c -- known-answer and exhaustive checks for the
 * MixColumns weave (og_mixcolumns.c). Prints one PASS/FAIL line per
 * check group and exits non-zero on any failure.
 *
 * Coverage:
 *  - FIPS-197 worked example: column (DB 13 53 45) mixes to
 *    (8E 4D A1 BC), and the mirror traversal returns it.
 *  - The mix table: every entry of all six coefficient tables
 *    equals og_gf_mul of the same operands (6 x 256, exhaustive) --
 *    the braid can never drift from the field arithmetic.
 *  - Field laws: x*1 == x and x*2 == xtime(x) for all 256 bytes;
 *    commutativity for all 65,536 byte pairs.
 *  - Mirror roundtrip: inv(mix(a)) == a and mix(inv(a)) == a for
 *    every single-position sweep (4 x 256 columns over a fixed
 *    pseudo-random base) and 10,000 deterministic pseudo-random
 *    columns; the same roundtrip for full 16-byte states.
 */
#include <stdio.h>
#include <string.h>
#include "og_mixcolumns.h"

static int g_failures = 0;

static void report(const char *name, int ok, const char *detail) {
    printf("%s %s%s%s\n", ok ? "PASS" : "FAIL", name,
           detail ? " -- " : "", detail ? detail : "");
    if (!ok) g_failures++;
}

static uint32_t rng_state = 0x12345678u;
static uint8_t rng_byte(void) {
    rng_state = rng_state * 1664525u + 1013904223u;
    return (uint8_t)(rng_state >> 24);
}

int main(void) {
    /* FIPS-197 worked example, forward and mirrored back. */
    {
        const uint8_t in[4] = {0xDB, 0x13, 0x53, 0x45};
        const uint8_t want[4] = {0x8E, 0x4D, 0xA1, 0xBC};
        uint8_t out[4], back[4];
        og_mix_column(out, in);
        og_inv_mix_column(back, out);
        report("fips197_column_forward", memcmp(out, want, 4) == 0, NULL);
        report("fips197_column_mirror_back", memcmp(back, in, 4) == 0, NULL);
    }

    /* The mix table is exactly og_gf_mul, entry for entry. */
    {
        static const uint8_t coeff[OG_MUL_SLOTS] =
            {0x02, 0x03, 0x09, 0x0B, 0x0D, 0x0E};
        int ok = 1;
        for (int s = 0; s < OG_MUL_SLOTS && ok; s++) {
            const uint8_t *t = og_gf_table(s);
            for (int x = 0; x < 256; x++)
                if (t[x] != og_gf_mul(coeff[s], (uint8_t)x)) { ok = 0; break; }
        }
        report("mix_table_matches_gf_mul", ok, "6 tables x 256 entries");
    }

    /* Field laws. */
    {
        int ok = 1;
        for (int x = 0; x < 256 && ok; x++) {
            uint8_t b = (uint8_t)x;
            if (og_gf_mul(b, 0x01) != b) ok = 0;
            if (og_gf_mul(b, 0x02) != og_gf_xtime(b)) ok = 0;
        }
        report("gf_identity_and_xtime", ok, "all 256 bytes");
    }
    {
        int ok = 1;
        for (int a = 0; a < 256 && ok; a++)
            for (int b = 0; b < 256; b++)
                if (og_gf_mul((uint8_t)a, (uint8_t)b) !=
                    og_gf_mul((uint8_t)b, (uint8_t)a)) { ok = 0; break; }
        report("gf_commutative", ok, "all 65,536 pairs");
    }

    /* Mirror roundtrips: position sweeps + pseudo-random columns. */
    {
        int ok = 1;
        const uint8_t base[4] = {0x3A, 0x7E, 0xC1, 0x59};
        for (int p = 0; p < 4 && ok; p++)
            for (int v = 0; v < 256 && ok; v++) {
                uint8_t a[4], m[4], back[4], im[4], fwd[4];
                memcpy(a, base, 4); a[p] = (uint8_t)v;
                og_mix_column(m, a); og_inv_mix_column(back, m);
                og_inv_mix_column(im, a); og_mix_column(fwd, im);
                if (memcmp(back, a, 4) != 0 || memcmp(fwd, a, 4) != 0) ok = 0;
            }
        report("mirror_roundtrip_sweeps", ok, "4 positions x 256 values, both directions");
    }
    {
        int ok = 1;
        for (int i = 0; i < 10000 && ok; i++) {
            uint8_t a[4], m[4], back[4];
            for (int k = 0; k < 4; k++) a[k] = rng_byte();
            og_mix_column(m, a); og_inv_mix_column(back, m);
            if (memcmp(back, a, 4) != 0) ok = 0;
        }
        report("mirror_roundtrip_random", ok, "10,000 columns");
    }
    {
        int ok = 1;
        for (int i = 0; i < 1000 && ok; i++) {
            uint8_t s[16], orig[16];
            for (int k = 0; k < 16; k++) s[k] = rng_byte();
            memcpy(orig, s, 16);
            og_mix_state(s); og_inv_mix_state(s);
            if (memcmp(s, orig, 16) != 0) ok = 0;
        }
        report("state_roundtrip_random", ok, "1,000 full states");
    }

    printf("mixcolumns: %s (%d failure%s)\n",
           g_failures ? "FAILURES" : "ALL PASS",
           g_failures, g_failures == 1 ? "" : "s");
    return g_failures ? 1 : 0;
}

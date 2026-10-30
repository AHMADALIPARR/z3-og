/*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Ahmad Ali Parr.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 */
/* og_rat.h - exact rational arithmetic on int64 with __int128 intermediates.
 * Hand-rolled for z3-og. Normalised: den > 0, gcd(|num|, den) = 1. */
#ifndef OG_RAT_H
#define OG_RAT_H
#include <stdint.h>
#include <stdbool.h>
typedef struct { int64_t num; int64_t den; } rat;
rat  rat_make(int64_t num, int64_t den);
rat  rat_int(int64_t v);
rat  rat_add(rat a, rat b);
rat  rat_sub(rat a, rat b);
rat  rat_mul(rat a, rat b);
rat  rat_neg(rat a);
int  rat_cmp(rat a, rat b);          /* -1, 0, 1 */
bool rat_is_int(rat a);
int64_t rat_floor(rat a);            /* greatest integer <= a */
int64_t rat_ceil(rat a);             /* smallest integer >= a */
#endif

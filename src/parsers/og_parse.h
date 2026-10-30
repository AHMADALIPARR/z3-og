/*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 */
/* og_parse.h - SMT-LIB 2 command interpreter for z3-og (subset, see STATUS.md). */
#ifndef OG_PARSE_H
#define OG_PARSE_H
#include <stdio.h>
void og_run_stream(FILE *in, FILE *out);
#endif

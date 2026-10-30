/*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Ahmad Ali Parr.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 */
/* og_theory.h - theory combination for z3-og: congruence closure (QF_UF)
 * plus exact integer arithmetic (QF_LIA) by Fourier-Motzkin bounded search.
 * Hand-rolled; sound, and complete within the stated node budget
 * (beyond it the result is TH_UNKNOWN, never a wrong SAT/UNSAT). */
#ifndef OG_THEORY_H
#define OG_THEORY_H
#include "../ast/og_ast.h"
#include <stdbool.h>
typedef enum { TH_SAT, TH_UNSAT, TH_UNKNOWN } th_res;
/* Model output, indexed by decl_id. */
typedef struct {
    int64_t *int_val;    /* value for Int constants */
    bool    *int_set;
    term_id *user_rep;   /* representative term for user-sort constants */
} og_model;
void   model_alloc(og_model *m);
void   model_free(og_model *m);
/* atoms/pol: the theory atoms and their assigned truth values. */
th_res theory_check(const term_id *atoms, const bool *pol, int natoms, og_model *out);
#endif

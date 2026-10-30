/*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Ahmad Ali Parr.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 */
/* og_solver.h - DPLL(T) driver in the original Z3 src/solver spirit:
 * Tseitin encoding to the SAT core, theory check on each propositional
 * model, blocking clause on theory conflict. Hand-rolled for z3-og. */
#ifndef OG_SOLVER_H
#define OG_SOLVER_H
#include "../ast/og_ast.h"
#include "../smt/og_theory.h"
#include <stdio.h>
void solver_reset(void);
void solver_assert(term_id t);
void solver_push(void);
void solver_pop(int n);
int  solver_check(void);              /* 1 sat, 0 unsat, -1 unknown */
void solver_print_model(FILE *out);
int  solver_model_bool(decl_id d);    /* 1 true, -1 false, 0 no value */
bool solver_model_int(decl_id d, int64_t *v);
term_id solver_model_user(decl_id d);  /* representative term or -1 */
#endif

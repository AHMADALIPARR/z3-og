/* og_sat.h - a DPLL SAT core in the original Z3 src/sat spirit.
 * Hand-rolled for z3-og: unit propagation + chronological backtracking.
 * Deliberately simple and complete; no clause learning (see STATUS.md). */
#ifndef OG_SAT_H
#define OG_SAT_H
#include <stdbool.h>
typedef struct og_sat og_sat;
og_sat *sat_new(int nvars);
void    sat_set_nvars(og_sat *s, int nvars); /* active var count for solving; storage grows in add_clause */
void    sat_free(og_sat *s);
void    sat_add_clause(og_sat *s, const int *lits, int nlits); /* lit: var index+1, sign = polarity */
bool    sat_solve(og_sat *s);        /* true = SAT; model via sat_value */
int     sat_value(og_sat *s, int var); /* after SAT solve: 1 true, -1 false, 0 unassigned */
int     sat_num_vars(og_sat *s);
#endif

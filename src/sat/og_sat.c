/*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Ahmad Ali Parr.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 */
#include "og_sat.h"
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
struct og_sat {
    int nvars, capvars;
    int *clauses;      /* arena of literals, 0 terminates a clause */
    int *coff;         /* clause offsets into arena */
    int nclauses, capclauses, clen, capclen;
    int8_t *assign;    /* 0 unassigned, 1 true, -1 false */
    int *trail; int ntrail;
};
static void *xmalloc(size_t n){ void *p = malloc(n ? n : 1); if (!p) exit(2); return p; }
static void *xrealloc(void *p, size_t n){ void *q = realloc(p, n ? n : 1); if (!q) exit(2); return q; }
og_sat *sat_new(int nvars){
    og_sat *s = xmalloc(sizeof(og_sat));
    s->nvars = nvars; s->capvars = nvars; s->nclauses = 0; s->capclauses = 0; s->clen = 0; s->capclen = 0;
    s->clauses = NULL; s->coff = NULL;
    s->assign = xmalloc((nvars + 1) * sizeof(int8_t));
    s->trail = xmalloc((nvars + 1) * sizeof(int));
    s->ntrail = 0;
    return s;
}
void sat_free(og_sat *s){ free(s->clauses); free(s->coff); free(s->assign); free(s->trail); free(s); }
int sat_num_vars(og_sat *s){ return s->nvars; }
void sat_set_nvars(og_sat *s, int nvars){ if (nvars > s->nvars) s->nvars = nvars; }
static void sat_grow_vars(og_sat *s, int v){
    if (v <= s->capvars) return;
    int nc = s->capvars ? s->capvars : 16;
    while (nc < v) nc *= 2;
    s->assign = xrealloc(s->assign, (nc + 1) * sizeof(int8_t));
    s->trail = xrealloc(s->trail, (nc + 1) * sizeof(int));
    for (int i = s->capvars + 1; i <= nc; i++) s->assign[i] = 0;
    s->capvars = nc;
}
void sat_add_clause(og_sat *s, const int *lits, int nlits){
    for (int i = 0; i < nlits; i++) { int v = lits[i] < 0 ? -lits[i] : lits[i]; sat_grow_vars(s, v); if (v > s->nvars) s->nvars = v; }
    if (s->nclauses == s->capclauses) { s->capclauses = s->capclauses ? s->capclauses * 2 : 64; s->coff = xrealloc(s->coff, s->capclauses * sizeof(int)); }
    if (s->clen + nlits + 1 > s->capclen) { s->capclen = s->capclen ? s->capclen * 2 : 256; while (s->clen + nlits + 1 > s->capclen) s->capclen *= 2; s->clauses = xrealloc(s->clauses, s->capclen * sizeof(int)); }
    s->coff[s->nclauses++] = s->clen;
    for (int i = 0; i < nlits; i++) s->clauses[s->clen++] = lits[i];
    s->clauses[s->clen++] = 0;
}
static int lit_val(og_sat *s, int lit){
    int v = lit < 0 ? -lit : lit;
    int8_t a = s->assign[v];
    if (a == 0) return 0;
    bool t = (a == 1);
    return (lit > 0) == t ? 1 : -1;
}
/* propagate: returns false on conflict */
static bool propagate(og_sat *s){
    bool changed = true;
    while (changed) {
        changed = false;
        for (int ci = 0; ci < s->nclauses; ci++) {
            int off = s->coff[ci];
            int unassigned = 0, last_un = 0; bool sat = false;
            for (int j = off; s->clauses[j]; j++) {
                int v = lit_val(s, s->clauses[j]);
                if (v == 1) { sat = true; break; }
                if (v == 0) { unassigned++; last_un = s->clauses[j]; }
            }
            if (sat) continue;
            if (unassigned == 0) return false;
            if (unassigned == 1) {
                int var = last_un < 0 ? -last_un : last_un;
                if (s->assign[var] == 0) {
                    s->assign[var] = last_un > 0 ? 1 : -1;
                    s->trail[s->ntrail++] = var;
                    changed = true;
                }
            }
        }
    }
    return true;
}
static bool all_satisfied(og_sat *s){
    for (int ci = 0; ci < s->nclauses; ci++) {
        int off = s->coff[ci]; bool sat = false;
        for (int j = off; s->clauses[j]; j++) if (lit_val(s, s->clauses[j]) == 1) { sat = true; break; }
        if (!sat) return false;
    }
    return true;
}
static bool dpll(og_sat *s){
    int saved = s->ntrail;
    if (!propagate(s)) { while (s->ntrail > saved) s->assign[s->trail[--s->ntrail]] = 0; return false; }
    if (all_satisfied(s)) return true;
    int var = 0;
    for (int v = 1; v <= s->nvars; v++) if (s->assign[v] == 0) { var = v; break; }
    if (!var) return false; /* clauses unsatisfied but everything assigned -> conflict already caught */
    for (int attempt = 0; attempt < 2; attempt++) {
        int mark = s->ntrail;
        s->assign[var] = attempt == 0 ? 1 : -1;
        s->trail[s->ntrail++] = var;
        if (dpll(s)) return true;
        while (s->ntrail > mark) s->assign[s->trail[--s->ntrail]] = 0;
    }
    while (s->ntrail > saved) s->assign[s->trail[--s->ntrail]] = 0;
    return false;
}
bool sat_solve(og_sat *s){
    memset(s->assign, 0, (s->nvars + 1) * sizeof(int8_t));
    s->ntrail = 0;
    return dpll(s);
}
int sat_value(og_sat *s, int var){ return s->assign[var]; }

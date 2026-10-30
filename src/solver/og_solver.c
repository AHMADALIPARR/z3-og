/*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 */
#include "og_solver.h"
#include "../sat/og_sat.h"
#include <stdlib.h>
#include <string.h>
static void *xmalloc(size_t n){ void *p = malloc(n ? n : 1); if (!p) exit(2); return p; }
static void *xrealloc(void *p, size_t n){ void *q = realloc(p, n ? n : 1); if (!q) exit(2); return q; }

static term_id *asserts; static int nasserts, capasserts;
static int *scopes; static int nscopes, capscopes;
void solver_reset(void){ nasserts = 0; nscopes = 0; }
void solver_assert(term_id t){
    if (nasserts == capasserts) { capasserts = capasserts ? capasserts * 2 : 32; asserts = xrealloc(asserts, capasserts * sizeof(term_id)); }
    asserts[nasserts++] = t;
}
void solver_push(void){
    if (nscopes == capscopes) { capscopes = capscopes ? capscopes * 2 : 16; scopes = xrealloc(scopes, capscopes * sizeof(int)); }
    scopes[nscopes++] = nasserts;
}
void solver_pop(int n){
    while (n-- > 0 && nscopes > 0) { nasserts = scopes[--nscopes]; }
}

/* Tseitin state, rebuilt per check */
static og_sat *sat;
static int *term_lit;      /* term_id -> lit (signed sat var), 0 = none */
static int term_lit_cap;
static term_id *atoms; static int natoms, capatoms;
static int next_var;
static int fresh_var(void){ return next_var++; }
static void add_clause(const int *lits, int n){ sat_add_clause(sat, lits, n); }
static void atom_register(term_id t){
    for (int i = 0; i < natoms; i++) if (atoms[i] == t) return;
    if (natoms == capatoms) { capatoms = capatoms ? capatoms * 2 : 32; atoms = xrealloc(atoms, capatoms * sizeof(term_id)); }
    atoms[natoms++] = t;
}
static int encode(term_id t); /* fwd */
static int encode_atom(term_id t){
    if (term_lit[t]) return term_lit[t];
    int v = fresh_var();
    term_lit[t] = v;
    atom_register(t);
    return v;
}
static int encode(term_id t){
    if (term_lit[t]) return term_lit[t];
    const og_term *tm = term_get(t);
    switch (tm->kind) {
        case T_TRUE: { int v = fresh_var(); int c[1] = { v }; add_clause(c, 1); term_lit[t] = v; return v; }
        case T_FALSE: { int v = fresh_var(); int c[1] = { -v }; add_clause(c, 1); term_lit[t] = v; return v; }
        case T_NOT: { int l = encode(tm->a); term_lit[t] = -l; return -l; }
        case T_AND: {
            int la = encode(tm->a), lb = encode(tm->b); int v = fresh_var();
            int c1[2] = { -v, la }, c2[2] = { -v, lb }, c3[3] = { v, -la, -lb };
            add_clause(c1, 2); add_clause(c2, 2); add_clause(c3, 3);
            term_lit[t] = v; return v;
        }
        case T_OR: {
            int la = encode(tm->a), lb = encode(tm->b); int v = fresh_var();
            int c1[2] = { v, -la }, c2[2] = { v, -lb }, c3[3] = { -v, la, lb };
            add_clause(c1, 2); add_clause(c2, 2); add_clause(c3, 3);
            term_lit[t] = v; return v;
        }
        case T_EQ: {
            if (term_get(tm->a)->sort != sort_bool()) return encode_atom(t);
            /* boolean operands: iff */
            int la = encode(tm->a), lb = encode(tm->b); int v = fresh_var();
            int c1[3] = { -v, -la, lb }, c2[3] = { -v, -lb, la }, c3[3] = { -la, -lb, v }, c4[3] = { la, lb, v };
            add_clause(c1, 3); add_clause(c2, 3); add_clause(c3, 3); add_clause(c4, 3);
            term_lit[t] = v; return v;
        }
        case T_ITE: {
            if (tm->sort != sort_bool()) return encode_atom(t);
            int lc = encode(tm->a), la = encode(tm->b), lb = encode(tm->c); int v = fresh_var();
            int c1[3] = { -v, -lc, la }, c2[3] = { -v, lc, lb }, c3[3] = { -lc, -la, v }, c4[3] = { lc, -lb, v };
            add_clause(c1, 3); add_clause(c2, 3); add_clause(c3, 3); add_clause(c4, 3);
            term_lit[t] = v; return v;
        }
        default: return encode_atom(t);
    }
}

static og_model model; static bool model_valid;
static int *bool_assign;   /* per atom index: sat value of its var */
int solver_check(void){
    model_valid = false;
    int tc = term_count();
    if (tc > term_lit_cap) { term_lit_cap = tc + 64; term_lit = xrealloc(term_lit, term_lit_cap * sizeof(int)); }
    for (int i = 0; i < tc; i++) term_lit[i] = 0;
    natoms = 0;
    next_var = 1;
    sat = sat_new(64);
    for (int i = 0; i < tc; i++) term_lit[i] = 0;
    natoms = 0;
    for (int i = 0; i < nasserts; i++) {
        int l = encode(asserts[i]);
        int c[1] = { l }; add_clause(c, 1);
    }
    bool_assign = xmalloc((natoms ? natoms : 1) * sizeof(int));
    for (int iter = 0; iter < 100000; iter++) {
        sat_set_nvars(sat, next_var - 1);
        if (!sat_solve(sat)) { sat_free(sat); return 0; }
        bool *pol = xmalloc((natoms ? natoms : 1) * sizeof(bool));
        term_id *at = xmalloc((natoms ? natoms : 1) * sizeof(term_id));
        int na = 0;
        for (int i = 0; i < natoms; i++) {
            int v = term_lit[atoms[i]];
            if (!v) continue;
            int val = sat_value(sat, v < 0 ? -v : v);
            bool p = (v > 0) == (val >= 0);
            if (val == 0) p = v > 0; /* unassigned atom: pick its natural polarity; theory decides */
            at[na] = atoms[i]; pol[na] = p; bool_assign[i] = p ? 1 : -1; na++;
        }
        og_model m; model_alloc(&m);
        th_res r = theory_check(at, pol, na, &m);
        free(pol); free(at);
        if (r == TH_SAT) {
            model = m; model_valid = true;
            sat_free(sat);
            return 1;
        }
        model_free(&m);
        if (r == TH_UNKNOWN) { sat_free(sat); return -1; }
        /* block this atom assignment */
        int *blk = xmalloc((na ? na : 1) * sizeof(int));
        int nb = 0;
        for (int i = 0; i < natoms; i++) {
            int v = term_lit[atoms[i]];
            if (!v) continue;
            blk[nb++] = bool_assign[i] == 1 ? -v : v;
        }
        sat_add_clause(sat, blk, nb);
        free(blk);
    }
    sat_free(sat);
    return -1;
}
int solver_model_bool(decl_id d){
    if (!model_valid) return 0;
    term_id vt = mk_var(d);
    if (vt >= term_lit_cap || !term_lit[vt]) return 0;
    int v = term_lit[vt];
    (void)v;
    for (int i = 0; i < natoms; i++) if (atoms[i] == vt) return bool_assign[i];
    return 0;
}
bool solver_model_int(decl_id d, int64_t *v){
    if (!model_valid || !model.int_set[d]) return false;
    *v = model.int_val[d]; return true;
}
term_id solver_model_user(decl_id d){
    if (!model_valid) return -1;
    return model.user_rep[d];
}
void solver_print_model(FILE *out){
    if (!model_valid) { fprintf(out, "(error \"no model\")\n"); return; }
    fprintf(out, "(model\n");
    for (int d = 0; d < decl_count(); d++) {
        const og_decl *dc = decl_get(d);
        if (dc->is_fun) continue;
        term_id vt = mk_var(d);
        fprintf(out, "  (define-fun %s () ", dc->name);
        if (dc->result == sort_bool()) {
            int b = solver_model_bool(d);
            fprintf(out, "Bool %s)\n", b < 0 ? "false" : "true");
        } else if (dc->result == sort_int()) {
            int64_t v = 0; solver_model_int(d, &v);
            if (v < 0) fprintf(out, "Int (- %lld))\n", (long long)(-v));
            else fprintf(out, "Int %lld)\n", (long long)v);
        } else {
            fprintf(out, "%s ", sort_name(dc->result));
            term_id rep = model.user_rep[d];
            if (rep >= 0) term_print(out, rep); else term_print(out, vt);
            fprintf(out, ")\n");
        }
    }
    fprintf(out, ")\n");
}

#include "og_theory.h"
#include "../util/og_rat.h"
#include <stdlib.h>
#include <string.h>

static void *xmalloc(size_t n){ void *p = malloc(n ? n : 1); if (!p) exit(2); return p; }
static void *xcalloc(size_t n, size_t s){ void *p = calloc(n ? n : 1, s ? s : 1); if (!p) exit(2); return p; }
static void *xrealloc(void *p, size_t n){ void *q = realloc(p, n ? n : 1); if (!q) exit(2); return q; }

void model_alloc(og_model *m){
    int n = decl_count();
    m->int_val = xcalloc(n, sizeof(int64_t));
    m->int_set = xcalloc(n, sizeof(bool));
    m->user_rep = xmalloc((n ? n : 1) * sizeof(term_id));
    for (int i = 0; i < n; i++) m->user_rep[i] = -1;
}
void model_free(og_model *m){ free(m->int_val); free(m->int_set); free(m->user_rep); }

/* ---------------- subterm collection ---------------- */
static term_id *nodes; static int nnodes, capnodes;
static int *node_of;
static void collect(term_id t){
    if (node_of[t] >= 0) return;
    if (nnodes == capnodes) { capnodes = capnodes ? capnodes * 2 : 128; nodes = xrealloc(nodes, capnodes * sizeof(term_id)); }
    node_of[t] = nnodes; nodes[nnodes++] = t;
    const og_term *tm = term_get(t);
    switch (tm->kind) {
        case T_AND: case T_OR: case T_IMPLIES: case T_EQ:
        case T_ADD: case T_SUB: case T_MUL:
        case T_LT: case T_LE: case T_GT: case T_GE:
            collect(tm->a); collect(tm->b); break;
        case T_NOT: case T_NEG: collect(tm->a); break;
        case T_ITE: collect(tm->a); collect(tm->b); collect(tm->c); break;
        case T_APP: case T_DISTINCT:
            for (int i = 0; i < tm->args_len; i++) collect(term_arg(t, i));
            break;
        default: break;
    }
}

/* ---------------- congruence closure ---------------- */
static int *uf;
static int uf_find(int x){ while (uf[x] != x) { uf[x] = uf[uf[x]]; x = uf[x]; } return x; }
static bool uf_union(int a, int b){ a = uf_find(a); b = uf_find(b); if (a == b) return false; uf[b] = a; return true; }

static bool same_head(int na, int nb){
    const og_term *x = term_get(nodes[na]), *y = term_get(nodes[nb]);
    if (x->kind != y->kind) return false;
    switch (x->kind) {
        case T_APP: return x->decl == y->decl && x->args_len == y->args_len;
        case T_ADD: case T_SUB: case T_MUL: case T_LT: case T_LE: case T_GT: case T_GE:
        case T_AND: case T_OR: case T_EQ: case T_IMPLIES: return true;
        case T_NOT: case T_NEG: return true;
        case T_ITE: return true;
        case T_DISTINCT: return x->args_len == y->args_len;
        default: return false;
    }
}
static bool congruent(int na, int nb){
    if (!same_head(na, nb)) return false;
    const og_term *x = term_get(nodes[na]), *y = term_get(nodes[nb]);
    switch (x->kind) {
        case T_APP: case T_DISTINCT:
            for (int i = 0; i < x->args_len; i++)
                if (uf_find(node_of[term_arg(nodes[na], i)]) != uf_find(node_of[term_arg(nodes[nb], i)])) return false;
            return true;
        case T_NOT: case T_NEG:
            return uf_find(node_of[x->a]) == uf_find(node_of[y->a]);
        case T_ITE:
            return uf_find(node_of[x->a]) == uf_find(node_of[y->a])
                && uf_find(node_of[x->b]) == uf_find(node_of[y->b])
                && uf_find(node_of[x->c]) == uf_find(node_of[y->c]);
        default:
            return uf_find(node_of[x->a]) == uf_find(node_of[y->a])
                && uf_find(node_of[x->b]) == uf_find(node_of[y->b]);
    }
}
static void cc_fixpoint(void){
    bool changed = true;
    while (changed) {
        changed = false;
        for (int i = 0; i < nnodes; i++)
            for (int j = i + 1; j < nnodes; j++)
                if (uf_find(i) != uf_find(j) && congruent(i, j))
                    if (uf_union(i, j)) changed = true;
    }
}

/* ---------------- linear expressions ----------------
 * Arith variables are congruence classes. A class gets a variable iff it
 * contains a leaf-shaped Int term: an Int variable, an Int application,
 * an ite, or a non-linear product. Linear combinations expand over the
 * class variables of their leaves; equality between a class's members is
 * added as explicit constraints by theory_check. */
static int *class_var;        /* indexed by class rep node, -1 = none */
static int *leaf_var;         /* node -> arith var, frozen before any post-solve unions */
static int nvars;
typedef struct { rat *coef; rat konst; } linexpr;   /* sum coef[i]*var_i + konst */

static bool has_nonconst_leaf(term_id t, int depth){
    if (depth > 64) return true;
    const og_term *tm = term_get(t);
    switch (tm->kind) {
        case T_INT: return false;
        case T_VAR: case T_APP: case T_ITE: return true;
        case T_ADD: case T_SUB: case T_MUL:
            return has_nonconst_leaf(tm->a, depth + 1) || has_nonconst_leaf(tm->b, depth + 1);
        case T_NEG: return has_nonconst_leaf(tm->a, depth + 1);
        default: return true;
    }
}
static bool is_leaf_arith(term_id t){
    const og_term *tm = term_get(t);
    if (tm->sort != sort_int()) return false;
    switch (tm->kind) {
        case T_VAR: case T_APP: case T_ITE: return true;
        case T_MUL: return has_nonconst_leaf(tm->a, 0) && has_nonconst_leaf(tm->b, 0);
        default: return false;
    }
}
static void lin_zero(linexpr *e){ for (int i = 0; i < nvars; i++) e->coef[i] = rat_int(0); e->konst = rat_int(0); }
static bool lin_build(term_id t, linexpr *out, int depth){
    if (depth > 64) return false;
    const og_term *tm = term_get(t);
    if (tm->kind == T_INT) { lin_zero(out); out->konst = rat_int(tm->ival); return true; }
    if (is_leaf_arith(t)) {
        int v = leaf_var[node_of[t]];
        if (v < 0) return false;
        lin_zero(out); out->coef[v] = rat_int(1); return true;
    }
    switch (tm->kind) {
        case T_ADD: case T_SUB: {
            linexpr L, R; L.coef = xmalloc(nvars * sizeof(rat)); R.coef = xmalloc(nvars * sizeof(rat));
            bool ok = lin_build(tm->a, &L, depth + 1) && lin_build(tm->b, &R, depth + 1);
            if (ok) {
                lin_zero(out);
                for (int i = 0; i < nvars; i++) out->coef[i] = (tm->kind == T_ADD) ? rat_add(L.coef[i], R.coef[i]) : rat_sub(L.coef[i], R.coef[i]);
                out->konst = (tm->kind == T_ADD) ? rat_add(L.konst, R.konst) : rat_sub(L.konst, R.konst);
            }
            free(L.coef); free(R.coef); return ok;
        }
        case T_NEG: {
            bool ok = lin_build(tm->a, out, depth + 1);
            if (ok) { for (int i = 0; i < nvars; i++) out->coef[i] = rat_neg(out->coef[i]); out->konst = rat_neg(out->konst); }
            return ok;
        }
        case T_MUL: {
            linexpr L, R; L.coef = xmalloc(nvars * sizeof(rat)); R.coef = xmalloc(nvars * sizeof(rat));
            bool ok = lin_build(tm->a, &L, depth + 1) && lin_build(tm->b, &R, depth + 1);
            if (ok) {
                bool lc = true, rc = true;
                for (int i = 0; i < nvars; i++) { if (L.coef[i].num) lc = false; if (R.coef[i].num) rc = false; }
                if (lc) { lin_zero(out); for (int i = 0; i < nvars; i++) out->coef[i] = rat_mul(L.konst, R.coef[i]); out->konst = rat_mul(L.konst, R.konst); }
                else if (rc) { lin_zero(out); for (int i = 0; i < nvars; i++) out->coef[i] = rat_mul(R.konst, L.coef[i]); out->konst = rat_mul(L.konst, R.konst); }
                else ok = false;
            }
            free(L.coef); free(R.coef); return ok;
        }
        default: return false;
    }
}
/* exprform(t): unit class-var expression for leaves, expansion otherwise */
static bool expr_form(term_id t, linexpr *out){
    if (is_leaf_arith(t)) {
        int v = leaf_var[node_of[t]];
        if (v < 0) return false;
        lin_zero(out); out->coef[v] = rat_int(1); return true;
    }
    return lin_build(t, out, 0);
}

/* ---------------- constraints & FM search ---------------- */
typedef struct { rat *coef; rat rhs; } ineq;      /* sum coef[i]*x_i <= rhs ; for diseqs: != rhs */
static ineq *cons;  static int ncons, capcons;
static ineq *diseqs; static int ndiseq, capdiseq;
static void push_ineq(ineq **arr, int *n, int *cap, rat *coef, rat rhs){
    if (*n == *cap) { *cap = *cap ? *cap * 2 : 32; *arr = xrealloc(*arr, *cap * sizeof(ineq)); }
    (*arr)[*n].coef = coef; (*arr)[*n].rhs = rhs; (*n)++;
}
static void add_rel(linexpr *d, int rel); /* rel: 0 <=, 1 <, 2 >=, 3 >, 4 =, 5 !=  on (expr d) rel 0 */
static void add_le(rat *coef, rat rhs){ /* takes ownership of coef */
    bool allzero = true; for (int i = 0; i < nvars; i++) if (coef[i].num) { allzero = false; break; }
    if (allzero) { /* constant constraint: 0 <= rhs ? */
        if (rhs.num < 0) { /* infeasible: encode as 0 <= -1 */ }
        push_ineq(&cons, &ncons, &capcons, coef, rhs); return;
    }
    push_ineq(&cons, &ncons, &capcons, coef, rhs);
}
static void add_rel(linexpr *d, int rel){
    /* constraint on D = sum coef x + konst, normalised to coef' x <= rhs with rhs = -konst adjusted */
    if (rel == 5) {
        rat *c = xmalloc(nvars * sizeof(rat)); memcpy(c, d->coef, nvars * sizeof(rat));
        push_ineq(&diseqs, &ndiseq, &capdiseq, c, rat_neg(d->konst)); return;
    }
    if (rel == 4) { add_rel(d, 0); linexpr nd; nd.coef = xmalloc(nvars * sizeof(rat)); for (int i = 0; i < nvars; i++) nd.coef[i] = rat_neg(d->coef[i]); nd.konst = rat_neg(d->konst); add_rel(&nd, 0); free(nd.coef); return; }
    rat *c = xmalloc(nvars * sizeof(rat));
    rat rhs;
    switch (rel) {
        case 0: memcpy(c, d->coef, nvars * sizeof(rat)); rhs = rat_neg(d->konst); break;                    /* D <= 0 */
        case 1: memcpy(c, d->coef, nvars * sizeof(rat)); rhs = rat_sub(rat_neg(d->konst), rat_int(1)); break; /* D < 0  -> D <= -1 */
        case 2: for (int i = 0; i < nvars; i++) c[i] = rat_neg(d->coef[i]); rhs = d->konst; break;          /* D >= 0 -> -D <= 0 */
        default: for (int i = 0; i < nvars; i++) c[i] = rat_neg(d->coef[i]); rhs = rat_add(d->konst, rat_int(-1)); break; /* D > 0 -> -D <= -1 */
    }
    add_le(c, rhs);
}

static int64_t *asg_val; static bool *asg_set;
static long budget; static bool budget_out;
static int fm_cap_hit;

/* Working constraint set for FM: coef over nvars + rhs, assigned vars folded in. */
typedef struct { rat *coef; rat rhs; } wcons;
static wcons *wset; static int nwset, capwset;
static void wset_push(rat *coef, rat rhs){
    if (nwset == capwset) { capwset = capwset ? capwset * 2 : 64; wset = xrealloc(wset, capwset * sizeof(wcons)); }
    wset[nwset].coef = coef; wset[nwset].rhs = rhs; nwset++;
}
static void wset_clear(void){ for (int i = 0; i < nwset; i++) free(wset[i].coef); nwset = 0; }
static void wset_load(void){
    wset_clear();
    for (int i = 0; i < ncons; i++) {
        rat *c = xmalloc(nvars * sizeof(rat)); rat rhs = cons[i].rhs;
        for (int v = 0; v < nvars; v++) {
            c[v] = cons[i].coef[v];
            if (asg_set[v] && c[v].num) { rhs = rat_sub(rhs, rat_mul(c[v], rat_int(asg_val[v]))); c[v] = rat_int(0); }
        }
        wset_push(c, rhs);
    }
}
/* Eliminate var u from wset (Fourier-Motzkin). */
static void fm_eliminate(int u){
    int nP = 0, nN = 0;
    for (int i = 0; i < nwset; i++) { if (wset[i].coef[u].num > 0) nP++; else if (wset[i].coef[u].num < 0) nN++; }
    rat **nc = xmalloc((nwset + nP * nN + 1) * sizeof(rat*)); rat *nr = xmalloc((nwset + nP * nN + 1) * sizeof(rat));
    int m = 0;
    for (int i = 0; i < nwset; i++) if (!wset[i].coef[u].num) { nc[m] = wset[i].coef; nr[m] = wset[i].rhs; m++; wset[i].coef = NULL; }
    for (int i = 0; i < nwset; i++) if (wset[i].coef && wset[i].coef[u].num > 0)
        for (int j = 0; j < nwset; j++) if (wset[j].coef && wset[j].coef[u].num < 0) {
            rat *c = xmalloc(nvars * sizeof(rat));
            rat sp = rat_neg(wset[j].coef[u]);   /* >0 scale for i */
            rat sn = wset[i].coef[u];            /* >0 scale for j */
            for (int v = 0; v < nvars; v++) c[v] = rat_add(rat_mul(sp, wset[i].coef[v]), rat_mul(sn, wset[j].coef[v]));
            nc[m] = c; nr[m] = rat_add(rat_mul(sp, wset[i].rhs), rat_mul(sn, wset[j].rhs)); m++;
            if (m > 20000) fm_cap_hit = 1;
        }
    for (int i = 0; i < nwset; i++) free(wset[i].coef);
    nwset = 0;
    for (int i = 0; i < m; i++) wset_push(nc[i], nr[i]);
    free(nc); free(nr);
}
/* Bounds for unassigned var v after eliminating all other unassigned vars.
 * Returns false if the current constraint set is infeasible. */
static bool fm_bounds(int v, bool *has_lo, rat *lo, bool *has_hi, rat *hi){
    wset_load();
    for (int u = 0; u < nvars; u++) {
        if (u == v || asg_set[u]) continue;
        fm_eliminate(u);
        if (fm_cap_hit) return false;
    }
    *has_lo = false; *has_hi = false;
    for (int i = 0; i < nwset; i++) {
        rat c = wset[i].coef[v];
        if (!c.num) { if (wset[i].rhs.num < 0) { wset_clear(); return false; } continue; }
        rat bound = rat_make((int64_t)((__int128)wset[i].rhs.num * c.den), (int64_t)((__int128)wset[i].rhs.den * c.num));
        if (c.num > 0) { if (!*has_hi || rat_cmp(bound, *hi) < 0) *hi = bound; *has_hi = true; }
        else { if (!*has_lo || rat_cmp(bound, *lo) > 0) *lo = bound; *has_lo = true; }
    }
    wset_clear();
    return true;
}
static bool fm_feasible(void){
    wset_load();
    for (int u = 0; u < nvars; u++) if (!asg_set[u]) { fm_eliminate(u); if (fm_cap_hit) return false; }
    bool ok = true;
    for (int i = 0; i < nwset; i++) if (wset[i].rhs.num < 0) { ok = false; break; }
    wset_clear();
    return ok;
}
static int bj_target;   /* deepest var in the disequality that failed at a leaf, -1 = none */
static bool check_full_assignment(void){
    for (int i = 0; i < ncons; i++) {
        rat acc = rat_int(0);
        for (int v = 0; v < nvars; v++) if (cons[i].coef[v].num) acc = rat_add(acc, rat_mul(cons[i].coef[v], rat_int(asg_val[v])));
        if (rat_cmp(acc, cons[i].rhs) > 0) { bj_target = -1; return false; }
    }
    for (int i = 0; i < ndiseq; i++) {
        rat acc = rat_int(0);
        for (int v = 0; v < nvars; v++) if (diseqs[i].coef[v].num) acc = rat_add(acc, rat_mul(diseqs[i].coef[v], rat_int(asg_val[v])));
        if (rat_cmp(acc, diseqs[i].rhs) == 0) {
            bj_target = -1;
            for (int v = 0; v < nvars; v++) if (diseqs[i].coef[v].num && v > bj_target) bj_target = v;
            return false;
        }
    }
    return true;
}
static int solve_rec(void){ /* 1 sat, 0 unsat, -1 unknown */
    if (budget-- <= 0) { budget_out = true; return -1; }
    if (!fm_feasible()) return 0;
    if (fm_cap_hit) return -1;
    int v = -1;
    for (int i = 0; i < nvars; i++) if (!asg_set[i]) { v = i; break; }
    if (v < 0) return check_full_assignment() ? 1 : 0;
    bool has_lo, has_hi; rat lo, hi;
    if (!fm_bounds(v, &has_lo, &lo, &has_hi, &hi)) return budget_out || fm_cap_hit ? -1 : 0;
    int64_t loi = has_lo ? rat_ceil(lo) : 0, hii = has_hi ? rat_floor(hi) : 0;
    if (has_lo && has_hi && loi > hii) return 0;
    int64_t c0;
    if (has_lo && has_hi) c0 = loi <= 0 && 0 <= hii ? 0 : (hii < 0 ? hii : loi);
    else if (has_hi) c0 = hii < 0 ? hii : 0;
    else if (has_lo) c0 = loi > 0 ? loi : 0;
    else c0 = 0;
    asg_set[v] = true; asg_val[v] = c0;
    int r = solve_rec();
    if (r == 1) return 1;
    asg_set[v] = false;
    if (r == -1) return -1;
    if (bj_target >= 0 && bj_target < v) return 0;   /* conflict does not involve v: backjump */
    /* branch: v <= c0-1 */
    {
        rat *c = xcalloc(nvars, sizeof(rat)); for (int i = 0; i < nvars; i++) c[i] = rat_int(0); c[v] = rat_int(1);
        push_ineq(&cons, &ncons, &capcons, c, rat_int(c0 - 1));
        r = solve_rec();
        ncons--; free(cons[ncons].coef);
        if (r != 0) return r;
        if (bj_target >= 0 && bj_target < v) return 0;
    }
    /* branch: v >= c0+1  <=>  -v <= -c0-1 */
    {
        rat *c = xcalloc(nvars, sizeof(rat)); for (int i = 0; i < nvars; i++) c[i] = rat_int(0); c[v] = rat_int(-1);
        push_ineq(&cons, &ncons, &capcons, c, rat_int(-c0 - 1));
        r = solve_rec();
        ncons--; free(cons[ncons].coef);
        if (r != 0) return r;
    }
    return 0;
}

/* ---------------- theory_check ---------------- */
static const term_id *g_atoms; static const bool *g_pol; static int g_natoms;
static int g_tc;
static int *diseq_pairs; static int ndiseq_pairs, capdiseq_pairs;   /* node-index pairs that must differ */
static void add_diseq_pair(int a, int b){
    if (ndiseq_pairs == capdiseq_pairs) { capdiseq_pairs = capdiseq_pairs ? capdiseq_pairs * 2 : 16; diseq_pairs = xrealloc(diseq_pairs, capdiseq_pairs * 2 * sizeof(int)); }
    diseq_pairs[2 * ndiseq_pairs] = a; diseq_pairs[2 * ndiseq_pairs + 1] = b; ndiseq_pairs++;
}
static bool diseq_pairs_ok(void){
    for (int i = 0; i < ndiseq_pairs; i++)
        if (uf_find(diseq_pairs[2 * i]) == uf_find(diseq_pairs[2 * i + 1])) return false;
    return true;
}
/* Bool applications (predicates): congruent arguments must give equal truth values. */
static bool predicate_congruence_ok(void){
    for (int i = 0; i < g_natoms; i++) {
        const og_term *x = term_get(g_atoms[i]);
        if (x->kind != T_APP || x->sort != sort_bool()) continue;
        for (int j = i + 1; j < g_natoms; j++) {
            const og_term *y = term_get(g_atoms[j]);
            if (y->kind != T_APP || y->sort != sort_bool() || y->decl != x->decl || y->args_len != x->args_len) continue;
            bool same = true;
            for (int k = 0; k < x->args_len; k++)
                if (uf_find(node_of[term_arg(g_atoms[i], k)]) != uf_find(node_of[term_arg(g_atoms[j], k)])) { same = false; break; }
            if (same && g_pol[i] != g_pol[j]) return false;
        }
    }
    return true;
}
/* ---------------- true-value evaluation ----------------
 * After the arithmetic solver assigns class variables, every Int term has
 * a TRUE value: leaves take their class value, applications are opaque,
 * and every composite (including non-linear products and ite) is computed
 * from its parts. Boolean terms evaluate through the atom polarities. */
static int8_t *pol_of;      /* term_id -> -1 unknown, 0 false, 1 true (atoms only) */
static bool eval_bool_true(term_id t, int depth);
static int64_t eval_true_int(term_id t, int depth){
    if (depth > 128) return 0;
    const og_term *tm = term_get(t);
    switch (tm->kind) {
        case T_INT: return tm->ival;
        case T_ADD: return eval_true_int(tm->a, depth + 1) + eval_true_int(tm->b, depth + 1);
        case T_SUB: return eval_true_int(tm->a, depth + 1) - eval_true_int(tm->b, depth + 1);
        case T_MUL: return eval_true_int(tm->a, depth + 1) * eval_true_int(tm->b, depth + 1);
        case T_NEG: return -eval_true_int(tm->a, depth + 1);
        case T_ITE: return eval_bool_true(tm->a, depth + 1) ? eval_true_int(tm->b, depth + 1) : eval_true_int(tm->c, depth + 1);
        default: { /* leaf: class variable value */
            int v = (node_of[t] >= 0) ? leaf_var[node_of[t]] : -1;
            return v >= 0 ? asg_val[v] : 0;
        }
    }
}
static bool eval_bool_true(term_id t, int depth){
    if (depth > 128) return false;
    const og_term *tm = term_get(t);
    switch (tm->kind) {
        case T_TRUE: return true;
        case T_FALSE: return false;
        case T_NOT: return !eval_bool_true(tm->a, depth + 1);
        case T_AND: return eval_bool_true(tm->a, depth + 1) && eval_bool_true(tm->b, depth + 1);
        case T_OR: return eval_bool_true(tm->a, depth + 1) || eval_bool_true(tm->b, depth + 1);
        case T_IMPLIES: return !eval_bool_true(tm->a, depth + 1) || eval_bool_true(tm->b, depth + 1);
        case T_LT: return eval_true_int(tm->a, depth + 1) < eval_true_int(tm->b, depth + 1);
        case T_LE: return eval_true_int(tm->a, depth + 1) <= eval_true_int(tm->b, depth + 1);
        case T_GT: return eval_true_int(tm->a, depth + 1) > eval_true_int(tm->b, depth + 1);
        case T_GE: return eval_true_int(tm->a, depth + 1) >= eval_true_int(tm->b, depth + 1);
        case T_EQ: {
            sort_id s = term_get(tm->a)->sort;
            if (s == sort_bool()) return eval_bool_true(tm->a, depth + 1) == eval_bool_true(tm->b, depth + 1);
            if (s == sort_int()) return eval_true_int(tm->a, depth + 1) == eval_true_int(tm->b, depth + 1);
            return uf_find(node_of[tm->a]) == uf_find(node_of[tm->b]);
        }
        case T_DISTINCT: {
            for (int i = 0; i < tm->args_len; i++)
                for (int j = i + 1; j < tm->args_len; j++) {
                    term_id x = term_arg(t, i), y = term_arg(t, j);
                    if (term_get(x)->sort == sort_int()) { if (eval_true_int(x, depth + 1) == eval_true_int(y, depth + 1)) return false; }
                    else if (uf_find(node_of[x]) == uf_find(node_of[y])) return false;
                }
            return true;
        }
        case T_ITE: return eval_bool_true(tm->a, depth + 1) ? eval_bool_true(tm->b, depth + 1) : eval_bool_true(tm->c, depth + 1);
        default: return pol_of[t] == 1;   /* VAR / APP atoms */
    }
}
/* does this Int term's value depend on a non-linear product or an ite? */
static bool has_determined_op(term_id t, int depth){
    if (depth > 64) return false;
    const og_term *tm = term_get(t);
    switch (tm->kind) {
        case T_ITE: return true;
        case T_MUL: return (has_nonconst_leaf(tm->a, 0) && has_nonconst_leaf(tm->b, 0))
                        || has_determined_op(tm->a, depth + 1) || has_determined_op(tm->b, depth + 1);
        case T_ADD: case T_SUB: return has_determined_op(tm->a, depth + 1) || has_determined_op(tm->b, depth + 1);
        case T_NEG: return has_determined_op(tm->a, depth + 1);
        default: return false;
    }
}

/* extra disequalities learned across rounds: expr(p) != expr(q) for node pairs */
static int *xd_pairs; static int nxd, capxd;
static bool xd_seen(int a, int b){
    for (int i = 0; i < nxd; i++) if ((xd_pairs[2*i] == a && xd_pairs[2*i+1] == b) || (xd_pairs[2*i] == b && xd_pairs[2*i+1] == a)) return true;
    return false;
}
static void xd_add(int a, int b){
    if (nxd == capxd) { capxd = capxd ? capxd * 2 : 16; xd_pairs = xrealloc(xd_pairs, capxd * 2 * sizeof(int)); }
    xd_pairs[2*nxd] = a; xd_pairs[2*nxd+1] = b; nxd++;
}

static th_res th_check_inner(og_model *out){
    /* base congruence state: asserted equalities + fixpoint (uf preset by caller) */
    for (int i = 0; i < g_natoms; i++) {
        const og_term *tm = term_get(g_atoms[i]);
        if (tm->kind == T_EQ && g_pol[i]) uf_union(node_of[tm->a], node_of[tm->b]);
    }
    cc_fixpoint();
    int *base_uf = xmalloc((nnodes ? nnodes : 1) * sizeof(int));
    memcpy(base_uf, uf, nnodes * sizeof(int));
    nxd = 0;
    th_res result = TH_UNKNOWN;
    int *uf2 = xmalloc((nnodes ? nnodes : 1) * sizeof(int));
    for (int round = 0; round < 40; round++) {
        memcpy(uf, base_uf, nnodes * sizeof(int));
        if (!diseq_pairs_ok()) { result = TH_UNSAT; break; }
        if (!predicate_congruence_ok()) { result = TH_UNSAT; break; }
        /* arith variables */
        class_var = xmalloc((nnodes ? nnodes : 1) * sizeof(int));
        for (int i = 0; i < nnodes; i++) class_var[i] = -1;
        nvars = 0;
        for (int i = 0; i < nnodes; i++) if (is_leaf_arith(nodes[i])) {
            int r = uf_find(i);
            if (class_var[r] < 0) class_var[r] = nvars++;
        }
        leaf_var = xmalloc((nnodes ? nnodes : 1) * sizeof(int));
        for (int i = 0; i < nnodes; i++) leaf_var[i] = is_leaf_arith(nodes[i]) ? class_var[uf_find(i)] : -1;
        /* constraints: class-member equalities */
        ncons = 0; ndiseq = 0;
        for (int i = 0; i < nnodes; i++) {
            if (term_get(nodes[i])->sort != sort_int()) continue;
            int ri = uf_find(i);
            int first = -1;
            for (int j = 0; j < nnodes; j++) if (uf_find(j) == ri && term_get(nodes[j])->sort == sort_int()) { first = j; break; }
            if (first < 0 || i == first) continue;
            linexpr A, B; A.coef = xmalloc(nvars * sizeof(rat)); B.coef = xmalloc(nvars * sizeof(rat));
            if (expr_form(nodes[i], &A) && expr_form(nodes[first], &B)) {
                linexpr D; D.coef = xmalloc(nvars * sizeof(rat));
                for (int v = 0; v < nvars; v++) D.coef[v] = rat_sub(A.coef[v], B.coef[v]);
                D.konst = rat_sub(A.konst, B.konst);
                bool zero = D.konst.num == 0; for (int v = 0; v < nvars; v++) if (D.coef[v].num) zero = false;
                if (!zero) add_rel(&D, 4);
                free(D.coef);
            }
            free(A.coef); free(B.coef);
        }
        /* constraints: atoms */
        for (int i = 0; i < g_natoms; i++) {
            term_id at = g_atoms[i]; const og_term *tm = term_get(at);
            int rel = -1;
            switch (tm->kind) {
                case T_LT: rel = g_pol[i] ? 1 : 2; break;
                case T_LE: rel = g_pol[i] ? 0 : 3; break;
                case T_GT: rel = g_pol[i] ? 3 : 0; break;
                case T_GE: rel = g_pol[i] ? 2 : 1; break;
                case T_EQ: if (term_get(tm->a)->sort == sort_int()) rel = g_pol[i] ? 4 : 5; break;
                default: break;
            }
            if (rel < 0) continue;
            linexpr A, B; A.coef = xmalloc(nvars * sizeof(rat)); B.coef = xmalloc(nvars * sizeof(rat));
            if (expr_form(tm->a, &A) && expr_form(tm->b, &B)) {
                linexpr D; D.coef = xmalloc(nvars * sizeof(rat));
                for (int v = 0; v < nvars; v++) D.coef[v] = rat_sub(A.coef[v], B.coef[v]);
                D.konst = rat_sub(A.konst, B.konst);
                add_rel(&D, rel);
                free(D.coef);
            }
            free(A.coef); free(B.coef);
        }
        /* constraints: learned disequalities */
        for (int i = 0; i < nxd; i++) {
            linexpr A, B; A.coef = xmalloc(nvars * sizeof(rat)); B.coef = xmalloc(nvars * sizeof(rat));
            if (expr_form(nodes[xd_pairs[2*i]], &A) && expr_form(nodes[xd_pairs[2*i+1]], &B)) {
                linexpr D; D.coef = xmalloc(nvars * sizeof(rat));
                for (int v = 0; v < nvars; v++) D.coef[v] = rat_sub(A.coef[v], B.coef[v]);
                D.konst = rat_sub(A.konst, B.konst);
                add_rel(&D, 5);
                free(D.coef);
            }
            free(A.coef); free(B.coef);
        }
        /* solve */
        asg_val = xcalloc(nvars ? nvars : 1, sizeof(int64_t));
        asg_set = xcalloc(nvars ? nvars : 1, sizeof(bool));
        budget = 200000; budget_out = false; fm_cap_hit = 0; bj_target = -1;
        int sr = nvars ? solve_rec() : (check_full_assignment() ? 1 : 0);
        if (sr == -1) { result = TH_UNKNOWN; break; }
        if (sr == 0) { result = TH_UNSAT; break; }
        for (int v = 0; v < nvars; v++) if (!asg_set[v]) { asg_set[v] = true; asg_val[v] = 0; }
        /* validate arith atoms under true values */
        bool bad = false, bad_unknown = false;
        for (int i = 0; i < g_natoms && !bad; i++) {
            const og_term *tm = term_get(g_atoms[i]);
            if (tm->kind == T_LT || tm->kind == T_LE || tm->kind == T_GT || tm->kind == T_GE
                || (tm->kind == T_EQ && term_get(tm->a)->sort == sort_int())) {
                if (eval_bool_true(g_atoms[i], 0) != g_pol[i]) {
                    bad = true;
                    if (has_determined_op(tm->a, 0) || has_determined_op(tm->b, 0)) bad_unknown = true;
                }
            }
        }
        if (bad) { result = bad_unknown ? TH_UNKNOWN : TH_UNSAT; break; }
        /* value merge on a copy: Int terms with equal true values join classes */
        memcpy(uf2, uf, nnodes * sizeof(int));
        {
            int *save = uf; uf = uf2;
            bool changed = true;
            while (changed) {
                changed = false;
                for (int i = 0; i < nnodes; i++) {
                    if (term_get(nodes[i])->sort != sort_int()) continue;
                    for (int j = i + 1; j < nnodes; j++) {
                        if (term_get(nodes[j])->sort != sort_int()) continue;
                        if (uf_find(i) != uf_find(j) && eval_true_int(nodes[i], 0) == eval_true_int(nodes[j], 0))
                            if (uf_union(i, j)) changed = true;
                    }
                }
                if (changed) cc_fixpoint();
            }
            bool ok = diseq_pairs_ok() && predicate_congruence_ok();
            uf = save;
            if (ok) {
                memcpy(uf, uf2, nnodes * sizeof(int));
                result = TH_SAT;
                break;
            }
        }
        /* find a witness pair: Int terms, different base classes, equal values */
        int wp = -1, wq = -1;
        for (int i = 0; i < nnodes && wp < 0; i++) {
            if (term_get(nodes[i])->sort != sort_int()) continue;
            for (int j = i + 1; j < nnodes; j++) {
                if (term_get(nodes[j])->sort != sort_int()) continue;
                /* were they merged in uf2 but not in base? */
                int a = i, b = j;
                /* check uf2 class equality using saved copy */
                /* (uf2 still holds merged state) */
                /* find in uf2: temporarily swap */
                int *save = uf; uf = uf2;
                bool merged = uf_find(a) == uf_find(b);
                uf = save;
                if (!merged) continue;
                /* different classes in current (base-restored) uf? */
                memcpy(uf, base_uf, nnodes * sizeof(int));
                if (uf_find(i) == uf_find(j)) continue;
                if (eval_true_int(nodes[i], 0) != eval_true_int(nodes[j], 0)) continue;
                if (xd_seen(i, j)) continue;
                wp = i; wq = j; break;
            }
        }
        if (wp < 0) { result = TH_UNSAT; break; }
        xd_add(wp, wq);
    }
    if (result == TH_SAT && out) {
        for (int d = 0; d < decl_count(); d++) {
            const og_decl *dc = decl_get(d);
            if (dc->is_fun) continue;
            term_id vt = mk_var(d);
            if (vt > g_tc || node_of[vt] < 0) continue;
            if (dc->result == sort_int()) { out->int_val[d] = eval_true_int(vt, 0); out->int_set[d] = true; }
            else if (dc->result != sort_bool()) {
                int cls = uf_find(node_of[vt]);
                term_id rep = vt;
                for (int i = 0; i < nnodes; i++) if (uf_find(i) == cls && term_get(nodes[i])->kind == T_VAR) { rep = nodes[i]; break; }
                out->user_rep[d] = rep;
            }
        }
    }
    free(base_uf); free(uf2);
    return result;
}

th_res theory_check(const term_id *atoms, const bool *pol, int natoms, og_model *out){
    g_atoms = atoms; g_pol = pol; g_natoms = natoms;
    nnodes = 0; capnodes = 0; nodes = NULL;
    int tc = term_count(); g_tc = tc;
    node_of = xmalloc((tc + 1) * sizeof(int));
    for (int i = 0; i <= tc; i++) node_of[i] = -1;
    for (int i = 0; i < natoms; i++) collect(atoms[i]);
    pol_of = xmalloc((tc + 1) * sizeof(int8_t));
    for (int i = 0; i <= tc; i++) pol_of[i] = -1;
    for (int i = 0; i < natoms; i++) pol_of[atoms[i]] = pol[i] ? 1 : 0;
    uf = xmalloc((nnodes ? nnodes : 1) * sizeof(int));
    /* negative-distinct atoms need a choice: not(distinct ...) means some pair is equal.
     * Branch over pairs of the FIRST such atom, recursing for any others. */
    int negd = -1;
    for (int i = 0; i < natoms; i++) if (term_get(atoms[i])->kind == T_DISTINCT && !pol[i]) { negd = i; break; }
    ndiseq_pairs = 0;
    for (int i = 0; i < natoms; i++) {
        const og_term *tm = term_get(atoms[i]);
        if (tm->kind == T_EQ && !pol[i]) add_diseq_pair(node_of[tm->a], node_of[tm->b]);
        if (tm->kind == T_DISTINCT && pol[i])
            for (int x = 0; x < tm->args_len; x++)
                for (int y = x + 1; y < tm->args_len; y++)
                    add_diseq_pair(node_of[term_arg(atoms[i], x)], node_of[term_arg(atoms[i], y)]);
    }
    if (negd >= 0) {
        const og_term *tm = term_get(atoms[negd]);
        th_res worst = TH_UNSAT;
        for (int x = 0; x < tm->args_len; x++)
            for (int y = x + 1; y < tm->args_len; y++) {
                for (int i = 0; i < nnodes; i++) uf[i] = i;
                uf_union(node_of[term_arg(atoms[negd], x)], node_of[term_arg(atoms[negd], y)]);
                /* remaining negative-distinct atoms are not branched further in this pass:
                 * they are re-checked by the caller loop through the solver's blocking clauses
                 * only if this branch's check passes them as ordinary atoms (they carry no
                 * constraint unless branched). To stay sound, treat any additional unbranched
                 * negative-distinct atom as UNKNOWN unless the branch happens to satisfy it. */
                bool more = false;
                for (int i = 0; i < natoms; i++) if (i != negd && term_get(atoms[i])->kind == T_DISTINCT && !pol[i]) more = true;
                th_res r = th_check_inner(out);
                if (r == TH_SAT && more) r = TH_UNKNOWN;
                if (r == TH_SAT) return TH_SAT;
                if (r == TH_UNKNOWN) worst = TH_UNKNOWN;
            }
        return worst;
    }
    for (int i = 0; i < nnodes; i++) uf[i] = i;
    return th_check_inner(out);
}

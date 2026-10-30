/*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Ahmad Ali Parr.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 */
#include "og_ast.h"
#include <stdlib.h>
#include <string.h>

static void *xmalloc(size_t n){ void *p = malloc(n ? n : 1); if (!p) { fprintf(stderr, "out of memory\n"); exit(2); } return p; }
static void *xrealloc(void *p, size_t n){ void *q = realloc(p, n ? n : 1); if (!q) { fprintf(stderr, "out of memory\n"); exit(2); } return q; }
static char *xstrdup(const char *s){ size_t n = strlen(s) + 1; char *p = xmalloc(n); memcpy(p, s, n); return p; }

/* ---- sorts ---- */
static og_sort *sorts; static int nsorts, capsorts;
static sort_id add_sort(int kind, const char *name){
    if (nsorts == capsorts) { capsorts = capsorts ? capsorts * 2 : 16; sorts = xrealloc(sorts, capsorts * sizeof(og_sort)); }
    sorts[nsorts].kind = kind; sorts[nsorts].name = xstrdup(name);
    return nsorts++;
}
sort_id sort_bool(void){ return 0; }
sort_id sort_int(void){ return 1; }
sort_id sort_user(const char *name){
    for (int i = 2; i < nsorts; i++)
        if (!strcmp(sorts[i].name, name)) return i;
    return add_sort(SORT_USER, name);
}
int sort_kind_of(sort_id s){ return sorts[s].kind; }
const char *sort_name(sort_id s){ return sorts[s].name; }

/* ---- declarations ---- */
static og_decl *decls; static int ndecls, capdecls;
static decl_id add_decl(const char *name, sort_id res, const sort_id *args, int nargs, bool is_fun){
    if (ndecls == capdecls) { capdecls = capdecls ? capdecls * 2 : 32; decls = xrealloc(decls, capdecls * sizeof(og_decl)); }
    og_decl *d = &decls[ndecls];
    d->name = xstrdup(name); d->result = res; d->nargs = nargs; d->is_fun = is_fun;
    d->args = NULL;
    if (nargs > 0) { d->args = xmalloc(nargs * sizeof(sort_id)); memcpy(d->args, args, nargs * sizeof(sort_id)); }
    return ndecls++;
}
decl_id decl_const(const char *name, sort_id s){
    decl_id old = decl_lookup(name);
    if (old >= 0) return old;
    return add_decl(name, s, NULL, 0, false);
}
decl_id decl_fun(const char *name, const sort_id *args, int nargs, sort_id res){
    decl_id old = decl_lookup(name);
    if (old >= 0) return old;
    return add_decl(name, res, args, nargs, true);
}
decl_id decl_lookup(const char *name){
    for (int i = 0; i < ndecls; i++)
        if (!strcmp(decls[i].name, name)) return i;
    return -1;
}
const og_decl *decl_get(decl_id d){ return &decls[d]; }
int decl_count(void){ return ndecls; }

/* ---- terms with hash-consing ---- */
static og_term *terms; static int nterms, capterms;
static int32_t *arena; static int narena, caparena;
static term_id *htable; static int hcap;   /* open addressing, stores term_id+1 */

static uint32_t hash_mix(uint32_t h, uint32_t x){ h ^= x + 0x9e3779b9u + (h << 6) + (h >> 2); return h; }
static uint32_t term_hash(term_kind k, int32_t a, int32_t b, int32_t c, decl_id d, int64_t iv, const term_id *args, int nargs){
    uint32_t h = hash_mix(2166136261u, (uint32_t)k);
    h = hash_mix(h, (uint32_t)a); h = hash_mix(h, (uint32_t)b); h = hash_mix(h, (uint32_t)c);
    h = hash_mix(h, (uint32_t)d); h = hash_mix(h, (uint32_t)(iv & 0xffffffff)); h = hash_mix(h, (uint32_t)(iv >> 32));
    for (int i = 0; i < nargs; i++) h = hash_mix(h, (uint32_t)args[i]);
    return h ? h : 1;
}
static bool term_struct_eq(const og_term *t, term_kind k, int32_t a, int32_t b, int32_t c, decl_id d, int64_t iv, const term_id *args, int nargs){
    if (t->kind != k || t->a != a || t->b != b || t->c != c || t->decl != d || t->ival != iv) return false;
    if (k == T_DISTINCT) {
        if (t->args_len != nargs) return false;
        for (int i = 0; i < nargs; i++) if (arena[t->args_off + i] != args[i]) return false;
    }
    if (k == T_APP) {
        if (t->args_len != nargs) return false;
        for (int i = 0; i < nargs; i++) if (arena[t->args_off + i] != args[i]) return false;
    }
    return true;
}
static void hgrow(void){
    int ncap = hcap ? hcap * 2 : 1024;
    term_id *nt = xmalloc(ncap * sizeof(term_id));
    for (int i = 0; i < ncap; i++) nt[i] = -1;
    for (int i = 0; i < nterms; i++) {
        uint32_t slot = terms[i].hash & (uint32_t)(ncap - 1);
        while (nt[slot] != -1) slot = (slot + 1) & (uint32_t)(ncap - 1);
        nt[slot] = i;
    }
    free(htable); htable = nt; hcap = ncap;
}
static term_id mk_raw(term_kind k, sort_id s, int32_t a, int32_t b, int32_t c, decl_id d, int64_t iv, const term_id *args, int nargs){
    uint32_t h = term_hash(k, a, b, c, d, iv, args, nargs);
    if (!htable || (nterms + 1) * 2 > hcap) hgrow();
    uint32_t slot = h & (uint32_t)(hcap - 1);
    while (htable[slot] != -1) {
        term_id cand = htable[slot];
        if (terms[cand].hash == h && term_struct_eq(&terms[cand], k, a, b, c, d, iv, args, nargs)) return cand;
        slot = (slot + 1) & (uint32_t)(hcap - 1);
    }
    if (nterms == capterms) { capterms = capterms ? capterms * 2 : 256; terms = xrealloc(terms, capterms * sizeof(og_term)); }
    og_term *t = &terms[nterms];
    t->kind = k; t->sort = s; t->hash = h; t->a = a; t->b = b; t->c = c; t->decl = d; t->ival = iv;
    t->args_off = 0; t->args_len = 0;
    if ((k == T_APP || k == T_DISTINCT) && nargs > 0) {
        if (narena + nargs > caparena) { caparena = caparena ? caparena * 2 : 256; while (narena + nargs > caparena) caparena *= 2; arena = xrealloc(arena, caparena * sizeof(int32_t)); }
        t->args_off = narena; t->args_len = nargs;
        for (int i = 0; i < nargs; i++) arena[narena++] = args[i];
    }
    htable[slot] = nterms;
    return nterms++;
}

void ast_init(void){
    add_sort(SORT_BOOL, "Bool");
    add_sort(SORT_INT, "Int");
}
const og_term *term_get(term_id t){ return &terms[t]; }
int term_count(void){ return nterms; }

term_id mk_var(decl_id d){ return mk_raw(T_VAR, decls[d].result, -1, -1, -1, d, 0, NULL, 0); }
term_id mk_int(int64_t v){ return mk_raw(T_INT, sort_int(), -1, -1, -1, -1, v, NULL, 0); }
term_id mk_true(void){ static term_id t = -1; if (t < 0) t = mk_raw(T_TRUE, sort_bool(), -1, -1, -1, -1, 0, NULL, 0); return t; }
term_id mk_false(void){ static term_id t = -1; if (t < 0) t = mk_raw(T_FALSE, sort_bool(), -1, -1, -1, -1, 0, NULL, 0); return t; }
term_id mk_app(decl_id f, const term_id *args, int nargs){ return mk_raw(T_APP, decls[f].result, -1, -1, -1, f, 0, args, nargs); }

static bool is_true(term_id t){ return terms[t].kind == T_TRUE; }
static bool is_false(term_id t){ return terms[t].kind == T_FALSE; }
static bool is_int(term_id t){ return terms[t].kind == T_INT; }

term_id mk_and(term_id x, term_id y){
    if (is_false(x) || is_false(y)) return mk_false();
    if (is_true(x)) return y;
    if (is_true(y)) return x;
    if (x == y) return x;
    if (x > y) { term_id tmp = x; x = y; y = tmp; }
    return mk_raw(T_AND, sort_bool(), x, y, -1, -1, 0, NULL, 0);
}
term_id mk_or(term_id x, term_id y){
    if (is_true(x) || is_true(y)) return mk_true();
    if (is_false(x)) return y;
    if (is_false(y)) return x;
    if (x == y) return x;
    if (x > y) { term_id tmp = x; x = y; y = tmp; }
    return mk_raw(T_OR, sort_bool(), x, y, -1, -1, 0, NULL, 0);
}
term_id mk_not(term_id x){
    if (is_true(x)) return mk_false();
    if (is_false(x)) return mk_true();
    if (terms[x].kind == T_NOT) return terms[x].a;
    return mk_raw(T_NOT, sort_bool(), x, -1, -1, -1, 0, NULL, 0);
}
term_id mk_implies(term_id x, term_id y){ return mk_or(mk_not(x), y); }
term_id mk_eq(term_id x, term_id y){
    if (x == y) return mk_true();
    if (x > y) { term_id tmp = x; x = y; y = tmp; }
    return mk_raw(T_EQ, sort_bool(), x, y, -1, -1, 0, NULL, 0);
}
term_id mk_distinct(const term_id *args, int nargs){
    term_id *sorted = xmalloc(nargs * sizeof(term_id));
    memcpy(sorted, args, nargs * sizeof(term_id));
    for (int i = 0; i < nargs; i++) for (int j = i + 1; j < nargs; j++) if (sorted[j] < sorted[i]) { term_id t = sorted[i]; sorted[i] = sorted[j]; sorted[j] = t; }
    for (int i = 1; i < nargs; i++)
        if (sorted[i] == sorted[i - 1]) { free(sorted); return mk_false(); }
    term_id r = mk_raw(T_DISTINCT, sort_bool(), -1, -1, -1, -1, 0, sorted, nargs);
    free(sorted);
    return r;
}
term_id mk_ite(term_id c, term_id x, term_id y){
    if (is_true(c)) return x;
    if (is_false(c)) return y;
    if (x == y) return x;
    return mk_raw(T_ITE, terms[x].sort, c, x, y, -1, 0, NULL, 0);
}
term_id mk_add(term_id x, term_id y){
    if (is_int(x) && is_int(y)) return mk_int(terms[x].ival + terms[y].ival);
    if (is_int(x) && terms[x].ival == 0) return y;
    if (is_int(y) && terms[y].ival == 0) return x;
    return mk_raw(T_ADD, sort_int(), x, y, -1, -1, 0, NULL, 0);
}
term_id mk_sub(term_id x, term_id y){
    if (is_int(x) && is_int(y)) return mk_int(terms[x].ival - terms[y].ival);
    if (is_int(y) && terms[y].ival == 0) return x;
    return mk_raw(T_SUB, sort_int(), x, y, -1, -1, 0, NULL, 0);
}
term_id mk_mul(term_id x, term_id y){
    if (is_int(x) && is_int(y)) return mk_int(terms[x].ival * terms[y].ival);
    if (is_int(x) && terms[x].ival == 0) return mk_int(0);
    if (is_int(y) && terms[y].ival == 0) return mk_int(0);
    if (is_int(x) && terms[x].ival == 1) return y;
    if (is_int(y) && terms[y].ival == 1) return x;
    return mk_raw(T_MUL, sort_int(), x, y, -1, -1, 0, NULL, 0);
}
term_id mk_neg(term_id x){
    if (is_int(x)) return mk_int(-terms[x].ival);
    if (terms[x].kind == T_NEG) return terms[x].a;
    return mk_raw(T_NEG, sort_int(), x, -1, -1, -1, 0, NULL, 0);
}
static term_id mk_cmp(term_kind k, term_id x, term_id y){
    if (is_int(x) && is_int(y)) {
        int64_t a = terms[x].ival, b = terms[y].ival;
        bool r = (k == T_LT) ? a < b : (k == T_LE) ? a <= b : (k == T_GT) ? a > b : a >= b;
        return r ? mk_true() : mk_false();
    }
    return mk_raw(k, sort_bool(), x, y, -1, -1, 0, NULL, 0);
}
term_id mk_lt(term_id x, term_id y){ return mk_cmp(T_LT, x, y); }
term_id mk_le(term_id x, term_id y){ return mk_cmp(T_LE, x, y); }
term_id mk_gt(term_id x, term_id y){ return mk_cmp(T_GT, x, y); }
term_id mk_ge(term_id x, term_id y){ return mk_cmp(T_GE, x, y); }

static const char *kind_op(term_kind k){
    switch (k) {
        case T_AND: return "and"; case T_OR: return "or"; case T_NOT: return "not";
        case T_EQ: return "="; case T_ITE: return "ite";
        case T_ADD: return "+"; case T_SUB: return "-"; case T_MUL: return "*";
        case T_NEG: return "-";
        case T_LT: return "<"; case T_LE: return "<="; case T_GT: return ">"; case T_GE: return ">=";
        default: return "?";
    }
}
void term_print(FILE *out, term_id tid){
    const og_term *t = term_get(tid);
    switch (t->kind) {
        case T_VAR: fputs(decls[t->decl].name, out); return;
        case T_INT: fprintf(out, "%lld", (long long)t->ival); return;
        case T_TRUE: fputs("true", out); return;
        case T_FALSE: fputs("false", out); return;
        case T_APP: {
            fprintf(out, "(%s", decls[t->decl].name);
            for (int i = 0; i < t->args_len; i++) { fputc(' ', out); term_print(out, arena[t->args_off + i]); }
            fputc(')', out); return;
        }
        case T_DISTINCT: {
            fputs("(distinct", out);
            for (int i = 0; i < t->args_len; i++) { fputc(' ', out); term_print(out, arena[t->args_off + i]); }
            fputc(')', out); return;
        }
        case T_NOT: case T_NEG:
            fprintf(out, "(%s ", kind_op(t->kind)); term_print(out, t->a); fputc(')', out); return;
        case T_ITE:
            fputs("(ite ", out); term_print(out, t->a); fputc(' ', out); term_print(out, t->b); fputc(' ', out); term_print(out, t->c); fputc(')', out); return;
        default:
            fprintf(out, "(%s ", kind_op(t->kind)); term_print(out, t->a); fputc(' ', out); term_print(out, t->b); fputc(')', out); return;
    }
}
term_id term_arg(term_id t, int i){ return arena[terms[t].args_off + i]; }

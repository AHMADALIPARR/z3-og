#include "og_parse.h"
#include "../ast/og_ast.h"
#include "../solver/og_solver.h"
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

static void *xmalloc(size_t n){ void *p = malloc(n ? n : 1); if (!p) exit(2); return p; }
static void *xrealloc(void *p, size_t n){ void *q = realloc(p, n ? n : 1); if (!q) exit(2); return q; }
static char *xstrdup(const char *s){ size_t n = strlen(s) + 1; char *p = xmalloc(n); memcpy(p, s, n); return p; }

/* ---------- s-expression tree ---------- */
typedef struct sexpr {
    char *atom;                 /* != NULL for atoms */
    struct sexpr **items; int n, cap;
    bool is_string;
} sexpr;
static sexpr *sx_atom(const char *s, bool is_string){
    sexpr *x = xmalloc(sizeof(sexpr)); x->atom = xstrdup(s); x->items = NULL; x->n = 0; x->cap = 0; x->is_string = is_string; return x;
}
static sexpr *sx_list(void){ sexpr *x = xmalloc(sizeof(sexpr)); x->atom = NULL; x->items = NULL; x->n = 0; x->cap = 0; x->is_string = false; return x; }
static void sx_push(sexpr *l, sexpr *it){
    if (l->n == l->cap) { l->cap = l->cap ? l->cap * 2 : 8; l->items = xrealloc(l->items, l->cap * sizeof(sexpr*)); }
    l->items[l->n++] = it;
}

/* ---------- lexer/parser over a growing buffer ---------- */
typedef struct { const char *s; size_t pos, len; } lexer;
static void skip_ws(lexer *lx){
    for (;;) {
        while (lx->pos < lx->len && isspace((unsigned char)lx->s[lx->pos])) lx->pos++;
        if (lx->pos < lx->len && lx->s[lx->pos] == ';') { while (lx->pos < lx->len && lx->s[lx->pos] != '\n') lx->pos++; continue; }
        break;
    }
}
static sexpr *parse_sx(lexer *lx){
    skip_ws(lx);
    if (lx->pos >= lx->len) return NULL;
    char c = lx->s[lx->pos];
    if (c == '(') {
        lx->pos++;
        sexpr *l = sx_list();
        for (;;) {
            skip_ws(lx);
            if (lx->pos >= lx->len) return l;
            if (lx->s[lx->pos] == ')') { lx->pos++; return l; }
            sexpr *it = parse_sx(lx);
            if (!it) return l;
            sx_push(l, it);
        }
    }
    if (c == ')') { lx->pos++; return NULL; }
    if (c == '"') {
        lx->pos++;
        size_t start = lx->pos;
        while (lx->pos < lx->len && lx->s[lx->pos] != '"') lx->pos++;
        size_t n = lx->pos - start;
        char *buf = xmalloc(n + 1); memcpy(buf, lx->s + start, n); buf[n] = 0;
        if (lx->pos < lx->len) lx->pos++;
        sexpr *x = sx_atom(buf, true); free(buf); return x;
    }
    if (c == '|' ) { /* quoted symbol */
        lx->pos++;
        size_t start = lx->pos;
        while (lx->pos < lx->len && lx->s[lx->pos] != '|') lx->pos++;
        size_t n = lx->pos - start;
        char *buf = xmalloc(n + 1); memcpy(buf, lx->s + start, n); buf[n] = 0;
        if (lx->pos < lx->len) lx->pos++;
        sexpr *x = sx_atom(buf, false); free(buf); return x;
    }
    size_t start = lx->pos;
    while (lx->pos < lx->len && !isspace((unsigned char)lx->s[lx->pos]) && lx->s[lx->pos] != '(' && lx->s[lx->pos] != ')' && lx->s[lx->pos] != ';') lx->pos++;
    size_t n = lx->pos - start;
    char *buf = xmalloc(n + 1); memcpy(buf, lx->s + start, n); buf[n] = 0;
    sexpr *x = sx_atom(buf, false); free(buf); return x;
}

/* ---------- define-fun macro store ---------- */
typedef struct { char *name; char **params; sort_id *psorts; int nparams; sort_id result; sexpr *body; } fundef;
static fundef *defs; static int ndefs, capdefs;
static fundef *def_lookup(const char *name){ for (int i = 0; i < ndefs; i++) if (!strcmp(defs[i].name, name)) return &defs[i]; return NULL; }

/* ---------- term building ---------- */
typedef struct { const char **names; term_id *vals; int n, cap; } env;
static void env_push(env *e, const char *name, term_id v){
    if (e->n == e->cap) { e->cap = e->cap ? e->cap * 2 : 8; e->names = xrealloc(e->names, e->cap * sizeof(char*)); e->vals = xrealloc(e->vals, e->cap * sizeof(term_id)); }
    e->names[e->n] = name; e->vals[e->n] = v; e->n++;
}
static bool env_find(env *e, const char *name, term_id *out){
    for (int i = e->n - 1; i >= 0; i--) if (!strcmp(e->names[i], name)) { *out = e->vals[i]; return true; }
    return false;
}
static FILE *g_out;
static bool g_err;
static bool g_poison;   /* an unsupported construct was seen: check-sat must answer unknown */
static void perr(const char *msg){ fprintf(g_out, "(error \"%s\")\n", msg); g_err = true; g_poison = true; }

static sort_id parse_sort(sexpr *x){
    if (x->atom) {
        if (!strcmp(x->atom, "Bool")) return sort_bool();
        if (!strcmp(x->atom, "Int")) return sort_int();
        return sort_user(x->atom);
    }
    perr("unsupported sort");
    return sort_user("_unsupported");
}
static bool is_numeral(const char *s, int64_t *out){
    const char *p = s; bool neg = false;
    if (*p == '-') { neg = true; p++; }
    if (!isdigit((unsigned char)*p)) return false;
    int64_t v = 0;
    while (isdigit((unsigned char)*p)) { v = v * 10 + (*p - '0'); p++; }
    if (*p) return false;
    *out = neg ? -v : v; return true;
}
static term_id build_term(sexpr *x, env *e, int depth);

static term_id build_app(const char *head, sexpr *x, env *e, int depth){
    int n = x->n - 1;
    /* n-ary boolean / arithmetic folds */
    if (!strcmp(head, "and") || !strcmp(head, "or") || !strcmp(head, "+") || !strcmp(head, "*")) {
        if (n < 1) { perr("empty fold"); return mk_true(); }
        term_id acc = build_term(x->items[1], e, depth + 1);
        for (int i = 1; i < n; i++) {
            term_id t = build_term(x->items[1 + i], e, depth + 1);
            if (!strcmp(head, "and")) acc = mk_and(acc, t);
            else if (!strcmp(head, "or")) acc = mk_or(acc, t);
            else if (!strcmp(head, "+")) acc = mk_add(acc, t);
            else acc = mk_mul(acc, t);
        }
        return acc;
    }
    if (!strcmp(head, "-")) {
        if (n == 1) return mk_neg(build_term(x->items[1], e, depth + 1));
        term_id acc = build_term(x->items[1], e, depth + 1);
        for (int i = 1; i < n; i++) acc = mk_sub(acc, build_term(x->items[1 + i], e, depth + 1));
        return acc;
    }
    if (!strcmp(head, "not")) return mk_not(build_term(x->items[1], e, depth + 1));
    if (!strcmp(head, "=>")) {
        term_id acc = build_term(x->items[x->n - 1], e, depth + 1);
        for (int i = n - 1; i >= 1; i--) acc = mk_implies(build_term(x->items[i], e, depth + 1), acc);
        return acc;
    }
    if (!strcmp(head, "=")) {
        if (n < 2) { perr("= needs 2 args"); return mk_true(); }
        term_id acc = mk_true();
        term_id prev = build_term(x->items[1], e, depth + 1);
        for (int i = 1; i < n; i++) { term_id t = build_term(x->items[1 + i], e, depth + 1); acc = mk_and(acc, mk_eq(prev, t)); prev = t; }
        return acc;
    }
    if (!strcmp(head, "distinct")) {
        term_id *args = xmalloc(n * sizeof(term_id));
        for (int i = 0; i < n; i++) args[i] = build_term(x->items[1 + i], e, depth + 1);
        term_id r = mk_distinct(args, n); free(args); return r;
    }
    if (!strcmp(head, "<") || !strcmp(head, "<=") || !strcmp(head, ">") || !strcmp(head, ">=")) {
        term_id acc = mk_true();
        term_id prev = build_term(x->items[1], e, depth + 1);
        for (int i = 1; i < n; i++) {
            term_id t = build_term(x->items[1 + i], e, depth + 1);
            term_id c = !strcmp(head, "<") ? mk_lt(prev, t) : !strcmp(head, "<=") ? mk_le(prev, t) : !strcmp(head, ">") ? mk_gt(prev, t) : mk_ge(prev, t);
            acc = mk_and(acc, c); prev = t;
        }
        return acc;
    }
    if (!strcmp(head, "ite")) return mk_ite(build_term(x->items[1], e, depth + 1), build_term(x->items[2], e, depth + 1), build_term(x->items[3], e, depth + 1));
    if (!strcmp(head, "abs")) {
        term_id a = build_term(x->items[1], e, depth + 1);
        return mk_ite(mk_ge(a, mk_int(0)), a, mk_neg(a));
    }
    /* user function or define-fun macro */
    fundef *fd = def_lookup(head);
    if (fd) {
        if (fd->nparams != n) { perr("define-fun arity mismatch"); return mk_true(); }
        env ne = { 0 };
        for (int i = 0; i < n; i++) env_push(&ne, fd->params[i], build_term(x->items[1 + i], e, depth + 1));
        term_id r = build_term(fd->body, &ne, depth + 1);
        free(ne.names); free(ne.vals);
        return r;
    }
    decl_id d = decl_lookup(head);
    if (d < 0 || !decl_get(d)->is_fun) { perr("unknown function"); return mk_true(); }
    term_id *args = xmalloc(n * sizeof(term_id));
    for (int i = 0; i < n; i++) args[i] = build_term(x->items[1 + i], e, depth + 1);
    term_id r = mk_app(d, args, n); free(args); return r;
}
static term_id build_term(sexpr *x, env *e, int depth){
    if (depth > 200) { perr("term too deep"); return mk_true(); }
    if (x->atom) {
        if (!strcmp(x->atom, "true")) return mk_true();
        if (!strcmp(x->atom, "false")) return mk_false();
        int64_t v; if (is_numeral(x->atom, &v)) return mk_int(v);
        term_id t; if (env_find(e, x->atom, &t)) return t;
        fundef *fd = def_lookup(x->atom);
        if (fd && fd->nparams == 0) { env ne = { 0 }; return build_term(fd->body, &ne, depth + 1); }
        decl_id d = decl_lookup(x->atom);
        if (d < 0) { perr("unknown symbol"); return mk_true(); }
        return mk_var(d);
    }
    if (x->n == 0) { perr("empty term"); return mk_true(); }
    sexpr *h = x->items[0];
    if (h->atom && !strcmp(h->atom, "let")) {
        /* simultaneous let: (let ((x t) ...) body) */
        sexpr *binds = x->items[1];
        env ne = { 0 };
        ne.names = e->names; ne.vals = e->vals; ne.n = e->n; ne.cap = e->cap; /* share prefix; pushes may realloc, acceptable: parent env is by-value copy */
        int added = 0;
        term_id *bvals = xmalloc(binds->n * sizeof(term_id));
        for (int i = 0; i < binds->n; i++) bvals[i] = build_term(binds->items[i]->items[1], e, depth + 1);
        for (int i = 0; i < binds->n; i++) { env_push(&ne, binds->items[i]->items[0]->atom, bvals[i]); added++; }
        term_id r = build_term(x->items[2], &ne, depth + 1);
        free(bvals);
        return r;
    }
    if (h->atom && !strcmp(h->atom, "_")) { perr("indexed operators unsupported"); return mk_true(); }
    if (!h->atom) { perr("unsupported term head"); return mk_true(); }
    return build_app(h->atom, x, e, depth);
}

/* ---------- model evaluation for get-value ---------- */
typedef struct { int kind; int64_t i; bool b; term_id rep; } mval; /* kind 0 int, 1 bool, 2 user */
static bool eval_term(term_id t, mval *out){
    const og_term *tm = term_get(t);
    switch (tm->kind) {
        case T_INT: out->kind = 0; out->i = tm->ival; return true;
        case T_TRUE: out->kind = 1; out->b = true; return true;
        case T_FALSE: out->kind = 1; out->b = false; return true;
        case T_VAR: {
            const og_decl *dc = decl_get(tm->decl);
            if (dc->result == sort_int()) { int64_t v; if (!solver_model_int(tm->decl, &v)) v = 0; out->kind = 0; out->i = v; return true; }
            if (dc->result == sort_bool()) { out->kind = 1; out->b = solver_model_bool(tm->decl) > 0; return true; }
            term_id r = solver_model_user(tm->decl); out->kind = 2; out->rep = r >= 0 ? r : t; return true;
        }
        case T_ADD: case T_SUB: case T_MUL: case T_NEG: {
            mval x, y;
            if (!eval_term(tm->a, &x)) return false;
            if (tm->kind == T_NEG) { out->kind = 0; out->i = -x.i; return true; }
            if (!eval_term(tm->b, &y)) return false;
            out->kind = 0;
            out->i = tm->kind == T_ADD ? x.i + y.i : tm->kind == T_SUB ? x.i - y.i : x.i * y.i;
            return true;
        }
        case T_LT: case T_LE: case T_GT: case T_GE: {
            mval x, y; if (!eval_term(tm->a, &x) || !eval_term(tm->b, &y)) return false;
            out->kind = 1;
            out->b = tm->kind == T_LT ? x.i < y.i : tm->kind == T_LE ? x.i <= y.i : tm->kind == T_GT ? x.i > y.i : x.i >= y.i;
            return true;
        }
        case T_AND: case T_OR: case T_NOT: case T_IMPLIES: {
            mval x, y;
            if (!eval_term(tm->a, &x)) return false;
            if (tm->kind == T_NOT) { out->kind = 1; out->b = !x.b; return true; }
            if (!eval_term(tm->b, &y)) return false;
            out->kind = 1; out->b = tm->kind == T_AND ? (x.b && y.b) : tm->kind == T_OR ? (x.b || y.b) : (!x.b || y.b);
            return true;
        }
        case T_EQ: {
            mval x, y; if (!eval_term(tm->a, &x) || !eval_term(tm->b, &y)) return false;
            out->kind = 1;
            out->b = x.kind == 0 ? x.i == y.i : x.kind == 1 ? x.b == y.b : x.rep == y.rep;
            return true;
        }
        case T_ITE: {
            mval c; if (!eval_term(tm->a, &c)) return false;
            return eval_term(c.b ? tm->b : tm->c, out);
        }
        default: return false;
    }
}
static void print_mval(FILE *out, const mval *v){
    if (v->kind == 0) { if (v->i < 0) fprintf(out, "(- %lld)", (long long)(-v->i)); else fprintf(out, "%lld", (long long)v->i); }
    else if (v->kind == 1) fputs(v->b ? "true" : "false", out);
    else term_print(out, v->rep);
}

/* ---------- commands ---------- */
static int last_check = 0; /* 1 sat, 0 unsat, -1 unknown/none yet */
static void exec_command(sexpr *x){
    if (!x || x->atom || x->n == 0 || !x->items[0]->atom) return;
    const char *cmd = x->items[0]->atom;
    g_err = false;
    if (!strcmp(cmd, "set-logic") || !strcmp(cmd, "set-info") || !strcmp(cmd, "set-option")) return;
    if (!strcmp(cmd, "declare-sort")) {
        if (x->n >= 2 && x->items[1]->atom) sort_user(x->items[1]->atom);
        return;
    }
    if (!strcmp(cmd, "declare-const")) {
        decl_const(x->items[1]->atom, parse_sort(x->items[2]));
        return;
    }
    if (!strcmp(cmd, "declare-fun")) {
        sexpr *sigs = x->items[2];
        if (sigs->n == 0) { decl_const(x->items[1]->atom, parse_sort(x->items[3])); return; }
        sort_id *args = xmalloc(sigs->n * sizeof(sort_id));
        for (int i = 0; i < sigs->n; i++) args[i] = parse_sort(sigs->items[i]);
        decl_fun(x->items[1]->atom, args, sigs->n, parse_sort(x->items[3]));
        free(args);
        return;
    }
    if (!strcmp(cmd, "define-fun")) {
        sexpr *params = x->items[2];
        fundef fd; fd.name = xstrdup(x->items[1]->atom);
        fd.nparams = params->n;
        fd.params = xmalloc((params->n ? params->n : 1) * sizeof(char*));
        fd.psorts = xmalloc((params->n ? params->n : 1) * sizeof(sort_id));
        for (int i = 0; i < params->n; i++) { fd.params[i] = xstrdup(params->items[i]->items[0]->atom); fd.psorts[i] = parse_sort(params->items[i]->items[1]); }
        fd.result = parse_sort(x->items[3]);
        fd.body = x->items[4];
        if (ndefs == capdefs) { capdefs = capdefs ? capdefs * 2 : 16; defs = xrealloc(defs, capdefs * sizeof(fundef)); }
        defs[ndefs++] = fd;
        return;
    }
    if (!strcmp(cmd, "assert")) {
        env e = { 0 };
        term_id t = build_term(x->items[1], &e, 0);
        if (!g_err) solver_assert(t);
        return;
    }
    if (!strcmp(cmd, "check-sat")) {
        if (g_poison) { last_check = -1; fprintf(g_out, "unknown\n"); return; }
        last_check = solver_check();
        fprintf(g_out, "%s\n", last_check == 1 ? "sat" : last_check == 0 ? "unsat" : "unknown");
        return;
    }
    if (!strcmp(cmd, "get-model")) {
        if (last_check == 1) solver_print_model(g_out);
        else fprintf(g_out, "(error \"model is not available\")\n");
        return;
    }
    if (!strcmp(cmd, "get-value")) {
        if (last_check != 1) { fprintf(g_out, "(error \"model is not available\")\n"); return; }
        sexpr *qs = x->items[1];
        fprintf(g_out, "(");
        for (int i = 0; i < qs->n; i++) {
            env e = { 0 };
            term_id t = build_term(qs->items[i], &e, 0);
            mval v;
            fprintf(g_out, "%s(", i ? " " : "");
            term_print(g_out, t);
            fprintf(g_out, " ");
            if (eval_term(t, &v)) print_mval(g_out, &v);
            else fprintf(g_out, "unknown");
            fprintf(g_out, ")");
        }
        fprintf(g_out, ")\n");
        return;
    }
    if (!strcmp(cmd, "push")) { int n = x->n >= 2 && x->items[1]->atom ? atoi(x->items[1]->atom) : 1; while (n-- > 0) solver_push(); return; }
    if (!strcmp(cmd, "pop")) { int n = x->n >= 2 && x->items[1]->atom ? atoi(x->items[1]->atom) : 1; solver_pop(n); return; }
    if (!strcmp(cmd, "reset")) { solver_reset(); last_check = -1; g_poison = false; return; }
    if (!strcmp(cmd, "exit")) { exit(0); }
    if (!strcmp(cmd, "echo")) { if (x->n >= 2 && x->items[1]->atom) fprintf(g_out, "%s\n", x->items[1]->atom); return; }
    if (!strcmp(cmd, "get-info")) {
        const char *k = x->n >= 2 && x->items[1]->atom ? x->items[1]->atom : "";
        if (!strcmp(k, ":name")) fprintf(g_out, "(:name \"z3-og\")\n");
        else if (!strcmp(k, ":version")) fprintf(g_out, "(:version \"0.1.0\")\n");
        else if (!strcmp(k, ":authors")) fprintf(g_out, "(:authors \"z3-og\")\n");
        else fprintf(g_out, "(error \"info not available\")\n");
        return;
    }
    /* anything else: unsupported in this subset */
    fprintf(g_out, "(error \"unsupported command: %s\")\n", cmd);
    g_poison = true;
}

void og_run_stream(FILE *in, FILE *out){
    g_out = out;
    size_t cap = 1 << 16, len = 0;
    char *buf = xmalloc(cap);
    size_t r;
    while ((r = fread(buf + len, 1, cap - len, in)) > 0) {
        len += r;
        if (len == cap) { cap *= 2; buf = xrealloc(buf, cap); }
    }
    lexer lx = { buf, 0, len };
    for (;;) {
        skip_ws(&lx);
        if (lx.pos >= lx.len) break;
        sexpr *x = parse_sx(&lx);
        if (!x) break;
        exec_command(x);
        fflush(out);
    }
    free(buf);
}

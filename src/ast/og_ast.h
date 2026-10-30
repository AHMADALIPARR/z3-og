/*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Ahmad Ali Parr.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 */
/* og_ast.h - hash-consed term manager, in the original Z3 src/ast spirit.
 * Hand-rolled for z3-og: sorts, declarations, terms with structural sharing. */
#ifndef OG_AST_H
#define OG_AST_H
#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>

typedef int32_t sort_id;   /* index into sort table */
typedef int32_t decl_id;   /* index into declaration table */
typedef int32_t term_id;   /* index into term table, -1 = none */

enum { SORT_BOOL = 0, SORT_INT = 1, SORT_USER = 2 };
typedef struct { int kind; char *name; } og_sort;

typedef struct {
    char   *name;
    sort_id result;
    sort_id *args;     /* argument sorts for functions; NULL for constants */
    int     nargs;
    bool    is_fun;
} og_decl;

typedef enum {
    T_VAR, T_INT, T_TRUE, T_FALSE,
    T_APP,                       /* uninterpreted application */
    T_AND, T_OR, T_NOT, T_IMPLIES, T_EQ, T_DISTINCT, T_ITE,
    T_ADD, T_SUB, T_MUL, T_NEG,
    T_LT, T_LE, T_GT, T_GE
} term_kind;

typedef struct {
    term_kind kind;
    sort_id   sort;
    uint32_t  hash;
    int32_t   a, b, c;           /* child term ids (binary/unary/ternary) */
    decl_id   decl;              /* T_VAR / T_APP */
    int64_t   ival;              /* T_INT */
    int32_t   args_off, args_len;/* T_DISTINCT: slice of the args arena */
} og_term;

void     ast_init(void);
sort_id  sort_bool(void);
sort_id  sort_int(void);
sort_id  sort_user(const char *name);
int      sort_kind_of(sort_id s);
const char *sort_name(sort_id s);
decl_id  decl_const(const char *name, sort_id s);
decl_id  decl_fun(const char *name, const sort_id *args, int nargs, sort_id res);
decl_id  decl_lookup(const char *name);
const og_decl *decl_get(decl_id d);
int      decl_count(void);

term_id  mk_var(decl_id d);
term_id  mk_int(int64_t v);
term_id  mk_true(void);
term_id  mk_false(void);
term_id  mk_app(decl_id f, const term_id *args, int nargs);
term_id  mk_and(term_id x, term_id y);
term_id  mk_or(term_id x, term_id y);
term_id  mk_not(term_id x);
term_id  mk_implies(term_id x, term_id y);
term_id  mk_eq(term_id x, term_id y);
term_id  mk_distinct(const term_id *args, int nargs);
term_id  mk_ite(term_id c, term_id x, term_id y);
term_id  mk_add(term_id x, term_id y);
term_id  mk_sub(term_id x, term_id y);
term_id  mk_mul(term_id x, term_id y);
term_id  mk_neg(term_id x);
term_id  mk_lt(term_id x, term_id y);
term_id  mk_le(term_id x, term_id y);
term_id  mk_gt(term_id x, term_id y);
term_id  mk_ge(term_id x, term_id y);

const og_term *term_get(term_id t);
int      term_count(void);
void     term_print(FILE *out, term_id t);
term_id  term_arg(term_id t, int i);   /* i-th arg of T_APP / T_DISTINCT */
#endif

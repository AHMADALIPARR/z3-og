/*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 */
/* rulec.c -- symbolic rule compiler for elementary cellular automata.
 *
 * Compiles a Wolfram elementary rule, unrolled over a fixed number of
 * steps, into Boolean constraints in SMT-LIB 2 that the z3-og solver
 * decides today (and that lower to CNF for the v2 CDCL core). Each
 * cell at each step is a Boolean variable c_<t>_<i>; each step asserts
 * c_<t+1>_<i> = (disjunction of the rule's minterms over the
 * neighbourhood c_<t>_<i-1>, c_<t>_<i>, c_<t>_<i+1>).
 *
 * Usage:
 *   rulec --rule N --width W --steps S [--boundary zero|wrap]
 *         [--init BITS] [--query T,I,V]
 *
 * --init BITS fixes generation 0 (one char per cell, index order).
 * --query T,I,V asserts cell I at step T equals V (0 or 1); the
 * emitted file ends with (check-sat). Without a query the file just
 * asserts the initial state and checks satisfiability.
 *
 * Exit codes: 0 ok, 2 usage/argument error.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void emit_lit(FILE *out, int t, int i, int positive) {
    if (positive)
        fprintf(out, "c_%d_%d", t, i);
    else
        fprintf(out, "(not c_%d_%d)", t, i);
}

/* Emit one minterm for neighbourhood bits (lb, cb, rb) of cell i at
 * step t. With a zero boundary, an out-of-range neighbour fixed to 1
 * kills the minterm (returns 0); fixed to 0 it drops out. */
static int emit_minterm(FILE *out, int width, int wrap,
                        int t, int i, int lb, int cb, int rb) {
    int idx[3], bit[3], n = 0;
    idx[0] = i - 1; bit[0] = lb;
    idx[1] = i;     bit[1] = cb;
    idx[2] = i + 1; bit[2] = rb;
    for (int k = 0; k < 3; k++) {
        if (!wrap && (idx[k] < 0 || idx[k] >= width)) {
            if (bit[k]) return 0;      /* requires a cell that is 0 */
            continue;                  /* satisfied by the boundary  */
        }
        if (wrap) idx[k] = ((idx[k] % width) + width) % width;
        n++;
    }
    if (n == 0) { fprintf(out, "true"); return 1; }
    if (n == 1) {
        for (int k = 0; k < 3; k++) {
            if (!wrap && (i + k - 1 < 0 || i + k - 1 >= width)) continue;
            emit_lit(out, t, wrap ? ((i + k - 1) % width + width) % width
                                  : i + k - 1, bit[k]);
            break;
        }
        return 1;
    }
    fprintf(out, "(and");
    for (int k = 0; k < 3; k++) {
        int j = i + k - 1;
        if (!wrap && (j < 0 || j >= width)) continue;
        if (wrap) j = ((j % width) + width) % width;
        fprintf(out, " ");
        emit_lit(out, t, j, bit[k]);
    }
    fprintf(out, ")");
    return 1;
}

int main(int argc, char **argv) {
    int rule = -1, width = -1, steps = -1, wrap = 0;
    const char *init = NULL;
    int qt = -1, qi = -1, qv = -1;
    for (int a = 1; a < argc; a++) {
        if (!strcmp(argv[a], "--rule") && a + 1 < argc) rule = atoi(argv[++a]);
        else if (!strcmp(argv[a], "--width") && a + 1 < argc) width = atoi(argv[++a]);
        else if (!strcmp(argv[a], "--steps") && a + 1 < argc) steps = atoi(argv[++a]);
        else if (!strcmp(argv[a], "--boundary") && a + 1 < argc)
            wrap = !strcmp(argv[++a], "wrap");
        else if (!strcmp(argv[a], "--init") && a + 1 < argc) init = argv[++a];
        else if (!strcmp(argv[a], "--query") && a + 1 < argc) {
            if (sscanf(argv[++a], "%d,%d,%d", &qt, &qi, &qv) != 3) {
                fprintf(stderr, "rulec: bad --query (want T,I,V)\n");
                return 2;
            }
        } else {
            fprintf(stderr, "rulec: unknown or incomplete argument %s\n", argv[a]);
            return 2;
        }
    }
    if (rule < 0 || rule > 255 || width < 1 || steps < 0) {
        fprintf(stderr, "rulec: need --rule 0..255 --width >=1 --steps >=0\n");
        return 2;
    }
    if (init && (int)strlen(init) != width) {
        fprintf(stderr, "rulec: --init must have exactly width bits\n");
        return 2;
    }
    FILE *out = stdout;
    for (int t = 0; t <= steps; t++)
        for (int i = 0; i < width; i++)
            fprintf(out, "(declare-const c_%d_%d Bool)\n", t, i);
    if (init)
        for (int i = 0; i < width; i++)
            fprintf(out, "(assert (= c_0_%d %s))\n", i,
                    init[i] == '1' ? "true" : "false");
    for (int t = 0; t < steps; t++) {
        for (int i = 0; i < width; i++) {
            /* collect the neighbourhoods whose rule bit is set */
            int terms = 0;
            for (int nb = 0; nb < 8; nb++) if (rule & (1 << nb)) terms++;
            fprintf(out, "(assert (= c_%d_%d ", t + 1, i);
            if (terms == 0) {
                fprintf(out, "false");
            } else if (terms == 8) {
                fprintf(out, "true");
            } else {
                if (terms > 1) fprintf(out, "(or");
                int first = 1;
                for (int nb = 0; nb < 8; nb++) {
                    if (!(rule & (1 << nb))) continue;
                    /* neighbourhood index: left is the high bit */
                    if (terms > 1) fprintf(out, " ");
                    else if (!first) fprintf(out, " ");
                    first = 0;
                    emit_minterm(out, width, wrap, t, i,
                                 (nb >> 2) & 1, (nb >> 1) & 1, nb & 1);
                }
                if (terms > 1) fprintf(out, ")");
            }
            fprintf(out, "))\n");
        }
    }
    if (qt >= 0) {
        if (qt > steps || qi < 0 || qi >= width || (qv != 0 && qv != 1)) {
            fprintf(stderr, "rulec: --query out of range\n");
            return 2;
        }
        fprintf(out, "(assert (= c_%d_%d %s))\n", qt, qi,
                qv ? "true" : "false");
    }
    fprintf(out, "(check-sat)\n");
    return 0;
}

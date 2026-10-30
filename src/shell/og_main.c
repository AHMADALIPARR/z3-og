/* og_main.c - z3-og shell: reads SMT-LIB 2 commands from a file or stdin. */
#include "../parsers/og_parse.h"
#include "../ast/og_ast.h"
#include "../solver/og_solver.h"
#include <stdio.h>
int main(int argc, char **argv){
    ast_init();
    solver_reset();
    FILE *in = stdin;
    if (argc > 1) {
        in = fopen(argv[1], "r");
        if (!in) { fprintf(stderr, "cannot open %s\n", argv[1]); return 1; }
    }
    og_run_stream(in, stdout);
    if (in != stdin) fclose(in);
    return 0;
}

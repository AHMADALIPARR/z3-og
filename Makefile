CC      = gcc
CFLAGS  = -std=c11 -Wall -Wextra -O2
SRC     = src/util/og_rat.c src/ast/og_ast.c src/sat/og_sat.c \
          src/smt/og_theory.c src/solver/og_solver.c \
          src/parsers/og_parse.c src/shell/og_main.c
OBJ     = $(SRC:.c=.o)

z3og: $(OBJ)
	$(CC) $(CFLAGS) -o $@ $(OBJ)

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

test: z3og
	sh tests/run_tests.sh

clean:
	rm -f $(OBJ) z3og
.PHONY: test clean

#!/bin/sh
# run_rulec.sh -- exhaustive small-width verification of the symbolic
# rule compiler (tools/rulec.c) against the independent bit-serial
# reference (tools/refstep.c), decided by the z3-og solver itself.
#
# For every (rule, boundary, initial state) at width 5 and every cell
# of generations 0..3: the solver must prove the simulated value
# (asserting it -> sat) and refute its negation (asserting the
# opposite -> unsat).
set -e
cd "$(dirname "$0")/.."
make >/dev/null
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
gcc -std=c11 -Wall -Wextra -O2 -o "$TMP/rulec" tools/rulec.c
gcc -std=c11 -Wall -Wextra -O2 -o "$TMP/refstep" tools/refstep.c
SOLVER=./z3og
[ -x "$SOLVER" ] || SOLVER=$(find . -maxdepth 2 -name z3og -type f | head -1)

check_all() {
    rule=$1; boundary=$2
    init=0
    while [ "$init" -lt 32 ]; do
        bits=""; n=$init; k=0
        while [ "$k" -lt 5 ]; do bits="$((n % 2))$bits"; n=$((n / 2)); k=$((k + 1)); done
        "$TMP/refstep" "$rule" 5 3 "$boundary" "$bits" > "$TMP/rows"
        t=0
        while read -r row; do
            i=0
            for cell in $(echo "$row" | sed 's/./& /g'); do
                exp=$cell
                neg=$((1 - exp))
                "$TMP/rulec" --rule "$rule" --width 5 --steps 3 \
                    --boundary "$boundary" --init "$bits" \
                    --query "$t,$i,$exp" > "$TMP/q.smt2"
                got=$("$SOLVER" "$TMP/q.smt2" | head -1)
                [ "$got" = "sat" ] || { echo "FAIL rule=$rule b=$boundary init=$bits t=$t i=$i assert=$exp -> $got (want sat)"; exit 1; }
                "$TMP/rulec" --rule "$rule" --width 5 --steps 3 \
                    --boundary "$boundary" --init "$bits" \
                    --query "$t,$i,$neg" > "$TMP/q.smt2"
                got=$("$SOLVER" "$TMP/q.smt2" | head -1)
                [ "$got" = "unsat" ] || { echo "FAIL rule=$rule b=$boundary init=$bits t=$t i=$i assert=$neg -> $got (want unsat)"; exit 1; }
                checks=$((checks + 2))
                i=$((i + 1))
            done
            t=$((t + 1))
        done < "$TMP/rows"
        init=$((init + 1))
    done
}

checks=0
for rule in 30 90 110; do check_all "$rule" zero; done
check_all 30 wrap
echo "rulec: $checks solver checks passed (rules 30/90/110 zero-boundary, rule 30 wrap; width 5, steps 3, all 32 inits, every cell proved and refuted)"

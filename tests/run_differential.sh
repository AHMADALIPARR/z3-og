#!/bin/sh
# z3-og -- hand-rolled SMT stack. Copyright (c) 2026 Ahmad Ali Parr.
# Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
# LICENSE v1.0 -- see LICENSE at the repository root. Commercial
# exploitation requires separate written authorisation; publication,
# access, download, visibility, or possession is not authorisation.
# Differential test: z3-og vs the system z3 (oracle) over tests/corpus/.
# MISMATCH = sat-vs-unsat disagreement (a soundness failure).
# unknown    = z3-og declined (out of fragment, budget, or poisoned input).
# no-verdict = z3-og printed no verdict in time (usually tactic-command
#              files with no plain (check-sat), or a timeout).
# skipped    = the oracle itself gave no verdict.
cd "$(dirname "$0")/.."
agree=0; unknown=0; mismatch=0; noverdict=0; skipped=0
for f in tests/corpus/*.smt2; do
    want=$(timeout 10 z3 "$f" 2>/dev/null | grep -m1 -E '^(sat|unsat|unknown)$')
    got=$(timeout 10 ./z3og "$f" 2>/dev/null | grep -m1 -E '^(sat|unsat|unknown)$')
    if [ -z "$want" ]; then skipped=$((skipped + 1)); continue; fi
    if [ -z "$got" ]; then noverdict=$((noverdict + 1)); continue; fi
    if [ "$got" = "$want" ]; then agree=$((agree + 1));
    elif [ "$got" = "unknown" ]; then unknown=$((unknown + 1));
    else echo "MISMATCH $f oracle=$want z3og=$got"; mismatch=$((mismatch + 1)); fi
done
echo "differential: agree=$agree unknown=$unknown mismatch=$mismatch no-verdict=$noverdict skipped=$skipped"
[ "$mismatch" -eq 0 ]

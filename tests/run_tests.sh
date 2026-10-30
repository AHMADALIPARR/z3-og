#!/bin/sh
# z3-og -- hand-rolled SMT stack. Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
# Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
# LICENSE v1.0 -- see LICENSE at the repository root. Commercial
# exploitation requires separate written authorisation; publication,
# access, download, visibility, or possession is not authorisation.
# z3-og self-tests: each tests/*.smt2 must produce the verdict in tests/expected.txt
cd "$(dirname "$0")/.."
fail=0; total=0
while read -r file want; do
    case "$file" in \#*|"") continue;; esac
    total=$((total + 1))
    got=$(timeout 15 ./z3og "tests/$file" | head -1)
    if [ "$got" = "$want" ]; then
        echo "PASS $file -> $got"
    else
        echo "FAIL $file -> got '$got', want '$want'"
        fail=$((fail + 1))
    fi
done < tests/expected.txt
echo "self-tests: $((total - fail))/$total passed"
[ "$fail" -eq 0 ]

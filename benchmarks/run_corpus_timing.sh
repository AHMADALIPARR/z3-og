#!/bin/sh
# run_corpus_timing.sh -- wall-clock comparison on the differential
# corpus: ./z3og vs the system z3, same files, same machine, 10 s cap.
# z3-og -- hand-rolled SMT stack. Copyright (c) 2026 Ahmad Ali Parr.
# Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
# LICENSE v1.0 -- see LICENSE at the repository root.
set -e
cd "$(dirname "$0")/.."
make >/dev/null
Z3=$(command -v z3 || true)
[ -n "$Z3" ] || { echo "no system z3 found"; exit 1; }
OUT=benchmarks/corpus_timing.csv
echo "file,z3og_ms,z3_ms,z3og_verdict,z3_verdict" > "$OUT"
for f in tests/corpus/*.smt2; do
    s=$(date +%s%N); v1=$(timeout 10 ./z3og "$f" 2>/dev/null | head -1 || echo timeout); e=$(date +%s%N); m1=$(( (e - s) / 1000000 ))
    s=$(date +%s%N); v2=$(timeout 10 "$Z3" "$f" 2>/dev/null | head -1 || echo timeout); e=$(date +%s%N); m2=$(( (e - s) / 1000000 ))
    echo "$(basename "$f"),$m1,$m2,$v1,$v2" >> "$OUT"
done
echo "wrote $OUT"

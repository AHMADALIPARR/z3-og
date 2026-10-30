/* bench_crypto.c -- throughput of the hand-rolled crypto layer.
 * z3-og -- hand-rolled SMT stack. Copyright (c) 2026 Ahmad Ali Parr.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. */
#define _POSIX_C_SOURCE 199309L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "../crypto/og_sha256.h"
#include "../crypto/og_merkle.h"

static double now_s(void) {
    struct timespec ts; clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec + ts.tv_nsec / 1e9;
}

int main(void) {
    const size_t total = 64u << 20; /* 64 MiB */
    unsigned char *buf = malloc(total);
    if (!buf) return 2;
    for (size_t i = 0; i < total; i++) buf[i] = (unsigned char)(i * 31u + 7u);

    double t0 = now_s();
    og_sha256_ctx c; og_sha256_init(&c);
    for (size_t off = 0; off < total; off += 65536)
        og_sha256_update(&c, buf + off, 65536);
    unsigned char dig[32]; og_sha256_final(&c, dig);
    double t1 = now_s();
    printf("sha256        %8.1f MiB/s  (64 MiB, digest %02x%02x%02x%02x)\n",
           (total / 1048576.0) / (t1 - t0), dig[0], dig[1], dig[2], dig[3]);

    /* Merkle root over 1024 leaves of 4 KiB each, 100 rounds */
    const int leaves = 1024, rounds = 100;
    unsigned char *leaf = malloc(4096);
    if (!leaf) return 2;
    memset(leaf, 0xA5, 4096);
    static og_merkle_leaf lv[1024];
    for (int i = 0; i < leaves; i++) { lv[i].data = leaf; lv[i].len = 4096; }
    unsigned char root[32];
    t0 = now_s();
    for (int r = 0; r < rounds; r++)
        og_merkle_root(lv, leaves, root);
    t1 = now_s();
    printf("merkle-1024   %8.1f roots/s (1024 leaves x 4 KiB, root %02x%02x%02x%02x)\n",
           rounds / (t1 - t0), root[0], root[1], root[2], root[3]);
    free(buf); free(leaf);
    return 0;
}

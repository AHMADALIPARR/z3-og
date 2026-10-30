/*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 */
/*
 * og_merkle.c -- Merkle tree root computation. See og_merkle.h for the
 * hash layout and the endianness-agnostic serialisation rule.
 *
 * The algorithm is the textbook bottom-up fold: hash every leaf, then
 * repeatedly hash adjacent pairs until one digest remains. An odd
 * trailing digest at a level is promoted to the next level unchanged
 * (it is NOT duplicated and NOT hashed with itself), which keeps the
 * root a pure function of the leaf sequence.
 */
#include "og_merkle.h"

#include <stdlib.h>
#include <string.h>

#define OG_MERKLE_LEAF_TAG 0x00u
#define OG_MERKLE_NODE_TAG 0x01u

/* leaf hash = SHA256( 0x00 || len64be || data ) */
static void og_merkle_hash_leaf(const og_merkle_leaf *leaf,
                                uint8_t out[OG_MERKLE_ROOT_LEN])
{
    og_sha256_ctx ctx;
    uint8_t tag = OG_MERKLE_LEAF_TAG;
    uint8_t lenbe[8];
    uint64_t n = (uint64_t)leaf->len;
    int i;

    /* The length prefix is built byte by byte, most significant byte
     * first. This is the endianness-agnostic serialisation rule: the
     * bytes hashed here are the same on every host, by construction. */
    for (i = 0; i < 8; i++) {
        lenbe[i] = (uint8_t)(n >> (56 - 8 * i));
    }

    og_sha256_init(&ctx);
    og_sha256_update(&ctx, &tag, 1);
    og_sha256_update(&ctx, lenbe, sizeof lenbe);
    if (leaf->len > 0) {
        og_sha256_update(&ctx, leaf->data, leaf->len);
    }
    og_sha256_final(&ctx, out);
}

/* internal node = SHA256( 0x01 || left32 || right32 ) */
static void og_merkle_hash_node(const uint8_t left[OG_MERKLE_ROOT_LEN],
                                const uint8_t right[OG_MERKLE_ROOT_LEN],
                                uint8_t out[OG_MERKLE_ROOT_LEN])
{
    og_sha256_ctx ctx;
    uint8_t tag = OG_MERKLE_NODE_TAG;

    og_sha256_init(&ctx);
    og_sha256_update(&ctx, &tag, 1);
    og_sha256_update(&ctx, left, OG_MERKLE_ROOT_LEN);
    og_sha256_update(&ctx, right, OG_MERKLE_ROOT_LEN);
    og_sha256_final(&ctx, out);
}

int og_merkle_root(const og_merkle_leaf *leaves, size_t count,
                   uint8_t out[OG_MERKLE_ROOT_LEN])
{
    uint8_t *cur;
    uint8_t *next;
    size_t n;
    size_t i;

    if (count == 0) {
        /* Empty tree: root is the SHA-256 of the empty input. */
        og_sha256("", 0, out);
        return 0;
    }

    cur = (uint8_t *)malloc(count * (size_t)OG_MERKLE_ROOT_LEN);
    if (cur == NULL) {
        return -1;
    }
    next = (uint8_t *)malloc(((count + 1) / 2) * (size_t)OG_MERKLE_ROOT_LEN);
    if (next == NULL) {
        free(cur);
        return -1;
    }

    for (i = 0; i < count; i++) {
        og_merkle_hash_leaf(&leaves[i], cur + i * OG_MERKLE_ROOT_LEN);
    }

    /* Fold level by level. Both buffers are large enough for every
     * level: cur holds the current level, next the level above, whose
     * size is at most ceil(n/2) of the level below it. */
    n = count;
    while (n > 1) {
        size_t m = 0;
        for (i = 0; i < n; i += 2) {
            if (i + 1 < n) {
                og_merkle_hash_node(cur + i * OG_MERKLE_ROOT_LEN,
                                    cur + (i + 1) * OG_MERKLE_ROOT_LEN,
                                    next + m * OG_MERKLE_ROOT_LEN);
            } else {
                /* Odd trailing node: promoted unchanged. */
                memcpy(next + m * OG_MERKLE_ROOT_LEN,
                       cur + i * OG_MERKLE_ROOT_LEN,
                       OG_MERKLE_ROOT_LEN);
            }
            m++;
        }
        {
            uint8_t *swap = cur;
            cur = next;
            next = swap;
        }
        n = m;
    }

    memcpy(out, cur, OG_MERKLE_ROOT_LEN);
    free(cur);
    free(next);
    return 0;
}

int og_merkle_root_hex(const og_merkle_leaf *leaves, size_t count,
                       char out[65])
{
    uint8_t root[OG_MERKLE_ROOT_LEN];

    if (og_merkle_root(leaves, count, root) != 0) {
        out[0] = '\0';
        return -1;
    }
    og_sha256_hex(root, out);
    return 0;
}

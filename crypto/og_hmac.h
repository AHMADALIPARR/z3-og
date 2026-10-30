/*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Ahmad Ali Parr.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 */
/*
 * og_hmac.h -- HMAC-SHA256, hand-rolled in C11 for the z3-og clean
 * stack. Implements RFC 2104 (HMAC: Keyed-Hashing for Message
 * Authentication) instantiated with SHA-256; test vectors are RFC 4231.
 *
 * In the z3-og assertion ledger this is the keyed counterpart to the
 * plain digest in og_sha256.h: ledger checkpoints can be authenticated
 * with a key so a root hash also proves who sealed the checkpoint.
 */
#ifndef OG_HMAC_H
#define OG_HMAC_H

#include <stddef.h>
#include <stdint.h>

#include "og_sha256.h"

#define OG_HMAC_SHA256_LEN OG_SHA256_DIGEST_LEN

typedef struct {
    og_sha256_ctx inner;                    /* hash of (K ^ ipad) || msg */
    uint8_t key_block[OG_SHA256_BLOCK_LEN]; /* K, zero-padded to 64 B */
} og_hmac_sha256_ctx;

/* Begin an HMAC with the given key. A key longer than the 64-byte
 * SHA-256 block is first reduced to its SHA-256 digest, per RFC 2104
 * step 1; key may be NULL only when key_len is 0. */
void og_hmac_sha256_init(og_hmac_sha256_ctx *ctx,
                         const uint8_t *key, size_t key_len);

/* Feed message bytes. May be called any number of times. */
void og_hmac_sha256_update(og_hmac_sha256_ctx *ctx,
                           const void *data, size_t len);

/* Finish and write the 32-byte MAC to out. The context is wiped by
 * this call and must be re-initialised before reuse. */
void og_hmac_sha256_final(og_hmac_sha256_ctx *ctx,
                          uint8_t out[OG_HMAC_SHA256_LEN]);

/* One-shot convenience: MAC of a single contiguous buffer. */
void og_hmac_sha256(const uint8_t *key, size_t key_len,
                    const void *data, size_t len,
                    uint8_t out[OG_HMAC_SHA256_LEN]);

#endif /* OG_HMAC_H */

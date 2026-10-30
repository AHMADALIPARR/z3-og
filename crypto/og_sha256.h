/*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 */
/*
 * og_sha256.h -- SHA-256 message digest, hand-rolled in C11 for the
 * z3-og clean stack. Implements FIPS 180-4 (Secure Hash Standard).
 *
 * This is the hash anchor for the z3-og SMT assertion ledger: every
 * assertion record is content-addressed by its SHA-256 digest, and the
 * Merkle layer (og_merkle.h) and HMAC layer (og_hmac.h) build on this
 * primitive. All multi-byte quantities in the algorithm (message words,
 * padding length) are serialised BIG-ENDIAN, exactly as FIPS 180-4
 * specifies, so digests are identical on hosts of either byte order.
 */
#ifndef OG_SHA256_H
#define OG_SHA256_H

#include <stddef.h>
#include <stdint.h>

#define OG_SHA256_DIGEST_LEN 32
#define OG_SHA256_BLOCK_LEN 64

typedef struct {
    uint32_t h[8];                          /* chaining state */
    uint64_t total_len;                     /* message bytes fed so far */
    uint8_t block[OG_SHA256_BLOCK_LEN];     /* partial-block buffer */
    size_t block_len;                       /* bytes valid in block */
} og_sha256_ctx;

/* Initialise ctx for a new message. */
void og_sha256_init(og_sha256_ctx *ctx);

/* Feed len bytes from data into the message. May be called any number
 * of times, with any chunk sizes; data may be NULL only when len is 0. */
void og_sha256_update(og_sha256_ctx *ctx, const void *data, size_t len);

/* Finish the message and write the 32-byte digest to out. The context
 * is wiped by this call and must be re-initialised before reuse. */
void og_sha256_final(og_sha256_ctx *ctx, uint8_t out[OG_SHA256_DIGEST_LEN]);

/* One-shot convenience: digest of a single contiguous buffer. */
void og_sha256(const void *data, size_t len,
               uint8_t out[OG_SHA256_DIGEST_LEN]);

/* Render a digest as 64 lowercase hex digits plus a NUL terminator.
 * out must have room for 65 chars. */
void og_sha256_hex(const uint8_t digest[OG_SHA256_DIGEST_LEN], char out[65]);

#endif /* OG_SHA256_H */

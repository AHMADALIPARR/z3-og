/*
 * og_hmac.c -- HMAC-SHA256 per RFC 2104. See og_hmac.h for context.
 *
 * Construction (RFC 2104 section 2), with B = 64 (SHA-256 block size):
 *   HMAC(K, m) = H( (K' ^ opad) || H( (K' ^ ipad) || m ) )
 * where K' is the key, hashed first if longer than B bytes, then
 * zero-padded to B bytes; ipad = 0x36 repeated, opad = 0x5c repeated.
 */
#include "og_hmac.h"

#include <string.h>

#define OG_HMAC_IPAD 0x36u
#define OG_HMAC_OPAD 0x5cu

void og_hmac_sha256_init(og_hmac_sha256_ctx *ctx,
                         const uint8_t *key, size_t key_len)
{
    uint8_t pad[OG_SHA256_BLOCK_LEN];
    size_t i;

    /* Step 1-3 of RFC 2104: derive K', the block-sized key. */
    memset(ctx->key_block, 0, sizeof ctx->key_block);
    if (key_len > (size_t)OG_SHA256_BLOCK_LEN) {
        /* Long key: K' starts with SHA256(K); the rest stays zero.
         * The digest lands in the first 32 bytes of the zeroed block. */
        og_sha256(key, key_len, ctx->key_block);
    } else if (key_len > 0) {
        memcpy(ctx->key_block, key, key_len);
    }

    /* Step 4-5: start the inner hash with (K' ^ ipad). */
    for (i = 0; i < (size_t)OG_SHA256_BLOCK_LEN; i++) {
        pad[i] = (uint8_t)(ctx->key_block[i] ^ OG_HMAC_IPAD);
    }
    og_sha256_init(&ctx->inner);
    og_sha256_update(&ctx->inner, pad, sizeof pad);

    memset(pad, 0, sizeof pad);
}

void og_hmac_sha256_update(og_hmac_sha256_ctx *ctx,
                           const void *data, size_t len)
{
    /* Step 6 of RFC 2104: append the message to the inner hash. */
    og_sha256_update(&ctx->inner, data, len);
}

void og_hmac_sha256_final(og_hmac_sha256_ctx *ctx,
                          uint8_t out[OG_HMAC_SHA256_LEN])
{
    uint8_t inner_digest[OG_SHA256_DIGEST_LEN];
    uint8_t pad[OG_SHA256_BLOCK_LEN];
    og_sha256_ctx outer;
    size_t i;

    og_sha256_final(&ctx->inner, inner_digest);

    /* Step 7-9: outer hash over (K' ^ opad) || inner_digest. */
    for (i = 0; i < (size_t)OG_SHA256_BLOCK_LEN; i++) {
        pad[i] = (uint8_t)(ctx->key_block[i] ^ OG_HMAC_OPAD);
    }
    og_sha256_init(&outer);
    og_sha256_update(&outer, pad, sizeof pad);
    og_sha256_update(&outer, inner_digest, sizeof inner_digest);
    og_sha256_final(&outer, out);

    memset(pad, 0, sizeof pad);
    memset(inner_digest, 0, sizeof inner_digest);
    memset(ctx, 0, sizeof *ctx);
}

void og_hmac_sha256(const uint8_t *key, size_t key_len,
                    const void *data, size_t len,
                    uint8_t out[OG_HMAC_SHA256_LEN])
{
    og_hmac_sha256_ctx ctx;

    og_hmac_sha256_init(&ctx, key, key_len);
    og_hmac_sha256_update(&ctx, data, len);
    og_hmac_sha256_final(&ctx, out);
}

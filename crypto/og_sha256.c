/*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 */
/*
 * og_sha256.c -- SHA-256 per FIPS 180-4. See og_sha256.h for context.
 *
 * Hand-rolled original C11: the message schedule, compression function
 * and padding below are written directly from the FIPS 180-4 spec
 * (sections 4.1.2, 5.1.1, 6.2), not adapted from any existing code.
 */
#include "og_sha256.h"

#include <string.h>

#define ROTR(x, n) (((x) >> (n)) | ((x) << (32 - (n))))
#define CH(x, y, z) (((x) & (y)) ^ (~(x) & (z)))
#define MAJ(x, y, z) (((x) & (y)) ^ ((x) & (z)) ^ ((y) & (z)))
#define BSIG0(x) (ROTR(x, 2) ^ ROTR(x, 13) ^ ROTR(x, 22))
#define BSIG1(x) (ROTR(x, 6) ^ ROTR(x, 11) ^ ROTR(x, 25))
#define SSIG0(x) (ROTR(x, 7) ^ ROTR(x, 18) ^ ((x) >> 3))
#define SSIG1(x) (ROTR(x, 17) ^ ROTR(x, 19) ^ ((x) >> 10))

/* Round constants: first 32 bits of the fractional parts of the cube
 * roots of the first 64 primes (FIPS 180-4 section 4.2.2). */
static const uint32_t OG_K[64] = {
    0x428a2f98u, 0x71374491u, 0xb5c0fbcfu, 0xe9b5dba5u,
    0x3956c25bu, 0x59f111f1u, 0x923f82a4u, 0xab1c5ed5u,
    0xd807aa98u, 0x12835b01u, 0x243185beu, 0x550c7dc3u,
    0x72be5d74u, 0x80deb1feu, 0x9bdc06a7u, 0xc19bf174u,
    0xe49b69c1u, 0xefbe4786u, 0x0fc19dc6u, 0x240ca1ccu,
    0x2de92c6fu, 0x4a7484aau, 0x5cb0a9dcu, 0x76f988dau,
    0x983e5152u, 0xa831c66du, 0xb00327c8u, 0xbf597fc7u,
    0xc6e00bf3u, 0xd5a79147u, 0x06ca6351u, 0x14292967u,
    0x27b70a85u, 0x2e1b2138u, 0x4d2c6dfcu, 0x53380d13u,
    0x650a7354u, 0x766a0abbu, 0x81c2c92eu, 0x92722c85u,
    0xa2bfe8a1u, 0xa81a664bu, 0xc24b8b70u, 0xc76c51a3u,
    0xd192e819u, 0xd6990624u, 0xf40e3585u, 0x106aa070u,
    0x19a4c116u, 0x1e376c08u, 0x2748774cu, 0x34b0bcb5u,
    0x391c0cb3u, 0x4ed8aa4au, 0x5b9cca4fu, 0x682e6ff3u,
    0x748f82eeu, 0x78a5636fu, 0x84c87814u, 0x8cc70208u,
    0x90befffau, 0xa4506cebu, 0xbef9a3f7u, 0xc67178f2u
};

/* Compression function: absorb one 64-byte block into the state. */
static void og_sha256_compress(og_sha256_ctx *ctx,
                               const uint8_t block[OG_SHA256_BLOCK_LEN])
{
    uint32_t w[64];
    uint32_t a, b, c, d, e, f, g, hh;
    int i;

    /* Message schedule: the block as 16 big-endian words, expanded to
     * 64 words (FIPS 180-4 section 6.2.2, steps 1). */
    for (i = 0; i < 16; i++) {
        w[i] = ((uint32_t)block[4 * i] << 24)
             | ((uint32_t)block[4 * i + 1] << 16)
             | ((uint32_t)block[4 * i + 2] << 8)
             | ((uint32_t)block[4 * i + 3]);
    }
    for (i = 16; i < 64; i++) {
        w[i] = SSIG1(w[i - 2]) + w[i - 7] + SSIG0(w[i - 15]) + w[i - 16];
    }

    a = ctx->h[0]; b = ctx->h[1]; c = ctx->h[2]; d = ctx->h[3];
    e = ctx->h[4]; f = ctx->h[5]; g = ctx->h[6]; hh = ctx->h[7];

    for (i = 0; i < 64; i++) {
        uint32_t t1 = hh + BSIG1(e) + CH(e, f, g) + OG_K[i] + w[i];
        uint32_t t2 = BSIG0(a) + MAJ(a, b, c);
        hh = g; g = f; f = e; e = d + t1;
        d = c; c = b; b = a; a = t1 + t2;
    }

    ctx->h[0] += a; ctx->h[1] += b; ctx->h[2] += c; ctx->h[3] += d;
    ctx->h[4] += e; ctx->h[5] += f; ctx->h[6] += g; ctx->h[7] += hh;

    memset(w, 0, sizeof w);
}

void og_sha256_init(og_sha256_ctx *ctx)
{
    /* Initial hash values: first 32 bits of the fractional parts of
     * the square roots of the first 8 primes (FIPS 180-4 5.3.3). */
    ctx->h[0] = 0x6a09e667u;
    ctx->h[1] = 0xbb67ae85u;
    ctx->h[2] = 0x3c6ef372u;
    ctx->h[3] = 0xa54ff53au;
    ctx->h[4] = 0x510e527fu;
    ctx->h[5] = 0x9b05688cu;
    ctx->h[6] = 0x1f83d9abu;
    ctx->h[7] = 0x5be0cd19u;
    ctx->total_len = 0;
    ctx->block_len = 0;
    memset(ctx->block, 0, sizeof ctx->block);
}

void og_sha256_update(og_sha256_ctx *ctx, const void *data, size_t len)
{
    const uint8_t *p = (const uint8_t *)data;

    ctx->total_len += (uint64_t)len;
    while (len > 0) {
        size_t room = (size_t)OG_SHA256_BLOCK_LEN - ctx->block_len;
        size_t take = (len < room) ? len : room;
        memcpy(ctx->block + ctx->block_len, p, take);
        ctx->block_len += take;
        p += take;
        len -= take;
        if (ctx->block_len == (size_t)OG_SHA256_BLOCK_LEN) {
            og_sha256_compress(ctx, ctx->block);
            ctx->block_len = 0;
        }
    }
}

void og_sha256_final(og_sha256_ctx *ctx, uint8_t out[OG_SHA256_DIGEST_LEN])
{
    uint64_t bit_len = ctx->total_len * 8u;
    uint8_t lenbe[8];
    uint8_t pad_byte = 0x80u;
    uint8_t zero_byte = 0x00u;
    int i;

    /* Padding (FIPS 180-4 5.1.1): a 1 bit, then zeros until the block
     * has exactly 8 bytes free, then the message length in bits as a
     * 64-bit big-endian integer. */
    og_sha256_update(ctx, &pad_byte, 1);
    while (ctx->block_len != 56u) {
        og_sha256_update(ctx, &zero_byte, 1);
    }
    for (i = 0; i < 8; i++) {
        lenbe[i] = (uint8_t)(bit_len >> (56 - 8 * i));
    }
    og_sha256_update(ctx, lenbe, 8);

    /* The state words are the digest, serialised big-endian. */
    for (i = 0; i < 8; i++) {
        out[4 * i]     = (uint8_t)(ctx->h[i] >> 24);
        out[4 * i + 1] = (uint8_t)(ctx->h[i] >> 16);
        out[4 * i + 2] = (uint8_t)(ctx->h[i] >> 8);
        out[4 * i + 3] = (uint8_t)(ctx->h[i]);
    }

    memset(ctx, 0, sizeof *ctx);
}

void og_sha256(const void *data, size_t len,
               uint8_t out[OG_SHA256_DIGEST_LEN])
{
    og_sha256_ctx ctx;

    og_sha256_init(&ctx);
    og_sha256_update(&ctx, data, len);
    og_sha256_final(&ctx, out);
}

void og_sha256_hex(const uint8_t digest[OG_SHA256_DIGEST_LEN], char out[65])
{
    static const char HEXDIGITS[] = "0123456789abcdef";
    int i;

    for (i = 0; i < OG_SHA256_DIGEST_LEN; i++) {
        out[2 * i] = HEXDIGITS[(digest[i] >> 4) & 0x0f];
        out[2 * i + 1] = HEXDIGITS[digest[i] & 0x0f];
    }
    out[64] = '\0';
}

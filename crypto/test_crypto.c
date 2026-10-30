/*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 */
/*
 * test_crypto.c -- known-answer tests for the z3-og crypto module.
 *
 * Every check compares against a hard-coded expected digest and prints
 * one PASS/FAIL line; the process exits non-zero if any check fails.
 *
 * Provenance of the expected values:
 *  - SHA-256: the FIPS 180-4 example messages and their published
 *    digests (also reproduced in every conforming implementation).
 *  - HMAC-SHA256: RFC 4231 test cases 1, 2 and 6.
 *  - Merkle roots: derived from the og_merkle.h layout spec with an
 *    INDEPENDENT tool -- the system sha256sum -- before the C code was
 *    written, so the C implementation is checked against the spec, not
 *    against itself. Method: build the exact byte string the spec
 *    names (tag byte, 8-byte big-endian length, payload; node's input
 *    is the hex of its children decoded back to bytes) and hash it.
 *    Concretely, with h(x) = "pack hex x to bytes, pipe to sha256sum":
 *      leaf("a") = h(00 || 0000000000000001 || 61)
 *                = 8b19d7b3...95d7a  (cross-checked by hashing the same
 *                  bytes produced with printf octal escapes: identical)
 *      root[1 leaf]  = leaf("a")
 *      root[2 leaf]  = h(01 || leaf("a") || leaf("b"))
 *      root[3 leaf]  = h(01 || root-of-pair(a,b) || leaf("c"))
 *                      because leaf "c" is promoted unchanged.
 *    If a Merkle check fails, the bug is in og_merkle.c (or in this
 *    derivation, which can be re-run with the commands above); the
 *    constants here are the spec, stated as data.
 */
#include <stdio.h>
#include <string.h>

#include "og_hmac.h"
#include "og_merkle.h"
#include "og_sha256.h"

static int g_checks = 0;
static int g_failures = 0;

static void check_digest(const char *name, const uint8_t got[32],
                         const char *want_hex)
{
    char got_hex[65];

    og_sha256_hex(got, got_hex);
    g_checks++;
    if (strcmp(got_hex, want_hex) == 0) {
        printf("PASS %s\n", name);
    } else {
        printf("FAIL %s\n  got  %s\n  want %s\n", name, got_hex, want_hex);
        g_failures++;
    }
}

static void check_hex(const char *name, const char *got_hex,
                      const char *want_hex)
{
    g_checks++;
    if (strcmp(got_hex, want_hex) == 0) {
        printf("PASS %s\n", name);
    } else {
        printf("FAIL %s\n  got  %s\n  want %s\n", name, got_hex, want_hex);
        g_failures++;
    }
}

static void test_sha256(void)
{
    uint8_t d[OG_SHA256_DIGEST_LEN];
    og_sha256_ctx ctx;
    static const char MSG56[] =
        "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq";
    size_t i;

    og_sha256("", 0, d);
    check_digest("sha256 empty string", d,
                 "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855");

    og_sha256("abc", 3, d);
    check_digest("sha256 \"abc\"", d,
                 "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");

    /* The 56-byte FIPS message: long enough that the padding spills
     * into a second block, exercising the wrap in og_sha256_final. */
    og_sha256(MSG56, 56, d);
    check_digest("sha256 56-byte FIPS message", d,
                 "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1");

    /* Streaming must equal one-shot: feed "abc" one byte at a time. */
    og_sha256_init(&ctx);
    og_sha256_update(&ctx, "a", 1);
    og_sha256_update(&ctx, "b", 1);
    og_sha256_update(&ctx, "c", 1);
    og_sha256_final(&ctx, d);
    check_digest("sha256 streaming \"abc\" byte-by-byte", d,
                 "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");

    /* Streaming with odd chunk sizes across a block boundary. */
    og_sha256_init(&ctx);
    for (i = 0; i < 56; i += 7) {
        og_sha256_update(&ctx, MSG56 + i, 7);
    }
    og_sha256_final(&ctx, d);
    check_digest("sha256 streaming 56-byte message in 7-byte chunks", d,
                 "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1");
}

static void test_hmac(void)
{
    uint8_t d[OG_HMAC_SHA256_LEN];
    uint8_t key1[20];
    uint8_t key6[131];
    static const char DATA6[] =
        "Test Using Larger Than Block-Size Key - Hash Key First";
    og_hmac_sha256_ctx ctx;

    /* RFC 4231 test case 1: key = 0x0b x 20, data = "Hi There". */
    memset(key1, 0x0b, sizeof key1);
    og_hmac_sha256(key1, sizeof key1, "Hi There", 8, d);
    check_digest("hmac-sha256 RFC4231 case 1", d,
                 "b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7");

    /* RFC 4231 test case 2: key = "Jefe",
     * data = "what do ya want for nothing?". */
    og_hmac_sha256((const uint8_t *)"Jefe", 4,
                   "what do ya want for nothing?", 28, d);
    check_digest("hmac-sha256 RFC4231 case 2", d,
                 "5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843");

    /* RFC 4231 test case 6: key = 0xaa x 131 (longer than the block,
     * so the key itself is hashed first). */
    memset(key6, 0xaa, sizeof key6);
    og_hmac_sha256(key6, sizeof key6, DATA6, strlen(DATA6), d);
    check_digest("hmac-sha256 RFC4231 case 6 (long key)", d,
                 "60e431591ee0b67f0d8a26aacbf5b77f8e0bc6213728c5140546040f0ee37f54");

    /* Streaming HMAC must equal one-shot for case 2. */
    og_hmac_sha256_init(&ctx, (const uint8_t *)"Jefe", 4);
    og_hmac_sha256_update(&ctx, "what do ya want ", 16);
    og_hmac_sha256_update(&ctx, "for nothing?", 12);
    og_hmac_sha256_final(&ctx, d);
    check_digest("hmac-sha256 streaming RFC4231 case 2", d,
                 "5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843");
}

static void test_merkle(void)
{
    uint8_t root[OG_MERKLE_ROOT_LEN];
    char root_hex[65];
    og_merkle_leaf one[1];
    og_merkle_leaf two[2];
    og_merkle_leaf three[3];
    int rc;

    one[0].data = (const uint8_t *)"a";   one[0].len = 1;
    two[0] = one[0];
    two[1].data = (const uint8_t *)"b";   two[1].len = 1;
    three[0] = two[0];
    three[1] = two[1];
    three[2].data = (const uint8_t *)"c"; three[2].len = 1;

    /* Empty tree root = SHA256(""). */
    rc = og_merkle_root(NULL, 0, root);
    if (rc != 0) {
        g_checks++;
        printf("FAIL merkle empty tree: og_merkle_root returned %d\n", rc);
        g_failures++;
    } else {
        check_digest("merkle root of empty tree", root,
                     "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855");
    }

    rc = og_merkle_root(one, 1, root);
    if (rc != 0) {
        g_checks++;
        printf("FAIL merkle 1 leaf: og_merkle_root returned %d\n", rc);
        g_failures++;
    } else {
        check_digest("merkle root of 1 leaf (\"a\")", root,
                     "8b19d7b3c8681f11ff11a3efc5496f59fd3581c65fec123e42c2f5fb17295d7a");
    }

    rc = og_merkle_root(two, 2, root);
    if (rc != 0) {
        g_checks++;
        printf("FAIL merkle 2 leaves: og_merkle_root returned %d\n", rc);
        g_failures++;
    } else {
        check_digest("merkle root of 2 leaves (\"a\",\"b\")", root,
                     "b3a32b93b5455c27f25f0f12725bc8bd8a0232280102bb1227a941243bbebb2d");
    }

    rc = og_merkle_root(three, 3, root);
    if (rc != 0) {
        g_checks++;
        printf("FAIL merkle 3 leaves: og_merkle_root returned %d\n", rc);
        g_failures++;
    } else {
        check_digest("merkle root of 3 leaves (\"a\",\"b\",\"c\")", root,
                     "e5b6e45c7a36c2b9cfa73be7a230b7b65c0c78bd0cec99445d5f080b5d2c6646");
    }

    /* The hex entry point must agree with the byte entry point. */
    rc = og_merkle_root_hex(three, 3, root_hex);
    if (rc != 0) {
        g_checks++;
        printf("FAIL merkle hex: og_merkle_root_hex returned %d\n", rc);
        g_failures++;
    } else {
        check_hex("merkle root hex of 3 leaves", root_hex,
                  "e5b6e45c7a36c2b9cfa73be7a230b7b65c0c78bd0cec99445d5f080b5d2c6646");
    }
}

int main(void)
{
    test_sha256();
    test_hmac();
    test_merkle();

    printf("---\n%d checks, %d failures\n", g_checks, g_failures);
    if (g_failures != 0) {
        printf("RESULT: FAIL\n");
        return 1;
    }
    printf("RESULT: ALL PASS\n");
    return 0;
}

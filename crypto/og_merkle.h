/*
 * og_merkle.h -- Merkle tree root over byte-string leaves, hand-rolled
 * in C11 for the z3-og clean stack.
 *
 * The tree commits to an ordered list of assertion records: the root is
 * the ledger head that checkpoints sign. The construction uses domain
 * separation (distinct tags for leaves and internal nodes) in the
 * spirit of the single-header merklecpp design, but this code is an
 * original C11 implementation written for z3-og; nothing is copied.
 *
 * SERIALISATION RULE (endianness-agnostic): the only multi-byte
 * quantity ever fed to the hash is the leaf length, and it is always
 * serialised as an 8-byte BIG-ENDIAN integer, constructed byte by byte
 * with shifts -- never by copying a host integer. A tree root therefore
 * does not depend on the byte order of the machine computing it; a
 * little-endian and a big-endian host derive identical roots for the
 * same ledger. This is the rule the merkle-Root line of work states as
 * "make serialisation endianness agnostic", applied to our own layout.
 *
 * Hash layout:
 *   leaf hash     = SHA256( 0x00 || len64be || data )
 *   internal node = SHA256( 0x01 || left32 || right32 )
 *   odd node at a level is promoted unchanged to the next level
 *   empty tree    = SHA256( "" )  (digest of the empty input)
 */
#ifndef OG_MERKLE_H
#define OG_MERKLE_H

#include <stddef.h>
#include <stdint.h>

#include "og_sha256.h"

#define OG_MERKLE_ROOT_LEN OG_SHA256_DIGEST_LEN

/* One leaf: a byte string. data may be NULL only when len is 0. */
typedef struct {
    const uint8_t *data;
    size_t len;
} og_merkle_leaf;

/* Compute the Merkle root of leaves[0..count) into out.
 * count may be 0 (leaves may then be NULL) giving the empty-tree root.
 * Returns 0 on success, -1 if a scratch allocation failed. */
int og_merkle_root(const og_merkle_leaf *leaves, size_t count,
                   uint8_t out[OG_MERKLE_ROOT_LEN]);

/* Same computation, rendered as 64 lowercase hex digits plus NUL.
 * Returns 0 on success, -1 on allocation failure (out then holds the
 * empty string). */
int og_merkle_root_hex(const og_merkle_leaf *leaves, size_t count,
                       char out[65]);

#endif /* OG_MERKLE_H */

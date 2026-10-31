# Dee Mirror Maze — MixColumns as a braided loom, in two fields

The AES MixColumns transform read as a physical weave: each state column
travels through fixed Galois strands — a 02 strand (xtime), a 03 strand
(xtime ⊕ self), two 01 pass strands — and the inverse transform is the
mirror traversal back through the loom. This directory holds the design
in every form it exists in the stack: the production C code (in
`crypto/`), the terminal front ends, the Goldilocks backend, the team
page, and the formal-verification attempt — each with its verification
status stated plainly.


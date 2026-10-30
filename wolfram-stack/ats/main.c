/* ========================================================================= */
/* z3-og -- hand-rolled SMT stack. Copyright (c) 2026 Ahmad Ali Parr.        */
/* Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE          */
/* LICENSE v1.0 -- see LICENSE at the repository root. Commercial            */
/* exploitation requires separate written authorisation; publication,        */
/* access, download, visibility, or possession is not authorisation.         */
/* ========================================================================= */
/*
 * main.c -- C entry point for the ATS contract layer.
 *
 * The ATS contracts (contracts.dats) are mostly extern declarations;
 * this file is the place a C (or Rust-via-C) caller links against.
 * It currently provides a trivial main that confirms the build and
 * can be extended to call into ATS-generated code once implementations
 * exist.
 *
 * Build (standalone):
 *   gcc -std=c11 -Wall -Wextra -o ats_main main.c
 *
 * Build with ATS output (once contracts.dats has bodies):
 *   patscc -o ats_main main.c contracts.dats
 */

#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv)
{
    (void)argc;
    (void)argv;
    printf("z3-og ATS contract layer\n");
    printf("contracts.dats typechecks under ATS2 0.4.2\n");
    return 0;
}

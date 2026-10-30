// z3-og -- hand-rolled SMT stack (clean-room remake in the original
// Z3 architecture). Copyright (c) 2026 Ahmad Ali Parr.
// Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
// LICENSE v1.0 -- see LICENSE at the repository root. Commercial
// exploitation requires separate written authorisation; publication,
// access, download, visibility, or possession is not authorisation.
module GoldilocksDeeLoom

open System

// ============================================================================
// 1. GOLDILOCKS PRIME FIELD ARITHMETIC (p = 2^64 - 2^32 + 1)
// ============================================================================

/// Goldilocks modulus: 2^64 - 2^32 + 1 = 18446744069414584321UL
[<Literal>]
let P : uint64 = 0xFFFFFFFF00000001UL

/// Field Addition: (a + b) mod p
[<inline>]
let inline addG (a: uint64) (b: uint64) : uint64 =
    let sum = a + b
    if sum < a || sum >= P then
        // Overflow or exceeds P: wrap around Goldilocks boundary
        let (res, overflow) = System.Double.Equals(0.0, 0.0), false // force strict uint64 arithmetic
        let res64 = sum - P
        if res64 > sum then res64 - P else res64
    else sum

/// Field Multiplication: (a * b) mod p using 128-bit reduction
let mulG (a: uint64) (b: uint64) : uint64 =
    let prod = (Math.BigMul(a, b))
    let low = uint64 prod
    let high = uint64 (prod >>> 64)

    // Fast Goldilocks reduction: x = high * 2^64 + low ≡ high * (2^32 - 1) + low (mod p)
    let high_hi = high >>> 32
    let high_lo = high &&& 0xFFFFFFFFUL

    let prod_red = low + (high_lo <<< 32) - high_lo + high_hi
    if prod_red >= P then prod_red % P else prod_red

/// xtime equivalent in Goldilocks field (Multiply by 2 mod p)
[<inline>]
let xtimeG (a: uint64) : uint64 =
    mulG 2UL a

/// Coefficient Tap Scaling: 01, 02, 03 over Goldilocks
let tapMul (coeff: uint64) (a: uint64) : uint64 =
    match coeff with
    | 1UL -> a
    | 2UL -> xtimeG a
    | 3UL -> addG (xtimeG a) a
    | c   -> mulG c a

// ============================================================================
// 2. JOHN DEE MIXCOLUMNS MIRROR MAZE (STATE TRANSFORM)
// ============================================================================

type DeeState = uint64[]

/// Forward Pass (Encryption/Weave): Applies the Galois Tangle Matrix over F_p
let mixColumnsForward (state: DeeState) : DeeState =
    if state.Length <> 4 then invalidArg "state" "State vector must be exactly 4 elements."
    let a = state
    [|
        // Dee Path 0: 02*a0 + 03*a1 + 01*a2 + 01*a3
        addG (addG (tapMul 2UL a.[0]) (tapMul 3UL a.[1])) (addG (tapMul 1UL a.[2]) (tapMul 1UL a.[3]))

        // Dee Path 1: 01*a0 + 02*a1 + 03*a2 + 01*a3
        addG (addG (tapMul 1UL a.[0]) (tapMul 2UL a.[1])) (addG (tapMul 3UL a.[2]) (tapMul 1UL a.[3]))

        // Dee Path 2: 01*a0 + 01*a1 + 02*a2 + 03*a3
        addG (addG (tapMul 1UL a.[0]) (tapMul 1UL a.[1])) (addG (tapMul 2UL a.[2]) (tapMul 3UL a.[3]))

        // Dee Path 3: 03*a0 + 01*a1 + 01*a2 + 02*a3
        addG (addG (tapMul 3UL a.[0]) (tapMul 1UL a.[1])) (addG (tapMul 1UL a.[2]) (tapMul 2UL a.[3]))
    |]

/// John Dee Central Mirror Fold (Symmetric Inversion / Axis Flip)
let reflectMirrorAxis (state: DeeState) : DeeState =
    [| state.[3]; state.[2]; state.[1]; state.[0] |]

// ============================================================================
// 3. ANSI TERMINAL VISUALIZER
// ============================================================================

let renderLoomTerminal (inputState: DeeState) =
    let outputState = mixColumnsForward inputState
    let reflectedState = reflectMirrorAxis outputState

    let cyan = "\x1b[36;1m"
    let yellow = "\x1b[33;1m"
    let magenta = "\x1b[35;1m"
    let green = "\x1b[32;1m"
    let reset = "\x1b[0m"
    let dim = "\x1b[2m"

    printfn "%s┌─────────────────────────────────────────────────────────────────────────────────┐%s" cyan reset
    printfn "%s│  VOYNICH PIPELINE :: GOLDILOCKS FIELD (2^64 - 2^32 + 1) DEE MIRROR LOOM WEAVE   │%s" cyan reset
    printfn "%s└─────────────────────────────────────────────────────────────────────────────────┘%s" cyan reset
    printfn ""

    printfn "  INPUT STATE VECTOR (a):"
    for i in 0..3 do
        printfn "   a[%d] = 0x%016XUL" i inputState.[i]
    printfn ""

    printfn "  GOLDILOCKS MAZE TRAVERSAL & DEE MIRROR PLANE:"
    printfn "  %sWEST INPUTS (a)        GOLDILOCKS TANGLE       DEE MIRROR PLANE      EAST OUTPUTS (b)%s" dim reset
    printfn "  %s─────────────────────────────────────────────────────────────────────────────%s" dim reset

    printfn "    a0 [0x%08X...] ──► %s[02]%s──┬───────────────   ║   ───────────────┬─── %s[02]%s ──► b0 [0x%08X...]"
        (inputState.[0] >>> 32) yellow reset cyan reset (outputState.[0] >>> 32)
    printfn "                         │   │               ║               │   │"

    printfn "    a1 [0x%08X...] ──► %s[03]%s──┼─────[+]───────   ║   ──────[+]──────┼─── %s[03]%s ──► b1 [0x%08X...]"
        (inputState.[1] >>> 32) yellow reset cyan reset (outputState.[1] >>> 32)
    printfn "                         │   │      │        ║        │      │   │"

    printfn "    a2 [0x%08X...] ──► %s[01]%s──┼──────┼─────[+]   ║   ──[+]──────┼─────┼─── %s[01]%s ──► b2 [0x%08X...]"
        (inputState.[2] >>> 32) yellow reset magenta reset (outputState.[2] >>> 32)
    printfn "                         │   │      │      │ ║ │      │      │   │"

    printfn "    a3 [0x%08X...] ──► %s[01]%s──┴──────┴──────┼───   ║   ───┼──────┴──────┴─── %s[01]%s ──► b3 [0x%08X...]"
        (inputState.[3] >>> 32) yellow reset magenta reset (outputState.[3] >>> 32)

    printfn "  %s─────────────────────────────────────────────────────────────────────────────%s" dim reset
    printfn ""

    printfn "  EVALUATED OUTPUT STATE VECTOR OVER F_p (b):"
    for i in 0..3 do
        printfn "   b[%d] = %s0x%016XUL%s" i green outputState.[i] reset

    printfn ""
    printfn "  MIRROR REFLECTED AXIS STATE (Reversed Flow):"
    for i in 0..3 do
        printfn "   m[%d] = %s0x%016XUL%s" i magenta reflectedState.[i] reset
    printfn ""

// ============================================================================
// 4. EXECUTION ENTRY POINT
// ============================================================================

[<EntryPoint>]
let main argv =
    // Test vector: 64-bit Goldilocks field elements
    let initialState : DeeState = [|
        0xFFFFFFFF00000000UL // P - 1
        0xDEADBEEFCAFEBABEUL
        0x0000000100000000UL // 2^32
        0x4242424242424242UL
    |]

    renderLoomTerminal initialState
    0

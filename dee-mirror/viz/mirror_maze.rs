// z3-og -- hand-rolled SMT stack (clean-room remake in the original
// Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
// Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
// LICENSE v1.0 -- see LICENSE at the repository root. Commercial
// exploitation requires separate written authorisation; publication,
// access, download, visibility, or possession is not authorisation.
// John Dee MixColumns Mirror Maze Terminal Visualizer
// Zero-dependency Rust terminal renderer for GF(2^8) Galois Loom

use std::fmt;

// Core GF(2^8) xtime operation (Multiply by 02 in GF(2^8) modulo 0x11B)
#[inline]
fn xtime(a: u8) -> u8 {
    if (a & 0x80) != 0 {
        (a << 1) ^ 0x1B
    } else {
        a << 1
    }
}

// Galois Field Multiplication: 01, 02, 03
fn gf_mul(coeff: u8, byte: u8) -> u8 {
    match coeff {
        0x01 => byte,
        0x02 => xtime(byte),
        0x03 => xtime(byte) ^ byte,
        _ => 0,
    }
}

pub struct MirrorMazeVisualizer {
    pub input_vector: [u8; 4],
    pub show_binary: bool,
}

impl MirrorMazeVisualizer {
    pub fn new(a0: u8, a1: u8, a2: u8, a3: u8) -> Self {
        Self {
            input_vector: [a0, a1, a2, a3],
            show_binary: false,
        }
    }

    pub fn compute_output(&self) -> [u8; 4] {
        let a = self.input_vector;
        [
            gf_mul(0x02, a[0]) ^ gf_mul(0x03, a[1]) ^ gf_mul(0x01, a[2]) ^ gf_mul(0x01, a[3]),
            gf_mul(0x01, a[0]) ^ gf_mul(0x02, a[1]) ^ gf_mul(0x03, a[2]) ^ gf_mul(0x01, a[3]),
            gf_mul(0x01, a[0]) ^ gf_mul(0x01, a[1]) ^ gf_mul(0x02, a[2]) ^ gf_mul(0x03, a[3]),
            gf_mul(0x03, a[0]) ^ gf_mul(0x01, a[1]) ^ gf_mul(0x01, a[2]) ^ gf_mul(0x02, a[3]),
        ]
    }

    pub fn render_ansi(&self) {
        let a = self.input_vector;
        let b = self.compute_output();

        // ANSI Color Schemes
        let reset = "\x1b[0m";
        let cyan = "\x1b[36;1m";
        let yellow = "\x1b[33;1m";
        let magenta = "\x1b[35;1m";
        let green = "\x1b[32;1m";
        let dim = "\x1b[2m";
        let bold_white = "\x1b[37;1m";

        println!("\x1b[2J\x1b[H"); // Clear screen & position at origin
        println!("{}┌─────────────────────────────────────────────────────────────────────────────────┐{}", cyan, reset);
        println!("{}│  VOYNICH PIPELINE :: JOHN DEE MIXCOLUMNS MIRROR MAZE (GF(2^8) LOOM WEAVE)       │{}", cyan, reset);
        println!("{}└─────────────────────────────────────────────────────────────────────────────────┘{}", cyan, reset);
        println!();

        // Display Inputs
        println!(" {}INPUT STATE VECTOR (a):{}", bold_white, reset);
        for i in 0..4 {
            println!("  a[{}] = 0x{:02X}  ({}{:08b}{})", i, a[i], dim, a[i], reset);
        }
        println!();

        // Draw Weaver Grid with Mirror Axis
        println!(" {}GALOIS TANGLE MAZE & DEE MIRROR PLANE:{}", bold_white, reset);
        println!(" {}        WEST INPUTS        GALOIS WEAVE      DEE MIRROR PLANE      EAST OUTPUTS{}", dim, reset);
        println!(" {}─────────────────────────────────────────────────────────────────────────────{}", dim, reset);

        // Row 0
        println!("   a0 [0x{:02X}] ───► {}[02]{}──┬───{}───────────{}   ║   {}───────────{}──┬─── {}[02]{} ───► b0 [0x{:02X}]",
            a[0], yellow, reset, cyan, reset, cyan, reset, green, reset, b[0]);
        println!("                     │   │               ║               │   │");

        // Row 1
        println!("   a1 [0x{:02X}] ───► {}[03]{}──┼───{}──[XOR]──────{}   ║   {}──────[XOR]───{}┼─── {}[03]{} ───► b1 [0x{:02X}]",
            a[1], yellow, reset, cyan, reset, cyan, reset, green, reset, b[1]);
        println!("                     │   │     │         ║         │     │   │");

        // Row 2
        println!("   a2 [0x{:02X}] ───► {}[01]{}──┼─────┼──────[⊕]──{}   ║   {}──[⊕]──────┼─────{}┼─── {}[01]{} ───► b2 [0x{:02X}]",
            a[2], yellow, reset, magenta, reset, magenta, reset, green, reset, b[2]);
        println!("                     │   │     │      │  ║  │      │     │   │");

        // Row 3
        println!("   a3 [0x{:02X}] ───► {}[01]{}──┴─────┴──────┼───{}   ║   {}───┼──────┴─────┴─── {}[01]{} ───► b3 [0x{:02X}]",
            a[3], yellow, reset, magenta, reset, magenta, reset, green, reset, b[3]);

        println!(" {}─────────────────────────────────────────────────────────────────────────────{}", dim, reset);
        println!();

        // Output Intermediates Matrix
        println!(" {}POLYNOMIAL COEFFICIENT MATRIX OVER GF(2^8):{}", bold_white, reset);
        println!("   │ 0x02  0x03  0x01  0x01 │   │ a0 [0x{:02X}] │   │ b0 [0x{:02X}] │", a[0], b[0]);
        println!("   │ 0x01  0x02  0x03  0x01 │ * │ a1 [0x{:02X}] │ = │ b1 [0x{:02X}] │", a[1], b[1]);
        println!("   │ 0x01  0x01  0x02  0x03 │   │ a2 [0x{:02X}] │ = │ b2 [0x{:02X}] │", a[2], b[2]);
        println!("   │ 0x03  0x01  0x01  0x02 │   │ a3 [0x{:02X}] │ = │ b3 [0x{:02X}] │", a[3], b[3]);
        println!();

        println!(" {}TRANSFORMATION DETAILED TRACE (ROW 0):{}", bold_white, reset);
        let term1 = gf_mul(0x02, a[0]);
        let term2 = gf_mul(0x03, a[1]);
        let term3 = gf_mul(0x01, a[2]);
        let term4 = gf_mul(0x01, a[3]);
        println!("   0x02*a0 = 0x{:02X} | 0x03*a1 = 0x{:02X} | 0x01*a2 = 0x{:02X} | 0x01*a3 = 0x{:02X}", term1, term2, term3, term4);
        println!("   Result b0 = 0x{:02X} ^ 0x{:02X} ^ 0x{:02X} ^ 0x{:02X} = {}0x{:02X}{}", term1, term2, term3, term4, green, b[0], reset);
        println!();
    }
}

fn main() {
    // Example test vector: AES State Column [0xDB, 0x13, 0x53, 0x45]
    let viz = MirrorMazeVisualizer::new(0xDB, 0x13, 0x53, 0x45);
    viz.render_ansi();
}

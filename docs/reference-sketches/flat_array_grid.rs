// z3-og -- hand-rolled SMT stack (clean-room remake in the original
// Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
// Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
// LICENSE v1.0 -- see LICENSE at the repository root. Commercial
// exploitation requires separate written authorisation; publication,
// access, download, visibility, or possession is not authorisation.
#![no_std]

pub const GRID_SIZE: usize = 1024;
pub const WORD_COUNT: usize = GRID_SIZE / 64; // Pack cells into 64-bit words for SIMD-like bitwise parallelism

pub struct FlatArrayGrid {
    pub cells: [u64; WORD_COUNT],
    pub next_cells: [u64; WORD_COUNT],
}

impl FlatArrayGrid {
    /// Initialize with a single bit set in the center (Wolfram Rule style)
    pub fn new_centered() -> Self {
        let mut grid = Self {
            cells: [0; WORD_COUNT],
            next_cells: [0; WORD_COUNT],
        };
        grid.cells[WORD_COUNT / 2] = 1 << 32;
        grid
    }

    /// Evaluates an elementary cellular automaton rule (e.g., Rule 30 or Rule 110)
    /// across the flat array using packed 64-bit word operations and boundary shifts.
    pub fn step_wolfram_rule(&mut self, rule: u8) {
        for i in 0..WORD_COUNT {
            let left = if i > 0 { self.cells[i - 1] } else { 0 };
            let curr = self.cells[i];
            let right = if i < WORD_COUNT - 1 { self.cells[i + 1] } else { 0 };

            // Extract left and right neighbor bits across word boundaries using shifts
            let l_neighbor = (curr << 1) | (left >> 63);
            let r_neighbor = (curr >> 1) | (right << 63);

            let mut word_res: u64 = 0;

            // Evaluate the 3-neighborhood rule across all 64 bit-positions in parallel
            for bit in 0..64 {
                let mask = 1u64 << bit;
                let l_bit = if (l_neighbor & mask) != 0 { 4 } else { 0 };
                let c_bit = if (curr & mask) != 0 { 2 } else { 0 };
                let r_bit = if (r_neighbor & mask) != 0 { 1 } else { 0 };

                let neighborhood = l_bit | c_bit | r_bit;
                if (rule & (1 << neighborhood)) != 0 {
                    word_res |= mask;
                }
            }

            self.next_cells[i] = word_res;
        }

        // Swap buffers in place (zero allocation, constant time)
        self.cells = self.next_cells;
    }
}

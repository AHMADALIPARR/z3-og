// z3-og -- hand-rolled SMT stack (clean-room remake in the original
// Z3 architecture). Copyright (c) 2026 Ahmad Ali Parr.
// Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
// LICENSE v1.0 -- see LICENSE at the repository root. Commercial
// exploitation requires separate written authorisation; publication,
// access, download, visibility, or possession is not authorisation.
#![no_std]

//! Caller-owned, allocation-free cellular automata kernels.
//! Bits are little-endian within each u64 word: cell i is bit (i & 63).

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Error {
    Empty,
    BufferTooSmall,
    ShapeOverflow,
    OverlappingBuffers,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Boundary {
    Zero,
    Wrap,
}

#[inline]
pub const fn words_for(cells: usize) -> usize {
    cells / 64 + ((cells % 64 != 0) as usize)
}

#[inline]
fn bit(words: &[u64], index: usize) -> u8 {
    ((words[index >> 6] >> (index & 63)) & 1) as u8
}

#[inline]
fn write_bit(words: &mut [u64], index: usize, value: u8) {
    words[index >> 6] |= (value as u64) << (index & 63);
}

fn validate(src: &[u64], dst: &[u64], cells: usize) -> Result<usize, Error> {
    if cells == 0 { return Err(Error::Empty); }
    let n = words_for(cells);
    if src.len() < n || dst.len() < n { return Err(Error::BufferTooSmall); }
    // Overlap detection is defensive for raw-FFI callers; safe Rust normally prevents aliasing.
    let a = src.as_ptr() as usize;
    let b = dst.as_ptr() as usize;
    let bytes = n.checked_mul(core::mem::size_of::<u64>()).ok_or(Error::ShapeOverflow)?;
    let ae = a.checked_add(bytes).ok_or(Error::ShapeOverflow)?;
    let be = b.checked_add(bytes).ok_or(Error::ShapeOverflow)?;
    if a < be && b < ae { return Err(Error::OverlappingBuffers); }
    Ok(n)
}

/// Apply Wolfram elementary rule 0..=255, simultaneously to all cells.
/// Source and destination must be distinct caller-owned buffers.
pub fn elementary(src: &[u64], dst: &mut [u64], cells: usize, rule: u8, boundary: Boundary) -> Result<(), Error> {
    let n = validate(src, dst, cells)?;
    dst[..n].fill(0);
    for i in 0..cells {
        let l = if i > 0 { bit(src, i - 1) } else if boundary == Boundary::Wrap { bit(src, cells - 1) } else { 0 };
        let c = bit(src, i);
        let r = if i + 1 < cells { bit(src, i + 1) } else if boundary == Boundary::Wrap { bit(src, 0) } else { 0 };
        let neighborhood = (l << 2) | (c << 1) | r;
        write_bit(dst, i, (rule >> neighborhood) & 1);
    }
    Ok(())
}

/// Popcount only the active cells; padding bits are ignored.
pub fn population(words: &[u64], cells: usize) -> Result<u64, Error> {
    if cells == 0 { return Err(Error::Empty); }
    let n = words_for(cells);
    if words.len() < n { return Err(Error::BufferTooSmall); }
    let mut total = 0u64;
    for &w in &words[..n - 1] { total += w.count_ones() as u64; }
    let rem = cells & 63;
    let mask = if rem == 0 { u64::MAX } else { (1u64 << rem) - 1 };
    total += (words[n - 1] & mask).count_ones() as u64;
    Ok(total)
}

/// Two-dimensional Moore-neighborhood Life-like rule.
/// birth and survive are 9-bit masks indexed by neighbor count 0..=8.
/// Flat row-major bit-packed storage; width * height is checked.
pub fn moore(src: &[u64], dst: &mut [u64], width: usize, height: usize, birth: u16, survive: u16, boundary: Boundary) -> Result<(), Error> {
    let cells = width.checked_mul(height).ok_or(Error::ShapeOverflow)?;
    if width == 0 || height == 0 { return Err(Error::Empty); }
    let n = validate(src, dst, cells)?;
    dst[..n].fill(0);
    for y in 0..height {
        for x in 0..width {
            let mut neighbors = 0u8;
            for dy in -1isize..=1 {
                for dx in -1isize..=1 {
                    if dx == 0 && dy == 0 { continue; }
                    let xx = match dx {
                        -1 if x == 0 => if boundary == Boundary::Wrap { width - 1 } else { continue },
                        1 if x + 1 == width => if boundary == Boundary::Wrap { 0 } else { continue },
                        -1 => x - 1,
                        1 => x + 1,
                        _ => x,
                    };
                    let yy = match dy {
                        -1 if y == 0 => if boundary == Boundary::Wrap { height - 1 } else { continue },
                        1 if y + 1 == height => if boundary == Boundary::Wrap { 0 } else { continue },
                        -1 => y - 1,
                        1 => y + 1,
                        _ => y,
                    };
                    neighbors += bit(src, yy * width + xx);
                }
            }
            let alive = bit(src, y * width + x);
            let mask = if alive == 0 { birth } else { survive };
            write_bit(dst, y * width + x, ((mask >> neighbors) & 1) as u8);
        }
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn rule90_single_seed() {
        let src = [0b0000_1000u64];
        let mut dst = [0u64];
        elementary(&src, &mut dst, 8, 90, Boundary::Zero).unwrap();
        assert_eq!(dst[0], 0b0001_0100);
    }

    #[test]
    fn rule30_single_seed() {
        let src = [0b0000_1000u64];
        let mut dst = [0u64];
        elementary(&src, &mut dst, 8, 30, Boundary::Zero).unwrap();
        assert_eq!(dst[0], 0b0001_1100);
    }

    #[test]
    fn rule0_clears_padding() {
        let src = [u64::MAX, u64::MAX];
        let mut dst = [u64::MAX, u64::MAX];
        elementary(&src, &mut dst, 65, 0, Boundary::Wrap).unwrap();
        assert_eq!(dst, [0, 0]);
    }

    #[test]
    fn population_masks_padding() {
        assert_eq!(population(&[u64::MAX, u64::MAX], 65), Ok(65));
    }

    #[test]
    fn blinker() {
        // 5x5, vertical blinker at x=2, rows 1..3.
        let src = [(1u64 << 7) | (1u64 << 12) | (1u64 << 17)];
        let mut dst = [0u64];
        moore(&src, &mut dst, 5, 5, 1 << 3, (1 << 2) | (1 << 3), Boundary::Zero).unwrap();
        assert_eq!(dst[0], (1u64 << 11) | (1u64 << 12) | (1u64 << 13));
    }

    #[test]
    fn buffers_and_shapes() {
        assert_eq!(elementary(&[], &mut [], 1, 30, Boundary::Zero), Err(Error::BufferTooSmall));
        assert_eq!(moore(&[], &mut [], usize::MAX, 2, 0, 0, Boundary::Zero), Err(Error::ShapeOverflow));
    }
}

#[cfg(kani)]
mod proofs {
    use super::*;

    #[kani::proof]
    fn words_for_ceiling() {
        let n: u16 = kani::any();
        let n = n as usize;
        let w = words_for(n);
        assert!(w * 64 >= n);
        assert!(n == 0 || (w - 1) * 64 < n);
    }

    #[kani::proof]
    fn population_ignores_padding() {
        let src: [u64; 2] = kani::any();
        let cells: usize = kani::any();
        kani::assume(cells >= 1 && cells <= 65);
        let p = population(&src, cells).unwrap();
        assert!(p <= cells as u64);
    }

    #[kani::proof]
    fn elementary_output_is_masked() {
        let src: [u64; 1] = kani::any();
        let rule: u8 = kani::any();
        let cells: usize = kani::any();
        kani::assume(cells >= 1 && cells <= 4);
        let mut dst = [u64::MAX];
        elementary(&src, &mut dst, cells, rule, Boundary::Zero).unwrap();
        assert!(dst[0] & !( (1u64 << cells) - 1) == 0);
    }

    #[kani::proof]
    fn zero_rule_clears_all() {
        let src: [u64; 1] = kani::any();
        let cells: usize = kani::any();
        kani::assume(cells >= 1 && cells <= 4);
        let mut dst = [u64::MAX];
        elementary(&src, &mut dst, cells, 0, Boundary::Wrap).unwrap();
        assert_eq!(dst[0], 0);
    }

    #[kani::proof]
    fn moore_zero_masks_zero() {
        let src: [u64; 1] = kani::any();
        let mut dst = [u64::MAX];
        moore(&src, &mut dst, 2, 2, 0, 0, Boundary::Wrap).unwrap();
        assert_eq!(dst[0], 0);
    }

    #[kani::proof]
    fn missing_buffer_rejected() {
        let src: [u64; 0] = [];
        let mut dst: [u64; 0] = [];
        let rule: u8 = kani::any();
        assert_eq!(elementary(&src, &mut dst, 1, rule, Boundary::Zero), Err(Error::BufferTooSmall));
    }
}

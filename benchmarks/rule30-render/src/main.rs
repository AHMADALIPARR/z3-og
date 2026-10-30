use std::io::Write;
use wolfram_flat::{elementary, words_for, Boundary};
fn main() {
    let args: Vec<String> = std::env::args().collect();
    let boundary = if args[1] == "wrap" { Boundary::Wrap } else { Boundary::Zero };
    let seed: usize = args[2].parse().unwrap();
    let cells = 800usize;
    let n = words_for(cells);
    let mut src = vec![0u64; n];
    let mut dst = vec![0u64; n];
    src[seed >> 6] |= 1u64 << (seed & 63);
    let mut out = Vec::with_capacity(cells * cells);
    for _gen in 0..800 {
        for i in 0..cells { out.push(((src[i >> 6] >> (i & 63)) & 1) as u8); }
        elementary(&src, &mut dst, cells, 30, boundary).unwrap();
        std::mem::swap(&mut src, &mut dst);
    }
    std::io::stdout().write_all(&out).unwrap();
}

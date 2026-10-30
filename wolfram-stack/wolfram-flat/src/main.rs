// z3-og -- hand-rolled SMT stack (clean-room remake in the original
// Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
// Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
// LICENSE v1.0 -- see LICENSE at the repository root. Commercial
// exploitation requires separate written authorisation; publication,
// access, download, visibility, or possession is not authorisation.
use std::io::{self, BufRead};
use wolfram_flat::{elementary, moore, population, words_for, Boundary};

fn words(s: &str, count: usize) -> Option<Vec<u64>> {
    let v: Vec<u64> = s.split(',').map(|x| u64::from_str_radix(x, 16)).collect::<Result<_,_>>().ok()?;
    if v.len() != count { return None; }
    Some(v)
}
fn number(s: Option<&str>) -> Option<usize> { s?.parse().ok() }
fn display(v: &[u64]) {
    for (i, w) in v.iter().enumerate() {
        if i != 0 { print!(","); }
        print!("{:016x}", w);
    }
    println!();
}
fn execute(line: &str) -> Result<(), ()> {
    let mut p = line.split_ascii_whitespace();
    let cmd = p.next().ok_or(())?;
    match cmd {
        "E" => {
            let n=number(p.next()).ok_or(())?;
            let rule: u8=p.next().ok_or(())?.parse().map_err(|_| ())?;
            let mode=p.next().ok_or(())?;
            let boundary=match mode {"W"=>Boundary::Wrap,"Z"=>Boundary::Zero,_=>return Err(())};
            if n==0 || n > 10_000_000 {return Err(());}
            let v=words(p.next().ok_or(())?,words_for(n)).ok_or(())?;
            if p.next().is_some(){return Err(());}
            let mut dst=vec![0;v.len()];
            elementary(&v,&mut dst,n,rule,boundary).map_err(|_|())?;
            display(&dst);
        },
        "P" => {
            let n=number(p.next()).ok_or(())?;
            if n==0 || n > 10_000_000 {return Err(());}
            let v=words(p.next().ok_or(())?,words_for(n)).ok_or(())?;
            if p.next().is_some(){return Err(());}
            println!("{}",population(&v,n).map_err(|_|())?);
        },
        "M" => {
            let w=number(p.next()).ok_or(())?;
            let h=number(p.next()).ok_or(())?;
            let birth:u16=p.next().ok_or(())?.parse().map_err(|_|())?;
            let survive:u16=p.next().ok_or(())?.parse().map_err(|_|())?;
            let mode=p.next().ok_or(())?;
            let boundary=match mode {"W"=>Boundary::Wrap,"Z"=>Boundary::Zero,_=>return Err(())};
            let n=w.checked_mul(h).ok_or(())?;
            if n==0 || n>10_000_000 || birth>511 || survive>511 {return Err(());}
            let v=words(p.next().ok_or(())?,words_for(n)).ok_or(())?;
            if p.next().is_some(){return Err(());}
            let mut dst=vec![0;v.len()];
            moore(&v,&mut dst,w,h,birth,survive,boundary).map_err(|_|())?;
            display(&dst);
        },
        _=>return Err(())
    }
    Ok(())
}
fn main() {
    let stdin=io::stdin();
    for line in stdin.lock().lines() {
        match line {
            Ok(s) if execute(&s).is_ok()=>{},
            _=> { eprintln!("ERR: malformed command or invalid kernel arguments"); std::process::exit(2); }
        }
    }
}

#[cfg(test)]
mod adapter_tests {
    use super::*;
    #[test] fn parse_uint() { assert_eq!(number(Some("128")),Some(128)); }
    #[test] fn reject_number() { assert_eq!(number(Some("-2")),None); }
    #[test] fn parse_word() { assert_eq!(words("000000000000000f",1),Some(vec![15])); }
    #[test] fn reject_wrong_count() { assert_eq!(words("01",2),None); }
    #[test] fn reject_invalid_hex() { assert_eq!(words("zz",1),None); }
}

#[cfg(kani)]
mod adapter_proofs {
    use super::*;
    #[kani::proof]
    fn parse_fixed_decimal() {
        assert_eq!(number(Some("128")),Some(128));
    }
    #[kani::proof]
    fn parse_fixed_hex() {
        assert_eq!(words("000000000000000f",1),Some(vec![15]));
    }
}

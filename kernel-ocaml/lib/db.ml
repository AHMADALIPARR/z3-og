(* z3-og -- hand-rolled SMT stack. Copyright (c) 2026 Ahmad Ali Parr.
   Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
   LICENSE v1.0 -- see LICENSE at the repository root. Commercial
   exploitation requires separate written authorisation; publication,
   access, download, visibility, or possession is not authorisation. *)
(* Hash-chained assertion ledger.  See db.mli for the format.
 *
 * The chain hash is FNV-1a over 64 bits: start from the FNV offset
 * basis, then for each byte of the input, xor the byte into the
 * hash and multiply by the FNV prime (all arithmetic mod 2^64,
 * which is exactly how Int64 arithmetic wraps in OCaml).  The
 * input for record i is the hex rendering of the previous hash, a
 * separator byte, and the printed form of the asserted term.
 *
 * This chain is an integrity mechanism (corruption/tamper
 * detection and a total order over assertions), NOT a
 * cryptographic one; cryptographic anchoring lives in the C
 * crypto module of the stack. *)

type record =
  { index : int
  ; term : string
  ; prev_hash : int64
  ; hash : int64
  }

(* 14695981039346656037 unsigned; written in hex because the decimal
   form exceeds the signed int64 range. *)
let fnv_offset_basis = 0xcbf29ce484222325L
let fnv_prime = 1099511628211L

let fnv1a_64 s =
  let h = ref fnv_offset_basis in
  String.iter
    (fun c ->
      h := Int64.mul (Int64.logxor !h (Int64.of_int (Char.code c))) fnv_prime)
    s;
  !h

let hex_of_hash h = Printf.sprintf "%016Lx" h

let chain_hash prev term_printed =
  fnv1a_64 (hex_of_hash prev ^ "|" ^ term_printed)

type t =
  { out : out_channel
  ; mutable count : int
  ; mutable last : int64
  }

let create path =
  { out = open_out path; count = 0; last = 0L }

let append ledger term =
  let printed = Term.to_string term in
  let h = chain_hash ledger.last printed in
  Printf.fprintf ledger.out "%s\t%s\t%s\n" (hex_of_hash h)
    (hex_of_hash ledger.last) printed;
  flush ledger.out;
  ledger.last <- h;
  ledger.count <- ledger.count + 1

let close ledger = close_out ledger.out

let size ledger = ledger.count

let head ledger = ledger.last

(* ---------------------------------------------------------------- *)
(* Loading and verification.                                        *)
(* ---------------------------------------------------------------- *)

let parse_hex s =
  try Some (Int64.of_string ("0x" ^ s)) with _ -> None

(* Verify one raw line at position [idx], given the expected
   previous hash.  Returns the parsed record, or [None] if the line
   is malformed or breaks the chain. *)
let parse_and_check idx expected_prev line =
  match String.split_on_char '\t' line with
  | [ hash_s; prev_s; term ] ->
      (match (parse_hex hash_s, parse_hex prev_s) with
       | Some h, Some p ->
           if p <> expected_prev then None
           else if chain_hash p term <> h then None
           else Some { index = idx; term; prev_hash = p; hash = h }
       | _ -> None)
  | _ -> None

let load path =
  let ic = open_in path in
  let rec loop idx expected_prev acc =
    match input_line ic with
    | line ->
        (match parse_and_check idx expected_prev line with
         | Some r -> loop (idx + 1) r.hash (r :: acc)
         | None ->
             close_in ic;
             Error idx)
    | exception End_of_file ->
        close_in ic;
        Ok (List.rev acc)
  in
  loop 0 0L []

let verify path =
  match load path with
  | Ok records -> Ok (List.length records)
  | Error _ as e -> e

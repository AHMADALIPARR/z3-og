(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Ahmad Ali Parr.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
module SMT.LowExtract

open FStar.UInt32
open FStar.Buffer

(* Flat array representation of expression opcodes for Low* extraction *)
type op_code =
  | OpConst : op_code
  | OpVar   : op_code
  | OpXor   : op_code

(* Flat buffer node representation *)
noeq type flat_node = {
  op: u32;
  left: u32;
  right: u32;
}

(* Low* verified helper: checks if a flat node represents an XOR-false identity *)
val is_xor_false_identity (node: flat_node) : Tot bool
let is_xor_false_identity node =
  // OpXor = 2, OpConst = 0, Constant False = 0
  node.op = 2ul && node.right = 0ul

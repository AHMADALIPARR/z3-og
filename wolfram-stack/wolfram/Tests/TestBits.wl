(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`TestBits[] := And@@{WF`AssertEqual[WF`PackBits[{1,0,1,1}],{13},"pack"],WF`AssertEqual[WF`UnpackBits[{13},4],{1,0,1,1},"unpack"],WF`AssertEqual[WF`BitPut[{0},63,1],{2^63},"put"],WF`AssertEqual[WF`PopCount[{2^64-1,2^64-1},65],65,"padding"],WF`AssertEqual[WF`XorPacked[{15},{10},4],{5},"xor"],WF`AssertEqual[WF`HammingDistance[{15},{10},4],2,"hamming"]}

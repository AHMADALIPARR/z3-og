(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`ParseHexWords[text_String] := Module[{parts=If[text==="",{},StringSplit[StringTrim[text],","]]},If[!VectorQ[parts,StringMatchQ[#,RegularExpression["[0-9a-fA-F]{1,16}"]]&],Return[$Failed]];FromDigits[#,16]&/@parts]

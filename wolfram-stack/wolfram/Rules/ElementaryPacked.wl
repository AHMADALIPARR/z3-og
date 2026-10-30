(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`ElementaryPacked[words_List,n_Integer,rule_Integer,boundary_:"Zero"] := Module[{bits=WF`UnpackBits[words,n],next},If[bits===$Failed,Return[$Failed]];next=WF`ElementaryStep[bits,rule,boundary];If[next===$Failed,$Failed,WF`PackBits[next]]]

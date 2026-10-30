(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`TestIndices[] := And@@{WF`AssertEqual[WF`Strides[{3,4,5}],{20,5,1},"strides"],WF`AssertEqual[WF`RavelIndex[{2,3,4},{3,4,5}],34,"ravel"],WF`AssertEqual[WF`UnravelIndex[34,{3,4,5}],{2,3,4},"unravel"],WF`AssertEqual[WF`RavelIndex[{0,1},{3,4}],$Failed,"range"]}

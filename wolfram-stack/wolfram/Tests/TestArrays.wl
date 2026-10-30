(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`TestArrays[] := And@@{WF`AssertEqual[WF`MapFlat[#^2&,{1,2,3}],{1,4,9},"map"],WF`AssertEqual[WF`ReduceFlat[Plus,0,{1,2,3}],6,"reduce"],WF`AssertEqual[WF`ScanFlat[Plus,0,{1,2,3}],{1,3,6},"scan"],WF`AssertEqual[WF`GatherFlat[{8,7,6},{3,1}],{6,8},"gather"],WF`AssertEqual[WF`ScatterFlat[{0,0,0},{1,3},{4,5}],{4,0,5},"scatter"],WF`AssertEqual[WF`WindowSum[{1,2,3},1],{3,6,5},"window"],WF`AssertEqual[WF`DotFlat[{1,2},{3,4}],11,"dot"],WF`AssertEqual[WF`MatMulFlat[{1,2,3,4},{5,6,7,8},2,2,2],{19,22,43,50},"matmul"]}

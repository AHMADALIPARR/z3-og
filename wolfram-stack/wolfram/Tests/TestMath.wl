(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Ahmad Ali Parr.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`TestMath[] := And@@{WF`AssertEqual[WF`GCDFlat[{48,18,30}],6,"gcd"],WF`AssertEqual[WF`MeanFlat[{1,2,3,4}],5/2,"mean"],WF`AssertEqual[WF`VarianceFlat[{1,2,3}],2/3,"variance"],WF`AssertEqual[WF`PowerInteger[3,5],243,"pow"],WF`AssertEqual[WF`Convolve1D[{1,2,3},{1,1,1}],{3,6,5},"convolution"],WF`AssertEqual[WF`MatVecFlat[{1,2,3,4},{5,6},2,2],{17,39},"matvec"]}

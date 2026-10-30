(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Ahmad Ali Parr.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`PopCount[words_List,cells_Integer] := Module[{n=WF`WordsFor[cells],rem,s=0,i,mask},If[cells<=0||n>Length[words],Return[$Failed]];For[i=1,i<n,i++,s+=DigitCount[BitAnd[words[[i]],2^64-1],2,1]];rem=Mod[cells,64];mask=If[rem==0,2^64-1,2^rem-1];s+DigitCount[BitAnd[words[[n]],mask],2,1]]

(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Ahmad Ali Parr.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`SliceFlat[a_List,start_Integer,count_Integer,stride_Integer:1] := Module[{out={},j,i},If[count<0||stride==0,Return[$Failed]];For[i=0,i<count,i++,j=start+i*stride;If[j<1||j>Length[a],Return[$Failed]];AppendTo[out,a[[j]]]];out]

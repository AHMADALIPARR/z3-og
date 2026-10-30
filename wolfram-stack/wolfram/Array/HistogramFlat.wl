(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`HistogramFlat[a_List,lo_Integer,hi_Integer] := Module[{out,i,v},If[hi<lo,Return[$Failed]];out=ConstantArray[0,hi-lo+1];For[i=1,i<=Length[a],i++,v=a[[i]];If[IntegerQ[v]&&lo<=v<=hi,out[[v-lo+1]]++]];out]

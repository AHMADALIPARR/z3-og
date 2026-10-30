(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Ahmad Ali Parr.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`ScanFlat[f_,initial_,a_List] := Module[{out=Table[Null,{Length[a]}],acc=initial,i},For[i=1,i<=Length[a],i++,acc=f[acc,a[[i]]];out[[i]]=acc];out]

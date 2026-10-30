(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Ahmad Ali Parr.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`Map2Flat[f_,a_List,b_List] /; Length[a]===Length[b] := Module[{n=Length[a],out,i},out=Table[Null,{Length[a]}];For[i=1,i<=n,i++,out[[i]]=f[a[[i]],b[[i]]]];out]
WF`Map2Flat[_,_,_]:=$Failed

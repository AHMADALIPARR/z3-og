(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Ahmad Ali Parr.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`RotateFlat[a_List,k_Integer] := Module[{n=Length[a],out,i,j},If[n==0,Return[{}]];out=Table[Null,{n}];For[i=1,i<=n,i++,j=Mod[i-1-k,n]+1;out[[i]]=a[[j]]];out]

(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Ahmad Ali Parr.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`PrefixMax[a_List] := Module[{out=a,m,i},If[Length[a]==0,Return[{}]];m=a[[1]];For[i=2,i<=Length[a],i++,If[a[[i]]>m,m=a[[i]]];out[[i]]=m];out]

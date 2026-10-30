(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Ahmad Ali Parr.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`LinearShift[a_List,k_Integer,fill_:0] := Module[{n=Length[a],out,i,j},out=ConstantArray[fill,n];For[i=1,i<=n,i++,j=i-k;If[1<=j<=n,out[[i]]=a[[j]]]];out]

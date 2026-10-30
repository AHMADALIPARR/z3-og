(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`Neighbors1D[i_Integer,n_Integer,r_Integer,boundary_:"Zero"] := Module[{out={},j,k},If[n<=0||i<1||i>n||r<0,Return[$Failed]];For[j=-r,j<=r,j++,k=i+j;If[boundary==="Wrap",k=Mod[k-1,n]+1];If[1<=k<=n,AppendTo[out,k]]];out]

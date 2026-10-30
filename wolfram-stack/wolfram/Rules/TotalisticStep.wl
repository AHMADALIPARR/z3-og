(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`TotalisticStep[bits_List,lookup_List,r_Integer,boundary_:"Zero"] := Module[{out,i,j,k,s,n=Length[bits]},If[!WF`ValidateBits[bits]||r<0||Length[lookup]!=2*r+2||!WF`ValidateBits[lookup]||!MemberQ[{"Zero","Wrap"},boundary],Return[$Failed]];out=ConstantArray[0,n];For[i=1,i<=n,i++,s=0;For[j=-r,j<=r,j++,k=i+j;If[boundary==="Wrap"&&n>0,k=Mod[k-1,n]+1];If[1<=k<=n,s+=bits[[k]]]];out[[i]]=lookup[[s+1]]];out]

(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Ahmad Ali Parr.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`ShiftPacked[words_List,n_Integer,offset_Integer,mode_:"Zero"] := Module[{src=WF`UnpackBits[words,n],out,i,j},If[src===$Failed||!MemberQ[{"Zero","Wrap"},mode],Return[$Failed]];out=ConstantArray[0,n];For[i=1,i<=n,i++,j=i-offset;If[mode==="Wrap"&&n>0,j=Mod[j-1,n]+1];If[1<=j<=n,out[[i]]=src[[j]]]];WF`PackBits[out]]

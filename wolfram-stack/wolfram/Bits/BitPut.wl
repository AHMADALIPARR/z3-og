(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Ahmad Ali Parr.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`BitPut[words_List,i_Integer,v_Integer] := Module[{out=words,j,mask},If[i<0||Quotient[i,64]>=Length[words]||!MemberQ[{0,1},v],Return[$Failed]];j=Quotient[i,64]+1;mask=BitShiftLeft[1,Mod[i,64]];out[[j]]=If[v==1,BitOr[out[[j]],mask],BitAnd[out[[j]],BitNot[mask]]];out[[j]]=BitAnd[out[[j]],2^64-1];out]

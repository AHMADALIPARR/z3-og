(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`AndPacked[a_List,b_List,n_Integer] := Module[{k=WF`WordsFor[n],out,i},If[k===$Failed||Length[a]<k||Length[b]<k,Return[$Failed]];out=ConstantArray[0,k];For[i=1,i<=k,i++,out[[i]]=BitAnd[a[[i]],b[[i]]]];If[k>0&&Mod[n,64]!=0,out[[k]]=BitAnd[out[[k]],2^Mod[n,64]-1]];out]

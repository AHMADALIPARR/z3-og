(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`BitRangeExtract[words_List,start_Integer,count_Integer] := Module[{out=ConstantArray[0,Max[0,count]],i,v},If[start<0||count<0||start+count>64*Length[words],Return[$Failed]];For[i=0,i<count,i++,v=WF`BitGet[words,start+i];If[v===$Failed,Return[$Failed]];out[[i+1]]=v];out]
WF`BitRangeExtract[_,_,_]:=$Failed

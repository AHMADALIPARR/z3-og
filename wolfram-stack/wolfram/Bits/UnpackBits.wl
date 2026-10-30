(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Ahmad Ali Parr.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`UnpackBits[words_List,n_Integer] /; n>=0&&Length[words]>=WF`WordsFor[n] := Module[{out=ConstantArray[0,n],i},For[i=0,i<n,i++,out[[i+1]]=WF`BitGet[words,i]];out]
WF`UnpackBits[_,_]:=$Failed

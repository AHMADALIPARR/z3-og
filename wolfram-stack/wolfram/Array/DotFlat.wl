(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`DotFlat[a_List,b_List] /; Length[a]===Length[b] := Module[{s=0,i},For[i=1,i<=Length[a],i++,s+=a[[i]]*b[[i]]];s]
WF`DotFlat[_,_]:=$Failed

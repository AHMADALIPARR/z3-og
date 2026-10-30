(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`GatherFlat[a_List,indices_List] := Module[{out=Table[Null,{Length[indices]}],i,j},For[i=1,i<=Length[indices],i++,j=indices[[i]];If[!IntegerQ[j]||j<1||j>Length[a],Return[$Failed]];out[[i]]=a[[j]]];out]

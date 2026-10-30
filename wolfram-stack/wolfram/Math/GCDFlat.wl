(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`GCDFlat[a_List] := Module[{g=0,i,x,y,t},For[i=1,i<=Length[a],i++,If[!IntegerQ[a[[i]]],Return[$Failed]];x=Abs[g];y=Abs[a[[i]]];While[y!=0,t=Mod[x,y];x=y;y=t];g=x];g]

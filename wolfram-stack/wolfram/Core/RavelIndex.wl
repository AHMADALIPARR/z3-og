(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`RavelIndex[coords_List,shape_List] := Module[{s=WF`Strides[shape]},If[s===$Failed || Length[coords]!=Length[shape] || !And@@MapThread[IntegerQ[#1]&&1<=#1<=#2&,{coords,shape}],Return[$Failed]];1+Total[(coords-1)*s]]

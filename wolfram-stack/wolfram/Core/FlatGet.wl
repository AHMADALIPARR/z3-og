(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`FlatGet[a_Association,coords_List] := Module[{idx},If[!WF`FlatValid[a],Return[$Failed]];idx=WF`RavelIndex[coords,a["Shape"]];If[idx===$Failed,$Failed,a["Data"][[idx]]]]
WF`FlatGet[_,_]:=$Failed

(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Ahmad Ali Parr.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`FlatSet[a_Association,coords_List,v_] := Module[{idx,out,data},If[!WF`FlatValid[a],Return[$Failed]];idx=WF`RavelIndex[coords,a["Shape"]];If[idx===$Failed,Return[$Failed]];data=a["Data"];data[[idx]]=v;out=<|"Shape"->a["Shape"],"Data"->data|>;out]
WF`FlatSet[_,_,_]:=$Failed

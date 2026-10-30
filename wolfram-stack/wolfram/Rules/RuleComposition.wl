(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`RuleComposition[bits_List,rules_List,boundary_:"Zero"] := Module[{state=bits,i},For[i=1,i<=Length[rules],i++,state=WF`ElementaryStep[state,rules[[i]],boundary];If[state===$Failed,Return[$Failed]]];state]

(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`ElementarySpaceTime[seed_List,rule_Integer,steps_Integer,boundary_:"Zero"] := Module[{hist=WF`ElementaryEvolve[seed,rule,steps,boundary]},If[hist===$Failed,$Failed,Flatten[hist]]]

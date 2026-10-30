(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
Get[FileNameJoin[{DirectoryName[$InputFileName],"Load.wl"}]];
results = {WF`TestIndices[], WF`TestArrays[], WF`TestBits[], WF`TestRules[], WF`TestMath[], WF`TestProperties[], WF`TestEveryFunction[]};
Print["Wolfram tests: ",Count[results,True],"/",Length[results]];
If[!And@@results,Exit[1]];
If[Length[$ScriptCommandLine]>1,If[!WF`TestBridge[$ScriptCommandLine[[2]]],Exit[2]]];
Exit[0];

(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`TestRules[] := And@@{WF`AssertEqual[WF`ElementaryStep[{0,0,0,1,0,0,0,0},90],{0,0,1,0,1,0,0,0},"rule90"],WF`AssertEqual[WF`ElementaryStep[{0,0,0,1,0,0,0,0},30],{0,0,1,1,1,0,0,0},"rule30"],WF`AssertEqual[WF`RuleNumber[WF`RuleTable[110]],110,"rule roundtrip"],WF`AssertEqual[WF`LifeStep[ReplacePart[ConstantArray[0,25],{8->1,13->1,18->1}],5,5],ReplacePart[ConstantArray[0,25],{12->1,13->1,14->1}],"life"],WF`AssertEqual[WF`ElementaryPacked[{8},8,90],{20},"packed90"]}

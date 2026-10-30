(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`RustPopulation[words_List,n_Integer,exe_String:"wolfram-flat-cli"] := Module[{hex=WF`HexWords[words],result,s},If[hex===$Failed||n<=0||Length[words]<WF`WordsFor[n],Return[$Failed]];s=StringRiffle[{"P",ToString[n],hex}," "];result=Quiet[Check[RunProcess[{exe},All,s<>"\n"],$Failed]];If[result===$Failed||result["ExitCode"]!=0||!StringMatchQ[StringTrim[result["StandardOutput"]],DigitCharacter..],$Failed,FromDigits[StringTrim[result["StandardOutput"]]]]]

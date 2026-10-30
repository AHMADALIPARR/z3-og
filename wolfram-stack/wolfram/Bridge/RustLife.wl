(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`RustLife[words_List,w_Integer,h_Integer,birth_List:{3},survive_List:{2,3},boundary_:"Zero",exe_String:"wolfram-flat-cli"] := Module[{hex=WF`HexWords[words],maskB,maskS,result,parsed,s},If[hex===$Failed||w<=0||h<=0||Length[words]<WF`WordsFor[w*h]||!SubsetQ[Range[0,8],birth]||!SubsetQ[Range[0,8],survive]||!MemberQ[{"Zero","Wrap"},boundary],Return[$Failed]];maskB=Total[2^birth];maskS=Total[2^survive];s=StringRiffle[{"M",ToString[w],ToString[h],ToString[maskB],ToString[maskS],If[boundary==="Wrap","W","Z"],hex}," "];result=Quiet[Check[RunProcess[{exe},All,s<>"\n"],$Failed]];If[result===$Failed||result["ExitCode"]!=0,Return[$Failed]];parsed=WF`ParseHexWords[StringTrim[result["StandardOutput"]]];If[parsed===$Failed||Length[parsed]!=WF`WordsFor[w*h],$Failed,parsed]]

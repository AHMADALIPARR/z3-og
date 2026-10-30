(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`RustElementary[words_List,n_Integer,rule_Integer,boundary_:"Zero",exe_String:"wolfram-flat-cli"] := Module[{hex=WF`HexWords[words],s,result,parsed},If[hex===$Failed||n<=0||Length[words]<WF`WordsFor[n]||rule<0||rule>255||!MemberQ[{"Zero","Wrap"},boundary],Return[$Failed]];s=StringRiffle[{"E",ToString[n],ToString[rule],If[boundary==="Wrap","W","Z"],hex}," "];result=Quiet[Check[RunProcess[{exe},All,s<>"\n"],$Failed]];If[result===$Failed||result["ExitCode"]!=0,Return[$Failed]];parsed=WF`ParseHexWords[StringTrim[result["StandardOutput"]]];If[parsed===$Failed||Length[parsed]!=WF`WordsFor[n],$Failed,parsed]]

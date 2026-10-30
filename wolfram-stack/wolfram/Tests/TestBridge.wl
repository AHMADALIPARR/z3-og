(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`TestBridge[exe_String:"wolfram-flat-cli"] := Module[{n,rule,bits,words,expected,actual},For[n=1,n<=130,n+=13,bits=Table[Boole[Mod[i*i+2*i+n,5]<2],{i,0,n-1}];words=WF`PackBits[bits];For[rule=0,rule<=255,rule+=17,expected=WF`ElementaryPacked[words,n,rule,"Wrap"];actual=WF`RustElementary[words,n,rule,"Wrap",exe];If[actual=!=expected,Print["FAIL bridge E n=",n," rule=",rule];Return[False]]];If[WF`RustPopulation[words,n,exe]=!=Total[bits],Return[False]]];words=WF`PackBits[ReplacePart[ConstantArray[0,25],{8->1,13->1,18->1}]];WF`RustLife[words,5,5,{3},{2,3},"Zero",exe]===WF`PackBits[ReplacePart[ConstantArray[0,25],{12->1,13->1,14->1}]]]

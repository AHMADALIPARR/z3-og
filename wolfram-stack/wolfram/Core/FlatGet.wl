WF`FlatGet[a_Association,coords_List] := Module[{idx},If[!WF`FlatValid[a],Return[$Failed]];idx=WF`RavelIndex[coords,a["Shape"]];If[idx===$Failed,$Failed,a["Data"][[idx]]]]
WF`FlatGet[_,_]:=$Failed

WF`FlatSet[a_Association,coords_List,v_] := Module[{idx,out,data},If[!WF`FlatValid[a],Return[$Failed]];idx=WF`RavelIndex[coords,a["Shape"]];If[idx===$Failed,Return[$Failed]];data=a["Data"];data[[idx]]=v;out=<|"Shape"->a["Shape"],"Data"->data|>;out]
WF`FlatSet[_,_,_]:=$Failed

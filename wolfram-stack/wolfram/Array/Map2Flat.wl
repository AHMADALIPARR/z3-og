WF`Map2Flat[f_,a_List,b_List] /; Length[a]===Length[b] := Module[{n=Length[a],out,i},out=Table[Null,{Length[a]}];For[i=1,i<=n,i++,out[[i]]=f[a[[i]],b[[i]]]];out]
WF`Map2Flat[_,_,_]:=$Failed

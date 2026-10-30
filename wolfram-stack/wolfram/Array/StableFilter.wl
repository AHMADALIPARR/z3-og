WF`StableFilter[p_,a_List] := Module[{out=Table[Null,{Length[a]}],i,j=0},For[i=1,i<=Length[a],i++,If[TrueQ[p[a[[i]]]],j++;out[[j]]=a[[i]]]];Take[out,j]]

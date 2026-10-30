WF`DotFlat[a_List,b_List] /; Length[a]===Length[b] := Module[{s=0,i},For[i=1,i<=Length[a],i++,s+=a[[i]]*b[[i]]];s]
WF`DotFlat[_,_]:=$Failed

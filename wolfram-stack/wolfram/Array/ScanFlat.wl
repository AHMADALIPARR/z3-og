WF`ScanFlat[f_,initial_,a_List] := Module[{out=Table[Null,{Length[a]}],acc=initial,i},For[i=1,i<=Length[a],i++,acc=f[acc,a[[i]]];out[[i]]=acc];out]

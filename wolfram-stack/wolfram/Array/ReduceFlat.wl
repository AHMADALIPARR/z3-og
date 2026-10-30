WF`ReduceFlat[f_,initial_,a_List] := Module[{acc=initial,i},For[i=1,i<=Length[a],i++,acc=f[acc,a[[i]]]];acc]

WF`ExclusiveScan[f_,seed_,a_List] := Module[{out=Table[Null,{Length[a]}],acc=seed,i},For[i=1,i<=Length[a],i++,out[[i]]=acc;acc=f[acc,a[[i]]]];out]

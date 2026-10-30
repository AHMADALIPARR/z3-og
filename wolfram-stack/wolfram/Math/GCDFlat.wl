WF`GCDFlat[a_List] := Module[{g=0,i,x,y,t},For[i=1,i<=Length[a],i++,If[!IntegerQ[a[[i]]],Return[$Failed]];x=Abs[g];y=Abs[a[[i]]];While[y!=0,t=Mod[x,y];x=y;y=t];g=x];g]

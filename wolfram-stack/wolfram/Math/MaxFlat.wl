WF`MaxFlat[a_List] := Module[{v,i},If[Length[a]==0,Return[$Failed]];v=a[[1]];For[i=2,i<=Length[a],i++,If[a[[i]]>v,v=a[[i]]]];v]

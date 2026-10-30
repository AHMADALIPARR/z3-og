WF`HammingDistance[a_List,b_List,n_Integer] := Module[{c=WF`XorPacked[a,b,n]},If[c===$Failed,$Failed,WF`PopCount[c,n]]]

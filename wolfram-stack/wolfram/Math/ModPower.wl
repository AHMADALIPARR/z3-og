WF`ModPower[b_Integer,e_Integer,m_Integer] /; e>=0&&m>0 := Module[{a=Mod[b,m],k=e,result=Mod[1,m]},While[k>0,If[OddQ[k],result=Mod[result*a,m]];a=Mod[a*a,m];k=Quotient[k,2]];result]
WF`ModPower[_,_,_]:=$Failed

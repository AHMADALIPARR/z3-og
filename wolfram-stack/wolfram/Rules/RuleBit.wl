WF`RuleBit[rule_Integer,left_Integer,center_Integer,right_Integer] /; 0<=rule<=255&&And@@(MemberQ[{0,1},#]&/@{left,center,right}) := BitAnd[BitShiftRight[rule,4*left+2*center+right],1]
WF`RuleBit[_,_,_,_]:=$Failed

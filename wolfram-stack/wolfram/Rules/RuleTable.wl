WF`RuleTable[rule_Integer] /; 0<=rule<=255 := Table[BitAnd[BitShiftRight[rule,i],1],{i,0,7}]
WF`RuleTable[_]:=$Failed

WF`RuleNumber[table_List] /; Length[table]==8&&WF`ValidateBits[table] := Total[table*Table[2^i,{i,0,7}]]
WF`RuleNumber[_]:=$Failed

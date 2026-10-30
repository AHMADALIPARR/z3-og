WF`ValidateBits[a_List] := VectorQ[a, IntegerQ[#] && 0 <= # <= 1 &]

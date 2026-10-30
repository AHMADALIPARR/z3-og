WF`ValidateShape[shape_List] := VectorQ[shape, IntegerQ[#] && # > 0 &]

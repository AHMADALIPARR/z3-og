WF`FlatReshape[a_Association,shape_List] := If[WF`FlatValid[a]&&WF`ValidateShape[shape]&&WF`ShapeSize[shape]===Length[a["Data"]],<|"Shape"->shape,"Data"->a["Data"]|>,$Failed]

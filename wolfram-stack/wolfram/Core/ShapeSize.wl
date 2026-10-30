WF`ShapeSize[shape_List] /; WF`ValidateShape[shape] := Fold[Times, 1, shape]
WF`ShapeSize[_] := $Failed

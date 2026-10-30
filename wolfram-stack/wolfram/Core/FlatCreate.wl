WF`FlatCreate[shape_List,value_:0] /; WF`ValidateShape[shape] := <|"Shape"->shape,"Data"->ConstantArray[value,WF`ShapeSize[shape]]|>
WF`FlatCreate[_,___]:=$Failed

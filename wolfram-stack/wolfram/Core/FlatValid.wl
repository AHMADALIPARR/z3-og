WF`FlatValid[a_Association] := KeyExistsQ[a,"Shape"]&&KeyExistsQ[a,"Data"]&&WF`ValidateShape[a["Shape"]]&&ListQ[a["Data"]]&&Length[a["Data"]]===WF`ShapeSize[a["Shape"]]
WF`FlatValid[_]:=False

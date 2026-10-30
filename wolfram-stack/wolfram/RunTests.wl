Get[FileNameJoin[{DirectoryName[$InputFileName],"Load.wl"}]];
results = {WF`TestIndices[], WF`TestArrays[], WF`TestBits[], WF`TestRules[], WF`TestMath[], WF`TestProperties[], WF`TestEveryFunction[]};
Print["Wolfram tests: ",Count[results,True],"/",Length[results]];
If[!And@@results,Exit[1]];
If[Length[$ScriptCommandLine]>1,If[!WF`TestBridge[$ScriptCommandLine[[2]]],Exit[2]]];
Exit[0];

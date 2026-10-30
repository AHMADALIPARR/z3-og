WF`ElementarySpaceTime[seed_List,rule_Integer,steps_Integer,boundary_:"Zero"] := Module[{hist=WF`ElementaryEvolve[seed,rule,steps,boundary]},If[hist===$Failed,$Failed,Flatten[hist]]]

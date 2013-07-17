function planC = deleteStructure(planC, structNum)
% function planC = deleteStructure(planC, structNum)
%
% Function to delete structure in a batch mode.
%
% APA, 09/25/2012

indexS = planC{end};
len = length(planC{indexS.structures});
planC = delUniformStr(structNum, planC); %Update the uniform data.
planC{indexS.structures}(structNum:len-1) = planC{indexS.structures}(structNum+1:len);
planC{indexS.structures} = planC{indexS.structures}(1:len-1);


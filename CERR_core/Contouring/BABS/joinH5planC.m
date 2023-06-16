function [dataOut3M,physExtentsV,planC] = joinH5planC(scanNum,data3M,labelPath,...
    userOptS,planC)
% function [dataOut3M,planC]  = joinH5planC(scanNum,segMask3M,labelPath,...
%                               userOptS,planC)

if ~exist('planC','var')
    global planC
end
indexS = planC{end};

%% Reverse pre-processing operations
[dataOut3M,physExtentsV,scanNum,planC] = reverseTransformAIOutput(scanNum,data3M,...
    userOptS,planC);

%% Import model output to CERR
outputTypeC = fieldnames(userOptS.output);
outputType = outputTypeC{1};
switch(lower(outputType))

    case 'labelmap'

        % Convert label maps to CERR structs
        labelOptS = userOptS.output.labelMap;
        %Get autosegmented structure names
        [outStrListC,labelMapS] = getAutosegStructnames(labelPath,labelOptS);

        roiGenerationDescription = '';
        if isfield(labelOptS,'roiGenerationDescription')
            roiGenerationDescription = labelOptS.roiGenerationDescription;
        end

        isUniform = 0;
        for i = 1 : length(labelMapS)
            labelVal = labelMapS(i).value;
            maskForStr3M = dataOut3M == labelVal;
            planC = maskToCERRStructure(maskForStr3M, isUniform, scanNum,...
                outStrListC{i}, planC);
            planC{indexS.structures}(end).roiGenerationAlgorithm = 'AUTOMATIC';
            planC{indexS.structures}(end).roiGenerationDescription = roiGenerationDescription;
            planC{indexS.structures}(end).structureDescription = roiGenerationDescription;
        end

    case 'dvf'
        if isfield(userOptS.output.(outputType),'saveToPlanC') &&...
                strcmpi(userOptS.output.(outputType).saveToPlanC,'yes')
            assocScanUID = planC{indexS.scan}(scanNum).scanUID;
            description = labelPath;
            planC = dose2CERR(dataOut3M,[],description,'',description,'CT',[],...
                'no',assocScanUID, planC);
        end
end

end
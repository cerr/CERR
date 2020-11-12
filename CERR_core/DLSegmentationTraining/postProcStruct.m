function planC = postProcStruct(planC,userOptS)
% planC = postProcStruct(planC,userOptS);
% Function to post-process segementations.
%-------------------------------------------------------------------------
%
%
% AI 10/14/19

% Get list of structures to be post-processed
postS = [];
if isfield(userOptS,'postProc')
    postS = userOptS.postProc;
end

if ~isempty(postS)
    
    strC = fieldnames(postS);
    
    indexS = planC{end};
    
    
    %Loop over structures
    for iStr = 1:length(strC)
        
        strListC = {planC{indexS.structures}.structureName};
        
        outMask3M = [];
        
        strNum = getMatchingIndex(strC{iStr},strListC,'EXACT');
        if length(strNum) ~= 1
            error(['Post-processing error: ', strC{iStr},' not found'])
        end
        scanNum = getStructureAssociatedScan(strNum,planC);
        
        methodC = postS.(strC{iStr}).method;
        if ~iscell(postS.(strC{iStr}).method)
            methodC = {methodC};
        end
        
        %Loop over post-processing methods
        for iMethod = 1:length(methodC)
            
            maskC = cell(length(methodC),1);
            
            
            switch methodC{iMethod}
                
                case 'getLargestConnComps'
                    
                    numConnComponents = postS.(strC{iStr}).params.numCC;
                    [maskC{iMethod}, planC]= getLargestConnComps(strNum,numConnComponents,planC);
                    
                case 'getLargestOverlappingComp'
                    
                    roiName = postS.(strC{iStr}).params.roiName;
                    roiStrNum = getMatchingIndex(roiName,strListC,'EXACT');
                    [maskC{iMethod}, planC] = getLargestOverlappingComp(strNum,roiStrNum,planC);
                    
                case 'getSegInROI'
                    
                    roiName = postS.(strC{iStr}).params.roiName;
                    roiStrNum = getMatchingIndex(roiName,strListC,'EXACT');
                    
                    [roiMask3M, planC] = getStrMask(roiStrNum,planC);
                    [strMask3M, planC] = getStrMask(strNum,planC);
                    
                    maskC{iMethod} = roiMask3M & strMask3M;
                    
                case 'removeBackgroundFP'
                    scan3M =getScanArray(scanNum,planC);
                    connPtMask3M = getPatientOutline(scan3M,[],100);
                    roiName = strC{iStr};
                    roiStrNum = getMatchingIndex(roiName,strListC,'EXACT');
                    [roiMask3M, planC] = getStrMask(roiStrNum,planC);
                    
                    maskC{iMethod} = roiMask3M & connPtMask3M;
                    
                case 'none'
                     
                    [maskC{iMethod}, planC] = getStrMask(strNum,planC);
                     
                otherwise
                    %Custom post-processing function
                    customMethod = methodC{iMethod};
                    if isfield(postS.(strC{iStr}),'params')
                        paramS = postS.(strC{iStr}).params;
                    else
                        paramS = [];
                    end
                    [maskC{iMethod},planC] = feval(customMethod,strNum,paramS,planC);
                   
            end
            
            %Combine masks
            if iMethod>1
                switch lower(postS.(strC{iStr}).operator)
                    case 'union'
                        outMask3M = or(maskC{iMethod-1},maskC{iMethod});
                        maskC{m} = outMask3M;
                    case 'intersection'
                        outMask3M = and(maskC{iMethod-1},maskC{iMethod});
                        maskC{iMethod} = outMask3M;
                end
            end
            
            %Replace original structure
            outMask3M = maskC{end};
            planC = deleteStructure(planC,strNum);
            planC = maskToCERRStructure(outMask3M,0,scanNum,strC{iStr},planC);
            
        end
        
    end
end
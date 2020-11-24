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
    
    
    %Loop over structures from postS
    for iStr = 1:length(strC)
        
        outMask3M = [];
               
        methodC = postS.(strC{iStr}); %.method;
        if ~iscell(postS.(strC{iStr})) %.method)
            methodC = {methodC};
        end
        
        maskC = cell(length(methodC),1);
        
        %Loop over post-processing methods
        for iMethod = 1:length(methodC)
            strListC = {planC{indexS.structures}.structureName};
            %get updated structure number in case iMethod > 1
            strNum = getMatchingIndex(strC{iStr},strListC,'EXACT');
            scanNum = getStructureAssociatedScan(strNum,planC);
            
            switch methodC{iMethod}.method
                
                case 'getLargestConnComps'
                    
                    numConnComponents = methodC{iMethod}.params.numCC;
                    [maskC{iMethod}, planC]= getLargestConnComps(strNum,numConnComponents,planC);
                    
                case 'getLargestOverlappingComp'
                    
                    roiName = methodC{iMethod}.params.roiName;
                    roiStrNum = getMatchingIndex(roiName,strListC,'EXACT');
                    [maskC{iMethod}, planC] = getLargestOverlappingComp(strNum,roiStrNum,planC);
                    
                case 'getSegInROI'
                    
                    roiName = methodC{iMethod}.params.roiName;
                    roiStrNum = getMatchingIndex(roiName,strListC,'EXACT');
                    
                    [roiMask3M, planC] = getStrMask(roiStrNum,planC);
                    [strMask3M, planC] = getStrMask(strNum,planC);
                    
                    maskC{iMethod} = roiMask3M & strMask3M;
                    
                case 'removeBackgroundFP'
                    scan3M =getScanArray(scanNum,planC);
                    connPtMask3M = getPatientOutline(scan3M,[],100);
                    [strMask3M, planC] = getStrMask(strNum,planC);
                    
                    maskC{iMethod} = strMask3M & connPtMask3M;
                    
                case 'none'
                     
                    [maskC{iMethod}, planC] = getStrMask(strNum,planC);
                     
                otherwise
                    %Custom post-processing function
                    customMethod = methodC{iMethod};
                    if isfield(customMethod,'params')
                        paramS = customMethod.params;
                    else
                        paramS = [];
                    end
                    [maskC{iMethod},planC] = feval(customMethod.method,strNum,paramS,planC);
                   
            end
            
            %Combine masks
            if iMethod>1
                switch lower(methodC{iMethod}.operator)
                    case 'union'
                        outMask3M = or(maskC{iMethod-1},maskC{iMethod});
                        maskC{iMethod} = outMask3M;
                    case 'intersection'
                        outMask3M = and(maskC{iMethod-1},maskC{iMethod});
                        maskC{iMethod} = outMask3M;
                end
            end
            
            %Replace original structure
            outMask3M = maskC{iMethod};
            planC = deleteStructure(planC,strNum);
            planC = maskToCERRStructure(outMask3M,0,scanNum,strC{iStr},planC);
            
        end
        
    end
end
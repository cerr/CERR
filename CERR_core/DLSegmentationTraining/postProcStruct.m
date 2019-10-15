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
    strListC = {planC{indexS.structures}.structureName};
    
    %Loop pver structures
    for iStr = 1:length(strC)
        
        outMask3M = [];
        
        strNum = getMatchingIndex(strC{iStr},strListC,'EXACT');
        
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
                    maskC{iMethod} = getLargestConnComps(strNum,numConnComponents,planC);
                    
                    
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
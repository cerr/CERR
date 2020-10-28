function [outMask3M, planC] = getMaskForModelConfig(planC,mask3M,scanNum,cropS)
% getMaskForModelConfig.m
% Create mask for deep learning based on input configuration file.
%
% AI 7/23/19
%--------------------------------------------------------------------------
%INPUTS:
% planC
% mask3M       
% scanNum        
% cropS        : Dictionary of parameters for cropping
%                Supported methods: 'crop_fixed_amt','crop_to_bounding_box',
%                'crop_to_str', 'crop_around_center','crop_pt_outline','crop_shoulders','none'.
%--------------------------------------------------------------------------
% AI 7/23/19
% RKP 9/13/19 

origMask3M = mask3M;
methodC = {cropS.method};
maskC = cell(length(methodC),1);

for m = 1:length(methodC)
    
    method = methodC{m};
    if isfield(cropS(m),'params')
        paramS = cropS(m).params;
    end
    
    switch(lower(method))
        
        case 'crop_fixed_amt'
            cropDimV = paramS.margins;
            outMask3M = false(size(getScanArray(scanNum,planC)));
            outMask3M(cropDimV(1):cropDimV(2),cropDimV(3):cropDimV(4),cropDimV(5):cropDimV(6)) = true;
            maskC{m} = outMask3M;
            
        case {'crop_to_bounding_box','crop_to_bounding_box_2d'}
            %Use to crop around one of the structures to be segmented
            %(bounding box computed for 3D mask)
            label = paramS.label;
            outMask3M = false(size(getScanArray(scanNum,planC)));
            if ~isempty(origMask3M)
                outMask3M = origMask3M == label;
            else
               warning(['Missing label = ', num2str(label)]); 
            end
            maskC{m} = outMask3M;

            
        case {'crop_to_str', 'crop_to_str_2d'}
            %Use to crop around different structure
            %mask3M = []
            strName = paramS.structureName;
            indexS = planC{end};
            strC = {planC{indexS.structures}.structureName};
            strIdx = getMatchingIndex(strName,strC,'EXACT');
            if ~isempty(strIdx)
                [outMask3M, planC] = getStrMask(strIdx,planC);
            else
                warning(['Missing structure ', strName]); 
                outMask3M = false(size(getScanArray(scanNum,planC)));
            end
            maskC{m} = outMask3M;

            
        case 'crop_around_center'
            % Use to crop around center
            cropDimV = paramS.margins;
            scanSizV = size(getScanArray(scanNum,planC));
            
            cx = ceil(scanSizV(1)/2);
            cy = ceil(scanSizV(2)/2);
            x = cropDimV(1)/2;
            y = cropDimV(2)/2;
            minr = cx - y;
            maxr = cx + y-1;
            minc = cy - x;
            maxc = cy + x-1;
            mins = 1;
            maxs = scanSizV(3);
            
            outMask3M = false(scanSizV);
            outMask3M(minr:maxr,minc:maxc,mins:maxs) = true;
            maskC{m} = outMask3M;
            
            
        case {'crop_pt_outline', 'crop_pt_outline_2d'}
            % Use to crop the patient outline
            
            structureName = paramS.structureName;
            outThreshold = paramS.outlineThreshold;            
            indexS = planC{end};            
            outlineIndex = getMatchingIndex(structureName,...
                {planC{indexS.structures}.structureName},'exact');

            if isempty(outlineIndex)
                scan3M = getScanArray(scanNum,planC);
                CToffset = planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
                scan3M = double(scan3M);
                scan3M = scan3M - CToffset;
                sliceV = 1:size(scan3M,3);
                outMask3M = getPatientOutline(scan3M,sliceV,outThreshold);
                maskC{m} = outMask3M;
            else
                [maskC{m}, planC] = getStrMask(outlineIndex,planC);
            end
            
        case 'crop_shoulders'
            % Use to crop above shoulders
            % Use pt_outline structure generated in "crop_pt_outline" case
            indexS = planC{end};
            strName = paramS.structureName;
            strNum = getMatchingIndex(strName,{planC{indexS.structures}.structureName},'exact');
            [pt_outline_mask3M, planC] = getStrMask(strNum,planC);
            
            % generate mask after cropping shoulder slices
            outMask3M = cropShoulder(pt_outline_mask3M,planC);
            maskC{m} = outMask3M;
            
        case 'crop_sup_inf'
            if ~isempty(origMask3M)
                [~, ~, ~, ~, mins, maxs] = compute_boundingbox(origMask3M);
                outMask3M = false(size(mask3M));
                outMask3M(:,:,mins:maxs) = true;
            else
                warning('Input ''mask3M'' is empty.'); 
                outMask3M = false(size(getScanArray(scanNum,planC)));
            end
            maskC{m} = outMask3M;
            
        case 'none'
            %Skip
            
            maskC{m} = [];
            
        otherwise
            %Custom crop function
            [maskC{m},planC] = feval(method,planC,paramS,mask3M,scanNum);
    end
    
    %Save to planC if reqd
    if isfield(paramS,'saveStrToPlanCFlag') && paramS.saveStrToPlanCFlag
        if isfield(paramS,'outStrName')
            outStrName = paramS.outStrName;
        else
            outStrName = method;
        end
        planC = maskToCERRStructure(maskC{m}, 0, scanNum, outStrName,planC);
    end
    
    if m>1
        switch lower(cropS(m).operator)
            case 'union'
                outMask3M = or(maskC{m-1},maskC{m});
                maskC{m} = outMask3M;
            case 'intersection'
                outMask3M = and(maskC{m-1},maskC{m});
                maskC{m} = outMask3M;
        end
    end
    
end


outMask3M = maskC{end};

end
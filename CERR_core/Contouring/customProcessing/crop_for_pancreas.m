function [bbox3M, planC] = crop_for_pancreas(planC,paramS,mask3M,scanNum)
%crop_for_pancreas.m
%--------------------------------------------------------------------------
% INPUTS
% planC      
% paramS     : Dictionary of parameters. 
%              Required:
%              scan: 'registered' or 'fixed'
%              threshold: Intensity threshold
%              saveStrToPlanCFlag: 0/1
% scanNum    : Scan # to be cropped.
%--------------------------------------------------------------------------
% AI 12/07/21

indexS = planC{end};

if strcmpi(paramS.scan,'registered')
    
    strName = 'bounding_box';
    strC = {planC{indexS.structures}.structureName};
    scanTypeC = {planC{indexS.scan}.scanType};
    strNum = getMatchingIndex('bounding_box',strC,'EXACT');
    bbox3M = getStrMask(strNum,planC);
    %Save to planC
    if isfield(paramS,'saveStrToPlanCFlag') && paramS.saveStrToPlanCFlag
        planC = maskToCERRStructure(bbox3M,0,scanNum,strName,planC);
    end
    
else %base scan
    
    %Get scan array
    scan3M  = double(getScanArray(scanNum,planC));
    CToffset = double(planC{indexS.scan}(scanNum).scanInfo(1).CTOffset);
    scan3M = scan3M - CToffset;
    
    %Get user-sepcified parameters
    threshold = paramS.threshold;
    
    %Define output dimensions
    [nRow,nCol,nSlc] = size(scan3M);
    
    min_x_st=9999;
    min_y_st=99999;
    max_x_end=0;
    max_y_end=0;
    
    for n = 1:nSlc
        
        scanM = scan3M(:,:,n);
        
        maskM = zeros(nRow,nCol);
        maskM(scanM>threshold) = 255;
        
        ccS = bwconncomp(maskM);
        regionPropS = regionprops(ccS, 'Area', 'PixelIdxList');
        [~, ind] = sort([regionPropS.Area], 'descend');
        regionPropS = regionPropS(ind);
        Xout = false(size(maskM));
        num_ct = min(1,length(regionPropS));
        
        if num_ct>0
            for tt=1:1, Xout(regionPropS(tt).PixelIdxList) = 1; end
            maskM = Xout;
            bbox = regionprops(maskM, 'BoundingBox');
            crop_box = floor(bbox.BoundingBox);
            extentsV = [crop_box(1),crop_box(2),crop_box(1)+crop_box(3),...
                crop_box(2)+crop_box(4)];
        else
            extentsV = [0,0,1,1];
        end
        
        min_x_st = min(min_x_st,extentsV(1));
        min_y_st = min(min_y_st,extentsV(2));
        max_x_end = max(max_x_end,extentsV(3));
        max_y_end = max(max_y_end,extentsV(4));
        
    end
    
    % Get crop center and extent
    crop_cx=floor((min_x_st+max_x_end)/2);
    crop_cy=floor((min_y_st+max_y_end)/2);
    len_x=(max_x_end-min_x_st)/2;
    len_y=(max_y_end-min_y_st)/2;
    
    % Create mask of bounding box
    bbox3M = false(nRow,nCol,nSlc);
    bbox3M(crop_cy-len_y:crop_cy+len_y,crop_cx-len_x:crop_cx+len_x,:) = true;
    
    %Save to planC
    if isfield(paramS,'saveStrToPlanCFlag') && paramS.saveStrToPlanCFlag
        strName = 'bounding_box';
        planC = maskToCERRStructure(bbox3M,0,scanNum,strName,planC);
    end
    
end


end
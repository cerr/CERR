function [minr, maxr, minc, maxc, mins, maxs] = getCropExtent(planC,mask3M,method,varargin)
% getCropExtent.m
% Compute bounding box extents.
%
% AI 5/2/19

switch(lower(method))
    
    case 'crop_to_bounding_box'
        %Use to crop around one of the structures to be segmented
        %Pass varargin{1} = structLabelNum        labelIdx = varargin{1};
        str3M = mask3M == labelIdx;
        [minr,maxr,minc,maxc,mins,maxs] = compute_boundingbox(str3M);
        
        
    case 'crop_to_str'
        %Use to crop around different structure
        %Pass varargin{1} = structName
        %mask3M = []
        strName = varargin{1};
        indexS = planC{end};
        strC = {planC{indexS.structures}.structureName};
        strIdx = getMatchingIndex(strName{1},strC,'EXACT');
        scanIdx = getStructureAssociatedScan(strIdx,planC);
        
        strMask3M = false(size(getScanArray(scanIdx,planC)));
        rasterM = getRasterSegments(strIdx,planC);
        [slMask3M,slicesV] = rasterToMask(rasterM,scanIdx,planC);
        strMask3M(:,:,slicesV) = slMask3M;
        
        [minr,maxr,minc,maxc,mins,maxs] = compute_boundingbox(strMask3M);
        
        
    case 'crop_around_center'
        cropDimV = varargin{1};
        cx = ceil(size(scan3M,1)/2);
        cy = ceil(size(scan3M,2)/2);
        x = cropDimV(1)/2;
        y = cropDimV(2)/2;
        minr = cx - y;
        maxr = cx + y-1;
        minc = cy - x;
        maxc = cy + x-1;
        mins = [];
        maxs = [];
        
    case 'none'
        %Skip
        
end




end
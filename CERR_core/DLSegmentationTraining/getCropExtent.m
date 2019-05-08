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
        strIdx = getMatchingIndex(strName,strC,'EXACT');
        strMask3M = getUniformStr(strIdx,planC);
        [minr,maxr,minc,maxc,mins,maxs] = compute_boundingbox(strMask3M);
        
        
    case 'crop_around_center'
        %To be added
        
        
    case 'none'
        %Skip
        
end




end
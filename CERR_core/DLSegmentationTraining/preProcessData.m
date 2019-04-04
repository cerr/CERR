function [scan3M,mask3M] = preProcessData(planC,scan3M,mask3M,method,varargin)
% preProcessData.m
%
% Script to preprocess images and labels for training.
%
% AI 3/15/19
%--------------------------------------------------------------------------
%INPUTS:
% scan3M       : Scan array
% mask3M       : Mask
% method       : 'None','crop_fixed_amt','crop_to_bounding_box'
% varargin     : Parameters for pre-processing (Optional)
%--------------------------------------------------------------------------

switch(lower(method))
    
    case 'crop_fixed_amt'
        cropDimV = varargin{1};
        scan3M = scan3M(cropDimV(1):cropDimV(2),cropDimV(3):cropDimV(4),cropDimV(5):cropDimV(6));
        mask3M = mask3M(cropDimV(1):cropDimV(2),cropDimV(3):cropDimV(4),cropDimV(5):cropDimV(6));
        
    case 'crop_to_bounding_box'
        %Use to crop around one of the structures to be segmented
        
        labelIdx = varargin{1};
        str3M = mask3M == labelIdx;
        [minr,maxr,minc,maxc,mins,maxs] = compute_boundingbox(str3M);
        scan3M = scan3M(minr:maxr,minc:maxc,mins:maxs);
        mask3M = mask3M(minr:maxr,minc:maxc,mins:maxs);
        
    case 'crop_to_str'
        %Use to crop around different structure
        strName = varargin{1};
        indexS = planC{end};
        strC = {planC{indexS.structures}.structureName};
        strIdx = getMatchingIndex(strName,strC,'EXACT');
        strMask3M = getUniformStr(strIdx,planC);
        [minr,maxr,minc,maxc,mins,maxs] = compute_boundingbox(strMask3M);
        scan3M = scan3M(minr:maxr,minc:maxc,mins:maxs);
        mask3M = mask3M(minr:maxr,minc:maxc,mins:maxs);
        
    case 'none'
        %..
        
end


end
function [scan3M,mask3M] = cropScanAndMask(planC,scan3M,mask3M,method,varargin)
% cropScanAndMask.m
% Script to crop images and masks for deep learning.
%
% AI 5/2/19
%--------------------------------------------------------------------------
%INPUTS:
% scan3M       : Scan array
% mask3M       : Mask
% method       : Supported methods: 'None','crop_fixed_amt',
%                'crop_to_bounding_box', 'crop_to_str'
% varargin     : Parameters for pre-processing
%--------------------------------------------------------------------------

switch(lower(method))
    
    case 'crop_fixed_amt'
        cropDimV = varargin{1};
        scan3M = scan3M(cropDimV(1):cropDimV(2),cropDimV(3):cropDimV(4),cropDimV(5):cropDimV(6));
        mask3M = mask3M(cropDimV(1):cropDimV(2),cropDimV(3):cropDimV(4),cropDimV(5):cropDimV(6));
        
    case 'crop_to_bounding_box'
        %Use to crop around one of the structures to be segmented
        %Pass varargin{1} = structLabelNum
        [minr, maxr, minc, maxc, mins, maxs] = getCropExtent(planC,mask3M,method,varargin);
        scan3M = scan3M(minr:maxr,minc:maxc,mins:maxs);
        mask3M = mask3M(minr:maxr,minc:maxc,mins:maxs);

    case 'crop_to_str'
        %Use to crop around different structure
        %Pass varargin{1} = structName
        %mask3M = []
        [minr, maxr, minc, maxc, mins, maxs] = getCropExtent(planC,mask3M,method,varargin);
        scan3M = scan3M(minr:maxr,minc:maxc,mins:maxs);
        mask3M = mask3M(minr:maxr,minc:maxc,mins:maxs);
        
    case 'crop_around_center'
         %To be added
         %sizeV = varargin{1};
        
        
    case 'none'
        %Skip
        
end


end
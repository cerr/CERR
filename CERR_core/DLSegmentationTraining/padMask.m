function mask3M = padMask(planC,scanNum,label3M,method,varargin)
% padMask.m
% Script to pad images and masks for deep learning.
%
% AI 5/2/19
%--------------------------------------------------------------------------
%INPUTS:
% scanNum      : Scan no. associated with masks
% label3M      : Mask returned by DL model
% method       : Supported methods: 'None','crop_fixed_amt',
%                'crop_to_bounding_box', 'crop_to_str'
% varargin     : Parameters for pre-processing
%--------------------------------------------------------------------------

sizeV = size(getScanArray(scanNum,planC));
mask3M = false(sizeV);

switch(lower(method))
    
    case 'crop_fixed_amt'
        cropDimV = varargin{1};
        mask3M(cropDimV(1):cropDimV(2),cropDimV(3):cropDimV(4),cropDimV(5):cropDimV(6)) = label3M;
        
    case 'crop_to_bounding_box'
        %Use to crop around one of the structures to be segmented
        %Pass varargin{1} = structLabelNum
        [minr, maxr, minc, maxc, mins, maxs] = getCropExtent(planC,mask3M,method,varargin);
        mask3M(minr:maxr,minc:maxc,mins:maxs) = label3M;
        
    case 'crop_to_str'
        %Use to crop around different structure
        %Pass varargin{1} = structName
        [minr, maxr, minc, maxc, mins, maxs] = getCropExtent(planC,mask3M,method,varargin);
        mask3M(minr:maxr,minc:maxc,mins:maxs) = label3M;
        
    case 'crop_around_center'
        %To be added
        %sizeV = varargin{1};
        
        
    case 'none'
        mask3M = label3M;
        
        
end


end
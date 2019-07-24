function [scan3M,mask3M] = cropScanAndMask(planC,scan3M,mask3M,cropS)
% cropScanAndMask.m
% Crop images and masks for deep learning.
%
% AI 5/2/19
%--------------------------------------------------------------------------
%INPUTS:
% planC         
% scan3M       : Scan array
% mask3M       : Mask
% cropS        : Dictionary of parameters for cropping
%                Supported methods: 'crop_fixed_amt','crop_to_bounding_box',
%                'crop_to_str', 'crop_around_center', 'none'
%--------------------------------------------------------------------------
% AI 5/2/19
% AI 7/23/19

%Get mask for model config
modelMask3M = getMaskForModelConfig(planC,mask3M,cropS);

%Compute bounding box
[minr, maxr, minc, maxc, mins, maxs] = compute_boundingbox(modelMask3M);

%Crop scan and mask
if ~isempty(scan3M)
    scan3M = scan3M(minr:maxr,minc:maxc,mins:maxs);
end
if ~isempty(mask3M)
    mask3M = mask3M(minr:maxr,minc:maxc,mins:maxs);
end    

end
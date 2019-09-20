function [minr, maxr, minc, maxc, mins, maxs] = getCropLimits(planC,mask3M,scanNum,cropS)
% getCropLimits.m
% Get limits of bounding box for various cropping options.
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
modelMask3M = getMaskForModelConfig(planC,mask3M,scanNum,cropS);

%Compute bounding box
methodC = {cropS.method};
crop2DMethodsC = {'crop_to_bounding_box_2D','crop_to_str_2D'};%Suported 2D crop options
if length(methodC) == 1 && strcmp(methodC{1},'none')
    minr = 1;
    maxr = size(modelMask3M,1);
    minc = 1;
    maxc = size(modelMask3M,2);
    mins = 1;
    maxs = size(modelMask3M,3);
    
elseif length(methodC) == 1 && ismember(methodC{1},crop2DMethodsC)
    
    minr = nan(size(modelMask3M,3),1);
    minc = nan(size(modelMask3M,3),1);
    maxr = nan(size(modelMask3M,3),1);
    maxc = nan(size(modelMask3M,3),1);
    for n = 1:size(modelMask3M,3)
        [minr(n), maxr(n), minc(n), maxc(n)] = compute_boundingbox(modelMask3M(:,:,n));
    end
    
else
    [minr, maxr, minc, maxc, mins, maxs] = compute_boundingbox(modelMask3M);
end


end
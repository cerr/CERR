function [minr, maxr, minc, maxc, slcV, modelMask3M, planC] = ...
    getCropLimits(planC,mask4M,scanNum,cropS)
% getCropLimits.m
% Get limits of bounding box for various cropping options.
%
% AI 5/2/19
%--------------------------------------------------------------------------
%INPUTS:
% planC
% scan3M       : 3-D scan array
% mask4M       : 4-D array with 3D structure masks stacked along 
% cropS        : Dictionary of parameters for cropping
%                Supported methods: 'crop_fixed_amt','crop_to_bounding_box',
%                'crop_to_str', 'crop_around_center', 'none'
%--------------------------------------------------------------------------
% AI 5/2/19
% AI 7/23/19

%Get mask for model config
[modelMask3M, planC] = getMaskForModelConfig(planC,mask4M,...
                       scanNum,cropS);

%Compute bounding box
methodC = lower({cropS.method});
crop2DMethodsC = {'crop_to_bounding_box_2d','crop_to_str_2d',...
    'crop_pt_outline_2d'};%Suported 2D crop options
if length(methodC) == 1 && strcmp(methodC{1},'none')
    scanSizeV = size(getScanArray(scanNum,planC));
    minr = 1;
    maxr = scanSizeV(1);
    minc = 1;
    maxc = scanSizeV(2);
    slcV = 1:scanSizeV(3);
    
elseif any(ismember(methodC,crop2DMethodsC))
    
    slcV = find(sum(sum(modelMask3M))>0);
    numSlcs = length(slcV);
    minr = nan(numSlcs,1);
    minc = nan(numSlcs,1);
    maxr = nan(numSlcs,1);
    maxc = nan(numSlcs,1);    
    for n = 1:numSlcs
        [minr(n), maxr(n), minc(n), maxc(n)] = compute_boundingbox(modelMask3M(:,:,slcV(n)));
    end
else
    [minr, maxr, minc, maxc] = compute_boundingbox(modelMask3M);
    slcV = find(sum(sum(modelMask3M))>0);
end


end
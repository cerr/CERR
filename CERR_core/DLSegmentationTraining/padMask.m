function mask3M = padMask(planC,scanNum,label3M,cropS)
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

methodC = {cropS.method};


sizeV = size(getScanArray(scanNum,planC));
mask3M = false(sizeV);
scan3M=[];
for m = 1:length(methodC)
    
    method = methodC{m};
    paramS = cropS(m).params;
    
    switch(lower(method))
        
        case 'crop_fixed_amt'
            cropDimV = paramS.margins;
            mask3M(cropDimV(1):cropDimV(2),cropDimV(3):cropDimV(4),cropDimV(5):cropDimV(6)) = label3M;
            
        case 'crop_to_bounding_box'
            %Use to crop around one of the structures to be segmented           
            modelMask3M = getMaskForModelConfig(planC,mask3M,cropS);
            [minr, maxr, minc, maxc, mins, maxs] = compute_boundingbox(modelMask3M);
            mask3M(minr:maxr,minc:maxc,mins:maxs) = label3M;
            
        case 'crop_to_str'
            %Use to crop around different structure
            modelMask3M = getMaskForModelConfig(planC,mask3M,cropS);
            [minr, maxr, minc, maxc, mins, maxs] = compute_boundingbox(modelMask3M);            
            mask3M(minr:maxr,minc:maxc,mins:maxs) = label3M;
            
        case 'crop_around_center'
            %Use to crop around center
            modelMask3M = getMaskForModelConfig(planC,mask3M,cropS);
            [minr, maxr, minc, maxc, mins, maxs] = compute_boundingbox(modelMask3M);            
            mask3M(minr:maxr,minc:maxc,mins:maxs) = label3M;
            
            
        case 'none'
            mask3M = label3M;
            
            
    end
end

end
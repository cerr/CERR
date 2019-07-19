function [scan3M,mask3M] = cropScanAndMask(planC,scan3M,mask3M,cropS)
% cropScanAndMask.m
% Script to crop images and masks for deep learning.
%
% AI 5/2/19
%--------------------------------------------------------------------------
%INPUTS:
% scan3M       : Scan array
% mask3M       : Mask
% cropS        : Dictionary of parameters for cropping
%                Supported methods: 'crop_fixed_amt','crop_to_bounding_box',
%                'crop_to_str', 'crop_around_center', 'none'
%--------------------------------------------------------------------------

origMask3M = mask3M;
methodC = {cropS.method};
maskC = cell(length(methodC),1);

for m = 1:length(methodC)
    
    method = methodC{m};
    paramS = cropS(m).params;
    
    switch(lower(method))
        
        case 'crop_fixed_amt'
            cropDimV = paramS.margins;
            scan3M = scan3M(cropDimV(1):cropDimV(2),cropDimV(3):cropDimV(4),cropDimV(5):cropDimV(6));
            if ~isempty(origMask3M)
                maskC{m} = origMask3M(cropDimV(1):cropDimV(2),cropDimV(3):cropDimV(4),cropDimV(5):cropDimV(6));
            end
            
        case 'crop_to_bounding_box'
            %Use to crop around one of the structures to be segmented
            label = paramS.label;
            if ~isempty(origMask3M)
                [minr, maxr, minc, maxc, mins, maxs] = getCropExtent(planC,origMask3M,method,label);
                scan3M = scan3M(minr:maxr,minc:maxc,mins:maxs);
                maskC{m} = origMask3M(minr:maxr,minc:maxc,mins:maxs);
            end
            
        case 'crop_to_str'
            %Use to crop around different structure
            %mask3M = []
            strName = paramS.structureName;
            [minr, maxr, minc, maxc, mins, maxs] = getCropExtent(planC,origMask3M,method,strName);
            scan3M = scan3M(minr:maxr,minc:maxc,mins:maxs);
            if ~isempty(origMask3M)
                maskC{m} = origMask3M(minr:maxr,minc:maxc,mins:maxs);
            end
            
        case 'crop_around_center'
            % Use to crop around center
            cropDimV = paramS.margins;
            scanSizV = size(scan3M);
            [minr, maxr, minc, maxc, mins, maxs] = getCropExtent(planC,mask3M,method,scanSizV,cropDimV);
            scan3M = scan3M(minr:maxr,minc:maxc,mins:maxs);
            if ~isempty(origMask3M)
                maskC{m} = origMask3M(minr:maxr,minc:maxc,mins:maxs);
            end
            
            
        case 'none'
            %Skip
            
    end
    
    if m>1
        switch lower(cropS(m).operator)
            case 'union'
                mask3M = or(maskC{m-1},maskC{m});
                maskC{m} = mask3M;
            case 'intersection'
                mask3M = and(maskC{m-1},maskC{m});
                maskC{m} = mask3M;
        end
    end
    
end

mask3M = maskC{m};

end
function [scanOut3M, maskOut3M] = resizeScanAndMask(scan3M,mask3M,inputImgSizeV,method,cropS,planC)
% resizeScanAndMask.m
% Script to resize images and masks for deep learning.
%
% AI 7/2/19
%--------------------------------------------------------------------------
%INPUTS:
% scan3M       : Scan array
% mask3M       : Mask
% method       : Supported methods: 'none','pad',
%                'bilinear', 'sinc'
% inputImgSizeV: Input size required by model [height, width]
%--------------------------------------------------------------------------

switch(lower(method))
    
    case 'pad'
        xPad = floor(inputImgSizeV(1) - size(scan3M,1));
        yPad = floor(inputImgSizeV(2) - size(scan3M,2));
        
        scanOut3M = zeros(inputImgSizeV(1), inputImgSizeV(2), size(scan3M,3));
        scanOut3M(xPad+1:xPad+size(scan3M,1), yPad+1:yPad+size(scan3M,2), 1:size(scan3M,3)) = scan3M;
        
        if isempty(mask3M)
            maskOut3M = [];
        else
            maskOut3M = zeros(inputImgSizeV(1), inputImgSizeV(2), size(mask3M,3));
            maskOut3M(xPad+1:xPad+size(scan3M,1), yPad+1:yPad+size(scan3M,2), 1:size(scan3M,3)) = mask3M;
        end
        
        
    case 'bilinear'
        
        scanOut3M = imresize(scan3M, inputImgSizeV, 'bilinear');
        if isempty(mask3M)
            maskOut3M = [];
        else
            maskOut3M = imresize(mask3M, inputImgSizeV, 'nearest');
        end
        
    case 'sinc'
        
        scanOut3M = imresize(scan3M, inputImgSizeV, 'lanczos3');
        if isempty(mask3M)
            maskOut3M = [];
        else
            maskOut3M = imresize(mask3M, inputImgSizeV, 'nearest');
        end
        
    case 'special_self_attention_pad'
        
        if isempty(scan3M)
            scanOut3M = [];
        else
            % Adjust size before padding
            scanSize = size(scan3M);
            
            % x-direction, must be <256 and must be even
            if scanSize(1)>256
                diff = scanSize(1) - 255;
                [minr, maxr, minc, maxc, mins, maxs] = compute_boundingbox(scan3M);
                scan3M = scan3M(minr:maxr-diff,minc:maxc,mins:maxs);
            end
            updatedScanSize = size(scan3M);
            if mod(updatedScanSize(1),2)==1
                [minr, maxr, minc, maxc, mins, maxs] = compute_boundingbox(scan3M);
                scan3M = scan3M(minr:maxr-1,minc:maxc,mins:maxs);
            end
            
            % y-direction, must be <256 and must be even
            if scanSize(2)>255
                diff = scanSize(2) - 255;
                [minr, maxr, minc, maxc, mins, maxs] = compute_boundingbox(scan3M);
                scan3M = scan3M(minr:maxr,minc:maxc-diff,mins:maxs);
            end
            updatedScanSize = size(scan3M);
            if mod(updatedScanSize(2),2)==1
                [minr, maxr, minc, maxc, mins, maxs] = compute_boundingbox(scan3M);
                scan3M = scan3M(minr:maxr,minc:maxc-1,mins:maxs);
            end
            
            % pad to final size required
            xPad = floor(inputImgSizeV(1) - size(scan3M,1));
            yPad = floor(inputImgSizeV(2) - size(scan3M,2));
            
            scanOut3M = zeros(inputImgSizeV(1), inputImgSizeV(2), size(scan3M,3));
            scanOut3M(xPad+1:xPad+size(scan3M,1), yPad+1:yPad+size(scan3M,2), 1:size(scan3M,3)) = scan3M;
        end
            
            if isempty(mask3M)
                maskOut3M = [];
            else
                tempMask3M = false(size(mask3M));
                
                modelMask3M = getMaskForModelConfig(planC,tempMask3M,cropS);
                [minr, maxr, minc, maxc, mins, maxs] = compute_boundingbox(modelMask3M);
                modelMask3M = modelMask3M(minr:maxr,minc:maxc,mins:maxs);

                maskSize = size(modelMask3M)
                maskOut3M = zeros(maskSize(1), maskSize(2), maskSize(3));
                
%                 % Adjust size before padding
     
%                 % x-direction, must be <256 and must be even
                if maskSize(1)>255
                    diff = bas(maskSize(1) - 255);
                    maskOut3M = padarray(maskOut3M,diff,0,'post');
                end
                updatedMaskSize = size(maskOut3M)
                if mod(updatedMaskSize(1),2)==1 
                    maskOut3M = padarray(maskOut3M,1,0,'post');
                end
                
                % y-direction, must be <256 and must be even
                if maskSize(2)>255
                    diff = abs(maskSize(1) - 255);
                    maskOut3M = padarray(maskOut3M,[0,diff],0,'post');

                end
                updatedMaskSize = size(maskOut3M)
                if mod(updatedMaskSize(1),2)==1
                    maskOut3M = padarray(maskOut3M,1,0,'pre');
                end
                %maskOut3M = mask3M
            end
               
        
        
    case 'none'
        %Skip
        
end


end
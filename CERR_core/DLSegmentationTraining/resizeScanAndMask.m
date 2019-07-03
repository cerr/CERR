function [scanOut3M, maskOut3M] = resizeScanAndMask(scan3M,mask3M,inputImgSizeV,method)
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
        xPad = floor(inputImgSizeV(1) - size(scan3M,1)/2);
        yPad = floor(inputImgSizeV(2) - size(scan3M,2)/2);
        
        scanOut3M = zeros(inputImgSizeV(1), inputImgSizeV(2));
        scanOut3M(xPad+1:xPad+size(scan3M,1), yPad+1:yPad+size(scan3M,2)) = scan3M;
        
        if isempty(mask3M)
            maskOut3M = [];
        else
            maskOut3M = zeros(inputImgSizeV(1), inputImgSizeV(2));
            maskOut3M(xPad+1:xPad+size(scan3M,1), yPad+1:yPad+size(scan3M,2)) = mask3M;
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
        
    case 'none'
        %Skip
        
end


end
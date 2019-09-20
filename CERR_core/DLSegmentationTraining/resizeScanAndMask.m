function [scanOut3M, maskOut3M] = resizeScanAndMask(scan3M,mask3M,outputImgSizeV,method,varargin)
% resizeScanAndMask.m
% Script to resize images and masks for deep learning.
%
% AI 7/2/19
%--------------------------------------------------------------------------
%INPUTS:
% scan3M         :  Scan array
% mask3M         :  Mask
% method         :  Supported methods: 'none','pad2d', 'pad3d',
%                 'bilinear', 'sinc'
% outputImgSizeV :  Required output size [height, width]
%--------------------------------------------------------------------------
%RKP 9/13/19 - Added method 'pad2d'
%AI 9/19/19  - Updated to handle undo-resize options

%Get input image size
if ~isempty(scan3M)
    origSizV = [size(scan3M,1), size(scan3M,2), size(scan3M,3)];
else
    origSizV = [size(mask3M,1), size(mask3M,2), size(mask3M,3)];
end

%Resize image by method
switch(lower(method))
    
    case 'pad3d'
        
        xPad = floor((outputImgSizeV(1) - origSizV(1))/2);
        yPad = floor((outputImgSizeV(2) - origSizV(2))/2);
        
        if xPad > 0
            
            %Pad scan
            if isempty(scan3M)
                scanOut3M = [];
            else
                scanOut3M = zeros(outputImgSizeV);
                scanOut3M(xPad+1:xPad+origSizV(1), yPad+1:yPad+origSizV(2), 1:origSizV(3)) = scan3M;
            end
            
            %Pad mask
            if isempty(mask3M)
                maskOut3M = [];
            else
                maskOut3M = zeros(outputImgSizeV);
                maskOut3M(xPad+1:xPad+origSizV(1), yPad+1:yPad+origSizV(2), 1:origSizV(3)) = mask3M;
            end
            
        else
            
            %un-pad
            xPad = -xPad;
            yPad = -yPad;
            
            if isempty(scan3M)
                scanOut3M = [];
            else
                scanOut3M = scan3M(xPad+1:xPad+origSizV(1), yPad+1:yPad+origSizV(2), :);
            end
            
            if isempty(mask3M)
                maskOut3M = [];
            else
                maskOut3M = mask3M(xPad+1:xPad+origSizV(1), yPad+1:yPad+origSizV(2), :);
            end
            
        end
        
    case 'pad2d'
        
        %varargin{1}: limitsM = [minrV,maxrV,mincV,maxcV]
        
        scanOut3M = zeros(outputImgSizeV);  
        maskOut3M = false(outputImgSizeV);
        
        limitsM = varargin{1};
        
        if outputImgSizeV(1) > origSizV(1)
            padFlag = 1;
        else
            padFlag = 0;  %un-pad
        end
            
        
        for slcNum = 1:outputImgSizeV(3)
            
            minr = limitsM(slcNum,1);
            maxr = limitsM(slcNum,2);
            minc = limitsM(slcNum,3);
            maxc = limitsM(slcNum,4);
            
            rowCenter = round((minr+maxr)/2);
            colCenter = round((minc+maxc)/2);
            rMin = rowCenter - outputImgSizeV(1)/2;
            cMin = colCenter - outputImgSizeV(2)/2;
            if rMin < 1
                rMin = 1;
            end
            if cMin < 1
                cMin = 1;
            end
            rMax = rMin + outputImgSizeV(1) - 1;
            cMax = cMin + outputImgSizeV(2) - 1;
            
            if ~isempty(scan3M)
                if padFlag
                    scanOut3M(:,:,slcNum) = scan3M(rMin:rMax,cMin:cMax,slcNum);
                else
                    scanOut3M(rMin:rMax,cMin:cMax,slcNum)= scan3M(:,:,slcNum);
                end
            end
            
            if ~isempty(mask3M)
                if padFlag
                    maskOut3M(:,:,slcNum) = mask3M(rMin:rMax,cMin:cMax,slcNum);
                else
                    maskOut3M(rMin:rMax,cMin:cMax,slcNum)= mask3M(:,:,slcNum);
                end
            end
            
        end
        
    case 'bilinear'
        
        if isempty(scan3M)
            scanOut3M = [];
        else
            scanOut3M = imresize(scan3M, outputImgSizeV, 'bilinear');
        end
        
        if isempty(mask3M)
            maskOut3M = [];
        else
            maskOut3M = imresize(mask3M, outputImgSizeV, 'nearest');
        end
        
    case 'sinc'
        
        if isempty(scan3M)
            scanOut3M = [];
        else
            scanOut3M = imresize(scan3M, outputImgSizeV, 'lanczos3');
        end
        
        if isempty(mask3M)
            maskOut3M = [];
        else
            maskOut3M = imresize(mask3M, outputImgSizeV, 'nearest');
        end
        
        
    case 'none'
        scanOut3M = scan3M;
        maskOut3M = mask3M;
        
end


end
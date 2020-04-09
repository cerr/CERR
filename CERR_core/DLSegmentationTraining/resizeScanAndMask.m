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
%                   'bilinear', 'sinc', 'bicubic'.
% outputImgSizeV :  Required output size [height, width]
%--------------------------------------------------------------------------
%RKP 9/13/19 - Added method 'pad2d'
%AI 9/19/19  - Updated to handle undo-resize options


outputImgSizeV = outputImgSizeV(:)';

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
        
    case 'unpad2d'
        % Zero out regions outside the mask
        scan3M(~mask3M) = 0;
        
        % Initialize resized scan and mask
        scanOut3M = zeros(outputImgSizeV);
        maskOut3M = zeros(outputImgSizeV,'uint32');
        
        % Min/max row and col limits for each slice
        limitsM = varargin{1};
        
        for slcNum = 1:origSizV(3)
            
            minr = limitsM(slcNum,1);
            maxr = limitsM(slcNum,2);
            minc = limitsM(slcNum,3);
            maxc = limitsM(slcNum,4);
            
            rowCenter = round((minr+maxr)/2);
            colCenter = round((minc+maxc)/2);
            
            rMin = rowCenter - origSizV(1)/2;
            cMin = colCenter - origSizV(2)/2;
            
            if rMin < 1
                rMin = 1;
            end
            if cMin < 1
                cMin = 1;
            end
            
            
            rMax = rMin + origSizV(1) - 1;
            cMax = cMin + origSizV(2) - 1;
            
            if rMax > outputImgSizeV(1)
                rMax = outputImgSizeV(1);
            end
            if cMax > outputImgSizeV(2)
                cMax = outputImgSizeV(2);
            end
            
            
            outRmin = 1;
            outCmin = 1;
            outRmax = outRmin + rMax - rMin;
            outCmax = outCmin + cMax - cMin;
            
            scanOut3M(rMin:rMax,cMin:cMax,slcNum)= scan3M(outRmin:outRmax,outCmin:outCmax,slcNum);
            maskOut3M(rMin:rMax,cMin:cMax,slcNum)= mask3M(outRmin:outRmax,outCmin:outCmax,slcNum);
            
        end
        
    case 'pad2d'
        
        % Zero out regions outside the mask
        scan3M(~mask3M) = 0;
        
        % Initialize resized scan and mask
        scanOut3M = zeros(outputImgSizeV);
        
        if isempty(mask3M)
            maskOut3M = [];
        else
            maskOut3M = zeros(outputImgSizeV,'uint32');
        end
        
        % Min/max row and col limits for each slice
        limitsM = varargin{1};
        
        for slcNum = 1:origSizV(3)
            
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
            
            if rMax > origSizV(1)
                rMax = origSizV(1);
            end
            if cMax > origSizV(2)
                cMax = origSizV(2);
            end
            
            outRmin = 1;
            outCmin = 1;
            outRmax = outRmin + rMax - rMin;
            outCmax = outCmin + cMax - cMin;
            
            if ~isempty(scan3M)
                scanOut3M(outRmin:outRmax,outCmin:outCmax,slcNum) = scan3M(rMin:rMax,cMin:cMax,slcNum);
            end
            
            if ~isempty(mask3M)
                maskOut3M(outRmin:outRmax,outCmin:outCmax,slcNum) = mask3M(rMin:rMax,cMin:cMax,slcNum);
            end
            
        end
        
    case {'bilinear','sinc','bicubic'} 
        
        if strcmp(method,'sinc')
            methodName = 'lanczos3';
        else
            methodName = method;
        end
        
        if isempty(scan3M)
            scanOut3M = [];
            
        else
            if nargin==4 || size(varargin{1},1)==1 %Previously cropped (3D)
                scanOut3M = imresize(scan3M, outputImgSizeV, methodName);
                
            else %2-D cropping and resizing
                scanOut3M = nan([outputImgSizeV,origSizV(3)]);
                limitsM = varargin{1};
                
                %Loop over slices
                for slcNum = 1:origSizV(3)
                    
                    %Get bounds
                    minr = limitsM(slcNum,1);
                    maxr = limitsM(slcNum,2);
                    minc = limitsM(slcNum,3);
                    maxc = limitsM(slcNum,4);
                    
                    %Crop slice
                    scanSliceM = scan3M(:,:,slcNum);
                    croppedSliceM = scanSliceM(minr:maxr, minc:maxc);
                    
                    %Resize slice
                    resizedSliceM = imresize(croppedSliceM, outputImgSizeV,...
                        methodName);
                    
                    scanOut3M(:,:,slcNum) = resizedSliceM;
                end
            end
        end
        
        if isempty(mask3M)
            maskOut3M = [];
            
        else
            if nargin==4 || size(varargin{1},1)==1 %Previously cropped (3D)
                maskOut3M = imresize(scan3M, outputImgSizeV, 'nearest');
                
            else %2-D cropping and resizing
                maskOut3M = false([outputImgSizeV,origSizV(3)]);
                limitsM = varargin{1};
                
                %Loop over slices
                for slcNum = 1:origSizV(3)
                    
                    %Get bounds
                    minr = limitsM(slcNum,1);
                    maxr = limitsM(slcNum,2);
                    minc = limitsM(slcNum,3);
                    maxc = limitsM(slcNum,4);
                    
                    %Crop slice
                    maskSliceM = mask3M(:,:,slcNum);
                    croppedSliceM = maskSliceM(minr:maxr, minc:maxc);
                    
                    %Resize slice
                    resizedSliceM = imresize(croppedSliceM, outputImgSizeV,...
                        'nearest');
                    
                    maskOut3M(:,:,slcNum) = resizedSliceM;
                end
            end
        end
        
    
        
    case 'none'
        scanOut3M = scan3M;
        maskOut3M = mask3M;
        
end


end
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
        scanOut3M = scanOut3M - 1024;
        maskOut3M = zeros(outputImgSizeV,'uint32');
        
        % Min/max row and col limits for each slice
        limitsM = varargin{1};
        
        %         if outputImgSizeV(1) < origSizV(1)
        %             padFlag = 1;
        %         else
        %             padFlag = 0;  %un-pad
        %         end
        
        
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
        scanOut3M = scanOut3M - 1024;
        maskOut3M = zeros(outputImgSizeV,'uint32');
        
        % Min/max row and col limits for each slice
        limitsM = varargin{1};
        
        %         if outputImgSizeV(1) < origSizV(1)
        %             padFlag = 1;
        %         else
        %             padFlag = 0;  %un-pad
        %         end
        
        
        for slcNum = 1:origSizV(3)
            
            minr = limitsM(slcNum,1);
            maxr = limitsM(slcNum,2);
            minc = limitsM(slcNum,3);
            maxc = limitsM(slcNum,4);
            
            rowCenter = round((minr+maxr)/2);
            colCenter = round((minc+maxc)/2);
            
            %             if outputImgSizeV(1) < origSizV(1)
            rMin = rowCenter - outputImgSizeV(1)/2;
            cMin = colCenter - outputImgSizeV(2)/2;
            %             else
            %                 rMin = rowCenter - origSizV(1)/2;
            %                 cMin = colCenter - origSizV(2)/2;
            %             end
            if rMin < 1
                rMin = 1;
            end
            if cMin < 1
                cMin = 1;
            end
            %             if outputImgSizeV(1) < origSizV(1)
            rMax = rMin + outputImgSizeV(1) - 1;
            cMax = cMin + outputImgSizeV(2) - 1;
            %             else
            %                 rMax = rMin + origSizV(1) - 1;
            %                 cMax = cMin + origSizV(2) - 1;
            %             end
            %             if outputImgSizeV(1) < origSizV(1)
            if rMax > origSizV(1)
                rMax = origSizV(1);
            end
            if cMax > origSizV(2)
                cMax = origSizV(2);
            end
            %             else
            %                 if rMax > outputImgSizeV(1)
            %                     rMax = outputImgSizeV(1);
            %                 end
            %                 if cMax > outputImgSizeV(2)
            %                     cMax = outputImgSizeV(2);
            %                 end
            %             end
            
            outRmin = 1;
            outCmin = 1;
            outRmax = outRmin + rMax - rMin;
            outCmax = outCmin + cMax - cMin;
            
            if ~isempty(scan3M)
                %                 if padFlag
                scanOut3M(outRmin:outRmax,outCmin:outCmax,slcNum) = scan3M(rMin:rMax,cMin:cMax,slcNum);
                %                 else
                %                     scanOut3M(rMin:rMax,cMin:cMax,slcNum)= scan3M(outRmin:outRmax,outCmin:outCmax,slcNum);
                %                 end
            end
            
            if ~isempty(mask3M)
                %                 if padFlag
                maskOut3M(outRmin:outRmax,outCmin:outCmax,slcNum) = mask3M(rMin:rMax,cMin:cMax,slcNum);
                %                 else
                %                     maskOut3M(rMin:rMax,cMin:cMax,slcNum)= mask3M(outRmin:outRmax,outCmin:outCmax,slcNum);
                %                 end
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
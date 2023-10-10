function [scanOut3M, maskOut4M] = resizeScanAndMask(scan3M,mask4M,...
                                  outputImgSizeV,method,varargin)
% resizeScanAndMask.m
% Script to resize images and masks for deep learning.
%
% AI 7/2/19
%--------------------------------------------------------------------------
%INPUTS:
% scan3M         :  Scan array
% mask4M         : 4-D array with 3D structure masks stacked along 
% outputImgSizeV :  Required output size [height, width]
% method         :  Supported methods: 'none','pad2d', 'pad3d',
%                   'bilinear', 'sinc', 'bicubic', 'nearest'.
% limitsM        :  Matrix with rows listing indices of rows & cols defining
%                   ROI extents on each slice [minr, maxr, minc, maxc] 
% preserveAspectFlag : Set to 1 to preserve aspect ratio when reszing (default:0)
%--------------------------------------------------------------------------
%RKP 9/13/19 - Added method 'pad2d'
%AI 9/19/19  - Updated to handle undo-resize options


if nargin > 4
    limitsM = varargin{1};
    if numel(varargin) > 1
        preserveAspectFlag = varargin{2};
    else
        preserveAspectFlag = 0;
    end
else
    limitsM = [];
    preserveAspectFlag = 0;
end
outputImgSizeV = outputImgSizeV(:)';

%Get input image size
if ~isempty(scan3M)
    origSizV = [size(scan3M,1), size(scan3M,2), size(scan3M,3)];
else
    origSizV = [size(mask4M,1), size(mask4M,2), size(mask4M,3)];
end
numStr = size(mask4M,4);

%Resize image by method
switch(lower(method))
    
    case 'padorcrop3d'

        if preserveAspectFlag
            cornerCube = scan3M(1:5,1:5,1:5);
            bgMean = mean(cornerCube(:));
            scanSize = size(scan3M);
            paddedSize = max(scanSize(1:2));
            padded3M = bgMean * ones(paddedSize,paddedSize,size(scan3M,3));
            idx11 = 1 + (paddedSize - scanSize(1))/2;
            idx12 = idx11 + scanSize(1) - 1;
            idx21 = 1 + (paddedSize - scanSize(2))/2;
            idx22 = idx21 + scanSize(2) - 1;
            padded3M(idx11:idx12,idx21:idx22,:) = scan3M;
            scan3M = padded3M;
            origSizV = size(scan3M);
        end

        xPad = floor((outputImgSizeV(1) - origSizV(1))/2);
        if xPad < 0
            resizeMethod = 'unpad3d'       ;     
        else
            resizeMethod = 'pad3d';
        end
        [scanOut3M, maskOut4M] = resizeScanAndMask(scan3M,...
            mask4M,outputImgSizeV,resizeMethod,varargin);
        
    case 'padorcrop2d'
        xPad = floor((outputImgSizeV(1) - origSizV(1))/2);
        if xPad < 0
            resizeMethod = 'unpad2d';
        else
            resizeMethod = 'pad2d';
        end
        [scanOut3M, maskOut4M] = resizeScanAndMask(scan3M,...
            mask4M,outputImgSizeV,resizeMethod,varargin{:});
        
    case 'pad3d'
        
        xPad = ceil((outputImgSizeV(1) - origSizV(1))/2);
        yPad = ceil((outputImgSizeV(2) - origSizV(2))/2);
        
        if xPad<0 || yPad<0
            error(['To resize by padding, output image dimensions must be',...
                ' larger than (cropped) input image dimensions']);
        end
                
        %Pad scan
        if isempty(scan3M)
            scanOut3M = [];
        else
            minScanVal = min(scan3M(:));
            scanOut3M = zeros(outputImgSizeV,class(scan3M)) + minScanVal;            
            scanOut3M(xPad+1:xPad+origSizV(1), yPad+1:yPad+origSizV(2), 1:origSizV(3)) = scan3M;
        end
        
        %Pad mask
        if isempty(mask4M)
            maskOut4M = [];
        else
            maskOut4M = zeros(outputImgSizeV);
            maskOut4M(xPad+1:xPad+origSizV(1), yPad+1:yPad+origSizV(2),...
                1:origSizV(3),:) = mask4M;
        end
        
    case 'unpad3d'
        
        xPad = floor((outputImgSizeV(1) - origSizV(1))/2);
        yPad = floor((outputImgSizeV(2) - origSizV(2))/2);
        
        xPad = -xPad;
        yPad = -yPad;
        
        if isempty(scan3M)
            scanOut3M = [];
        else
            scanOut3M = scan3M(xPad+1:xPad+outputImgSizeV(1),...
                yPad+1:yPad+outputImgSizeV(2), :);
        end
        
        if isempty(mask4M)
            maskOut4M = [];
        else
            maskOut4M = mask4M(xPad+1:xPad+outputImgSizeV(1),...
                yPad+1:yPad+outputImgSizeV(2),:,:);
        end
        
    case 'unpad2d'
        % Zero out regions outside the mask
        %scan3M(~mask3M) = 0;
        
        % Initialize resized scan and mask
        if isempty(scan3M)
            scanOut3M = [];
        else
            minScanVal = min(scan3M(:));
            scanOut3M = zeros(outputImgSizeV,class(scan3M)) + minScanVal;
        end
        
        if isempty(mask4M)
            maskOut4M = [];
        else
            maskOut4M = zeros([outputImgSizeV,numStr],'uint32');
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
            
            if ~isempty(scan3M)
                scanOut3M(rMin:rMax,cMin:cMax,slcNum)= ...
                    scan3M(outRmin:outRmax,outCmin:outCmax,slcNum);
            end
            if ~isempty(mask4M)
                maskOut4M(rMin:rMax,cMin:cMax,slcNum,:)= ...
                    mask4M(outRmin:outRmax,outCmin:outCmax,slcNum,:);
            end
            
        end
        
    case 'pad2d'
        
        % Zero out regions outside the mask
        %scan3M(~mask3M) = 0; % make this optional in future
        
        % Initialize resized scan and mask
        if isempty(scan3M)
            scanOut3M = [];
        else
            minScanVal = min(scan3M(:));
            scanOut3M = zeros(outputImgSizeV,class(scan3M)) + minScanVal;
        end
        
        if isempty(mask4M)
            maskOut4M = [];
        else
            maskOut4M = zeros([outputImgSizeV,numStr],'uint32');
        end
        
        % Min/max row and col limits for each slice
%         limitsM = varargin{1};
        
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
            
            if ~isempty(mask4M)
                maskOut4M(outRmin:outRmax,outCmin:outCmax,slcNum) = mask4M(rMin:rMax,cMin:cMax,slcNum);
            end
            
        end

    case 'padslices'

        numSlices = outputImgSizeV;
        scanOut3M = [];
        if ~isempty(scan3M)
            scanOut3M = zeros(size(scan3M,1),size(scan3M,2),numSlices);
            scanOut3M(:,:,1:origSizV(3)) = scan3M;
        end

        maskOut4M = [];
        if ~isempty(mask4M)
            maskOut4M = zeros(size(scan3M,1),size(scan3M,2),numSlices);
            maskOut4M(:,:,1:origSizV(3)) = mask4M;
        end

    case 'unpadslices'

        numSlices = outputImgSizeV;
        scanOut3M = [];
        if ~isempty(scan3M)
            scanOut3M = scan3M(:,:,1:numSlices);
        end

        maskOut4M = [];
        if ~isempty(mask4M)
            maskOut4M = mask4M(:,:,1:numSlices);
        end
        
    case {'bilinear','sinc','bicubic','nearest'}
        
        if strcmp(method,'sinc')
            methodName = 'lanczos3';
        else
            methodName = method;
        end
        
        if isempty(scan3M)
            scanOut3M = [];
            
        else
            if preserveAspectFlag % preserve aspect ratio == yes
                cornerCube = scan3M(1:5,1:5,1:5);
                bgMean = mean(cornerCube(:));
                scanSize = size(scan3M);
            end
            if nargin==4 || size(varargin{1},1)==1 %Previously cropped (3D)
                if preserveAspectFlag  %%add case for non-square outputImgSizeV?
                    paddedSize = max(scanSize(1:2));
                    padded3M = bgMean * ones(paddedSize,paddedSize,size(scan3M,3));
                    idx11 = 1 + (paddedSize - scanSize(1))/2;
                    idx12 = idx11 + scanSize(1) - 1;
                    idx21 = 1 + (paddedSize - scanSize(2))/2;
                    idx22 = idx21 + scanSize(2) - 1;
                    padded3M(idx11:idx12,idx21:idx22,:) = scan3M;
                    scanOut3M = nan([outputImgSizeV,size(scan3M,3)]);
                    for nSlc = 1:size(padded3M,3)
                        scanOut3M(:,:,nSlc) = imresize(squeeze(padded3M(:,:,nSlc)),...
                            outputImgSizeV(1:2), methodName);
                    end
                else
                    scanOut3M = nan([outputImgSizeV(1:2),size(scan3M,3)]);
                    for nSlc = 1:size(scan3M,3)
                        scanOut3M(:,:,nSlc) = imresize(squeeze(scan3M(:,:,nSlc)),...
                            outputImgSizeV(1:2), methodName);
                    end
                end
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
                    if preserveAspectFlag
                        cropSize = [maxr - minr, maxc - minc];
                        paddedSize = max(cropSize);
                        croppedSliceM = bgMean * ones(paddedSize,paddedSize);
                        idx11 = 1 + floor((paddedSize - cropSize(1)) / 2);
                        idx12 = idx11 + cropSize(1);
                        idx21 = 1 + floor((paddedSize - cropSize(2)) / 2);
                        idx22 = idx21 + cropSize(2);
                        croppedSliceM(idx11:idx12,idx21:idx22) = scanSliceM(minr:maxr,minc:maxc);
                    else
                        croppedSliceM = scanSliceM(minr:maxr, minc:maxc);
                    end
                    %Resize slice
                    resizedSliceM = imresize(croppedSliceM, outputImgSizeV(1:2),...
                        methodName);
                    
                    scanOut3M(:,:,slcNum) = resizedSliceM;
                end
            end
        end
        
        if isempty(mask4M)
            maskOut4M = [];
            
        else
            if nargin > 3 && size(limitsM,1)==1 % cropped 3D
                minr = limitsM(1); 
                maxr = limitsM(2);
                minc = limitsM(3);
                maxc = limitsM(4);
                cropDim = [maxr-minr+1, maxc-minc+1];
%                 slcV = limitsM(6) - limitsM(5) + 1;                
                if preserveAspectFlag  %%add case for non-square outputImgSizeV?
                    paddedSize = max(cropDim(1:2))*[1, 1];
                    maskResize3M = zeros([paddedSize,size(mask4M,3)]);
                    for nSlc = 1:size(mask4M,3)
                        maskResize3M(:,:,nSlc) = imresize(squeeze(...
                            mask4M(:,:,nSlc)),paddedSize, 'nearest');
                    end
                    %padded3M = bgMean * ones(paddedSize,paddedSize,size(scan3M,3));
                    idx11 = 1 + round((paddedSize - cropDim(1))/2);
                    idx12 = idx11 + cropDim(1) - 1;
                    idx21 = 1 + round((paddedSize - cropDim(2))/2);
                    idx22 = idx21 + cropDim(2) - 1;
                    
%                     maskOut3M = zeros([outputImgSizeV(1:2), origSizV(3)]);
%                     maskOut3M(minr:maxr,minc:maxc,:) = maskResize3M(idx11:idx12,idx21:idx11,:);
                    maskOut4M = maskResize3M(idx11:idx12,idx21:idx22,:);
                else
                    maskOut4M = zeros([outputImgSizeV(1:2),size(mask4M,3)]);
                    for nSlc = 1:size(mask4M,3)
                        maskOut4M(:,:,nSlc) = imresize(squeeze(...
                            mask4M(:,:,nSlc)),outputImgSizeV(1:2), 'nearest');
                    end
                end
            else %2-D cropping and resizing
                maskOut4M = zeros([outputImgSizeV(1:2),origSizV(3)]);
                limitsM = varargin{1};
                
                maskOut4M = zeros([outputImgSizeV(1:2),origSizV(3)]);

                %Loop over slices
                for slcNum = 1:origSizV(3)
                    
                    maskSliceM = mask4M(:,:,slcNum);
                    
                    %Get bounds
                    minr = limitsM(slcNum,1);
                    maxr = limitsM(slcNum,2);
                    minc = limitsM(slcNum,3);
                    maxc = limitsM(slcNum,4);
                    
                    cropDim = [maxr-minr+1, maxc-minc+1];
                    
                    if preserveAspectFlag
                        paddedSize = max(cropDim(1:2))*[1, 1];
                        maskSliceResize = imresize(maskSliceM,paddedSize,'nearest');
                    %Un-crop slice
%                         paddedSize = max(cropDim);
                        idx11 = 1 + floor((paddedSize(1) - cropDim(1)) / 2);
                        idx12 = idx11 + cropDim(1) - 1;
                        idx21 = 1 + floor((paddedSize(2) - cropDim(2)) / 2);
                        idx22 = idx21 + cropDim(2)-1;
                        resizedSliceM = zeros(outputImgSizeV(1:2));
                        resizedSliceM(minr:maxr,minc:maxc) = maskSliceResize(idx11:idx12,idx21:idx22);
%                       resizedSliceM = maskSliceResize(idx11:idx12,idx21:idx22);
                    else

                        croppedSliceM = maskSliceM(minr:maxr, minc:maxc);

                        %Resize slice
                        resizedSliceM = imresize(croppedSliceM, outputImgSizeV,...
                            'nearest');
                    end
                    maskOut4M(:,:,slcNum) = resizedSliceM;
                end
            end
        end
        
        
        
    case 'none'
        scanOut3M = scan3M;
        maskOut4M = mask4M;
        
end


end

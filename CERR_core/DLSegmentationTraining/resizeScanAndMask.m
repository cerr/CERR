function [scanOut3M, rcsM] = resizeScanAndMask(scan3M,mask3M,inputImgSizeV,method)
% resizeScanAndMask.m
% Script to resize images and masks for deep learning.
%
% AI 7/2/19
%--------------------------------------------------------------------------
%INPUTS:
% scan3M       : Scan array
% mask3M       : Mask
% method       : Supported methods: 'none','pad2d', 'pad3d',
%                'bilinear', 'sinc'
% inputImgSizeV: Input size required by model [height, width]
%--------------------------------------------------------------------------
%RKP 9/13/19 - Added method 'pad2d'

rcsM = [];

switch(lower(method))
    
    case 'pad3d'
        xPad = floor(inputImgSizeV(1) - size(scan3M,1)/2);
        yPad = floor(inputImgSizeV(2) - size(scan3M,2)/2);
        
        scanOut3M = zeros(inputImgSizeV(1), inputImgSizeV(2), size(scan3M,3));
        scanOut3M(xPad+1:xPad+size(scan3M,1), yPad+1:yPad+size(scan3M,2), 1:size(scan3M,3)) = scan3M;
        
        if isempty(mask3M)
            maskOut3M = [];
        else
            maskOut3M = zeros(inputImgSizeV(1), inputImgSizeV(2), size(mask3M,3));
            maskOut3M(xPad+1:xPad+size(scan3M,1), yPad+1:yPad+size(scan3M,2), 1:size(scan3M,3)) = mask3M;
        end
        
    case 'pad2d'           
        [~, ~, ~, ~, mins, maxs] = compute_boundingbox(mask3M);
        scanOut3M = zeros(inputImgSizeV(1), inputImgSizeV(2), maxs-mins+1);                
        iSlc = 0;
        for slcNum = mins:maxs
            iSlc  = iSlc + 1;            
            [minr, maxr, minc, maxc] = compute_boundingbox(mask3M(:,:,slcNum));
            rowCenter = round((minr+maxr)/2);
            colCenter = round((minc+maxc)/2);
            rMin = rowCenter - inputImgSizeV(1)/2;
            cMin = colCenter - inputImgSizeV(2)/2;
            if rMin < 1
                rMin = 1;
            end
            if cMin < 1
                cMin = 1;
            end            
            rMax = rMin + inputImgSizeV(1) - 1;
            cMax = cMin + inputImgSizeV(2) - 1;
            scanOut3M(:,:,iSlc) = scan3M(rMin:rMax,cMin:cMax,slcNum);  
            rcsM(:,iSlc) = [rMin,rMax,cMin,cMax,slcNum];
        end        
        
    case 'bilinear'
        %Compute bounding box
        methodC = {cropS.method};
        if length(methodC) == 1 && any(strcmp(methodC,'none'))
            %if strcmpi(cropS.method,'none')
            minr = 1;
            maxr = size(modelMask3M,1);
            minc = 1;
            maxc = size(modelMask3M,2);
            mins = 1;
            maxs = size(modelMask3M,3);
        else
            [minr, maxr, minc, maxc, mins, maxs] = compute_boundingbox(modelMask3M);
        end
        
        %Crop scan and mask
        if ~isempty(scan3M)
            scan3M = scan3M(minr:maxr,minc:maxc,mins:maxs);
            
        end
        if ~isempty(mask3M)
            mask3M = mask3M(minr:maxr,minc:maxc,mins:maxs);
        end
        scanOut3M = imresize(scan3M, inputImgSizeV, 'bilinear');
        if isempty(mask3M)
            maskOut3M = [];
        else
            maskOut3M = imresize(mask3M, inputImgSizeV, 'nearest');
        end
        
    case 'sinc'
        %Compute bounding box
        methodC = {cropS.method};
        if length(methodC) == 1 && any(strcmp(methodC,'none'))
            %if strcmpi(cropS.method,'none')
            minr = 1;
            maxr = size(modelMask3M,1);
            minc = 1;
            maxc = size(modelMask3M,2);
            mins = 1;
            maxs = size(modelMask3M,3);
        else
            [minr, maxr, minc, maxc, mins, maxs] = compute_boundingbox(modelMask3M);
        end
        
        %Crop scan and mask
        if ~isempty(scan3M)
            scan3M = scan3M(minr:maxr,minc:maxc,mins:maxs);
            
        end
        if ~isempty(mask3M)
            mask3M = mask3M(minr:maxr,minc:maxc,mins:maxs);
        end
        scanOut3M = imresize(scan3M, inputImgSizeV, 'lanczos3');
        if isempty(mask3M)
            maskOut3M = [];
        else
            maskOut3M = imresize(mask3M, inputImgSizeV, 'nearest');
        end
        
    case 'none'
        scanOut3M = scan3M;
        sizV = size(scanOut3M);
        rcsM = repmat([1,sizV(1),1,sizV(2)],[sizV(3),1]);
        rcsM = [rcsM (1:sizV(3))'];
        
end


end
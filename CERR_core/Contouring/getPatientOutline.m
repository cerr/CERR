function ptMask3M = getPatientOutline(scan3M,slicesV,outThreshold,minMaskSiz)
% Returns mask of patient's outline
%
% Usage:
% global planC
% indexS = planC{end};
% scan3M = getScanArray(scanNum,planC);
% CToffset = planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
% scan3M = scan3M - CToffset;
% ptMask3M = getPatientOutline(scan3M,1:size(scan3M,3),0); %Returns mask for all slices by default
%
% AI 7/13/19


if ~exist('slicesV','var')
    slicesV = 1:size(scan3M,3);
end

if ~exist('minMaskSiz','var')
    minMaskSiz = 1500;
end

%Compute threshold
scanThreshV = scan3M(scan3M>outThreshold);
threshold = prctile(scanThreshV,5);
sizV = size(scan3M);
imageCenterRow = sizV(1)/2;
imageCenterCol = sizV(2)/2;

%% Extract mask
minDistV = nan([numel(slicesV),1]);
idxC = cell(1,numel(slicesV));
for n = 1:numel(slicesV)
    
    %Threshold image
    y = scan3M(:,:,slicesV(n))>threshold;
    y = imdilate(y,strel('disk',4,8));
    y = imfill(y,'holes');
    
    %Identify largest connected component
    cc = bwconncomp(y);
    ccSiz = cellfun(@numel,[cc.PixelIdxList]);
    %sel = ccSiz==max(ccSiz);
    
    %Exclude masks with fewer voxels than minMaskSiz 
    selV = find(ccSiz > minMaskSiz);
    
    %Record distance of centroid of largest CC from image center
    if ~isempty(selV)
        
        rowMedianV = nan(1,length(selV));
        colMedianV = nan(1,length(selV));
        for iSel = 1:length(selV)
            [rV,cV] = ind2sub(size(y),cc.PixelIdxList{selV(iSel)});
            rowMedianV(iSel) = median(rV);
            colMedianV(iSel) = median(cV);
        end
        distV = (rowMedianV - imageCenterRow).^2 + (colMedianV - imageCenterCol).^2 ;
        [minDistV(n),indMin] = min(distV);
        sel = selV(indMin);
        
        %Record pixel indices of largest CC
        idxC{n} = cc.PixelIdxList{sel};
    end
    
end


%If distance of row centroid of largest CC from image center is too large, 
%it is excluded

%- Compute mean & std deviation of distances of row centroids from image 
%center for all slices
globalMedianDist = nanmedian(minDistV); 
distDev = nanstd(minDistV,1);
%distDev = 50;

%- Filter slices if they deviate too much from image center
ptMask3M = false(size(scan3M));
for n = 1:numel(slicesV)
    
    maskM = false(size(y));

    %Check if deviation is within one std dev from global mean 
    if abs(minDistV(n)-globalMedianDist) < distDev  
        maskM(idxC{n}) = true;
    %If largest CC is far from centroid, use mask from previous slice
    elseif n >1
        maskM = ptMask3M(:,:,slicesV(n-1));
    end
    
    ptMask3M(:,:,slicesV(n)) = maskM;    
end

%--- Use finterp in future----
% %Fill in mask on missing slices
% maskSlicesV = squeeze(sum(sum(ptMask3M))>0);
% mins = find(maskSlicesV,1,'first');
% maxs = find(maskSlicesV,1,'last');
% maskSlicesV = mins : maxs;
% 
% missingIdxV = squeeze(sum(sum(ptMask3M(:,:,maskSlicesV)))==0);
% missingSlicesV = maskSlicesV(missingIdxV);
% 
% for n = 1:length(missingSlicesV)
%     
%     prevMaskM  = ptMask3M(:,:,missingSlicesV(n)-1);
%     nextMaskM = ptMask3M(:,:,missingSlicesV(n)+1);
%     
%     if sum(prevMaskM(:))==0
%         maskM = nextMaskM;
%     elseif sum(nextMaskM(:))==0
%         maskM = prevMaskM;
%     else
%         maskM = prevMaskM | nextMaskM;
%     end
%     
%     ptMask3M(:,:,missingSlicesV(n)) = maskM;
%     
% end

%% Morphological post-processing
ptMask3M = imfill(ptMask3M,26,'holes');
%Fuse disjointed segments
for n = 1:size(ptMask3M,3)
    labelM = double(ptMask3M(:,:,n));
    labelM = imclose(labelM,strel('disk',4));
    ptMask3M(:,:,n) = labelM;
end

end
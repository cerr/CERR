function ptMask3M = getPatientOutline(scan3M,slicesV,outThreshold)
% Returns mask of patient's outline
%
% Usage:
% global planC
% indexS = planC{end};
% scan3M = getScanArray(scanNum,planC);
% CToffset = planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
% scan3M = scan3M - CToffset;
% ptMask3M = getPatientOutline(scan3M); %Returns mask for all slices by default
%
% AI 7/13/19


if ~exist('slicesV','var')
    slicesV = 1:size(scan3M,3);
end


%Compute threshold
scanThreshV = scan3M(scan3M>outThreshold);
threshold = prctile(scanThreshV,5);
sizV = size(scan3M);
imageCenterRow = sizV(1)/2;

%% Extract mask
minMaskSiz = 1500;
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
        for iSel = 1:length(selV)
            [rV,~] = ind2sub(size(y),cc.PixelIdxList{selV(iSel)});
            rowMedianV(iSel) = median(rV);
        end
        distV = (rowMedianV - imageCenterRow).^2;
        [minDistV(n),indMin] = min(distV);
        sel = selV(indMin);
        
        %Record pixel indices of largest CC
        idxC{n} = cc.PixelIdxList{sel};
    end
    
end


%If distance of row centroid of largest CC from image center is too large, 
%it is excluded

%- Compute deviance of row centroid across all the slices
globalMeanDist = nanmean(minDistV); 
distDev = nanstd(minDistV,1);

ptMask3M = false(size(scan3M));
%- Filter slices if they deviate too much from the centroid
for n = 1:numel(slicesV)
    maskM = false(size(y));
    if minDistV(n) > globalMeanDist-distDev  ||  minDistV(n) < globalMeanDist+distDev    
        maskM(idxC{n}) = true;
    end
    ptMask3M(:,:,slicesV(n)) = maskM;    
end

%Fill in mask on missing slices
maskSlicesV = squeeze(sum(sum(ptMask3M))>0);
mins = find(maskSlicesV,1,'first');
maxs = find(maskSlicesV,1,'last');
maskSlicesV = mins : maxs;

missingIdxV = squeeze(sum(sum(ptMask3M(:,:,maskSlicesV)))==0);
missingSlicesV = maskSlicesV(missingIdxV);

for n = 1:length(missingSlicesV)
    
    prevMaskM  = ptMask3M(:,:,missingSlicesV(n)-1);
    nextMaskM = ptMask3M(:,:,missingSlicesV(n)+1);
    
    if sum(prevMaskM(:))==0
        maskM = nextMaskM;
    elseif sum(nextMaskM(:))==0
        maskM = prevMaskM;
    else
        maskM = prevMaskM & nextMaskM;
    end
    
    ptMask3M(:,:,missingSlicesV(n)) = maskM;
    
end


end
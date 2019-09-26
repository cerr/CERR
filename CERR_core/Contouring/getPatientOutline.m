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

minDistV = nan([numel(slicesV),1]);
idxC = cell(1,numel(slicesV));
for n = 1:numel(slicesV)
    
    y = scan3M(:,:,slicesV(n))>threshold;
    y = imdilate(y,strel('disk',4,8));
    y = imfill(y,'holes');
    
    
    cc = bwconncomp(y);
    ccSiz = cellfun(@numel,[cc.PixelIdxList]);
    %sel = ccSiz==max(ccSiz);
    
    % Select the component closest to image center
    selV = find(ccSiz > 1500);
    %maskM = false(size(y));
    if ~isempty(selV)
        
        rowMedianV = nan(1,length(selV));
        for iSel = 1:length(selV)
            [rV,~] = ind2sub(size(y),cc.PixelIdxList{selV(iSel)});
            rowMedianV(iSel) = median(rV);
        end
        distV = (rowMedianV - imageCenterRow).^2;
        [minDistV(n),indMin] = min(distV);
        sel = selV(indMin);
        
        idxC{n} = cc.PixelIdxList{sel};
    end
    
end

% Compute deviance of row centroid across all the slices
globalMeanDist = nanmean(minDistV); 
distDev = nanstd(minDistV,1);

ptMask3M = false(size(scan3M));
% Filter slices if they deviate too much from the centroid
for n = 1:numel(slicesV)
    maskM = false(size(y));
    if minDistV(n) > globalMeanDist-distDev  ||  minDistV(n) < globalMeanDist+distDev    
        maskM(idxC{n}) = true;
    end
    ptMask3M(:,:,slicesV(n)) = maskM;    
end

end
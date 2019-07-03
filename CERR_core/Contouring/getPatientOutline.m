function ptMask3M = getPatientOutline(scan3M,slicesV)
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
ptMask3M = false(size(scan3M));
scanThresh3M = scan3M(scan3M>0);
threshold = prctile(scanThresh3M(:),5);

for n = 1:numel(slicesV)
    
    y = scan3M(:,:,slicesV(n))>threshold;
    y = imdilate(y,strel('disk',4,8));
    y = imfill(y,'holes');
    cc = bwconncomp(y);
    ccSiz = cellfun(@numel,[cc.PixelIdxList]);
    sel = ccSiz==max(ccSiz);
    
    %------------ Added for registered data---%
    if isempty(sel) | max(ccSiz)<10000
        maskM = false(size(y));
    else
    %-------------- End added------------------%
        idx = cc.PixelIdxList{sel};
        maskM = false(size(y));
        maskM(idx) = true;
    end
    
    ptMask3M(:,:,slicesV(n)) = maskM;
    
end

end
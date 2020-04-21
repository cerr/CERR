function ptMask3M = getPatientOutline(scan3M,slicesV,outThreshold,minMaskSiz)
% Returns mask of patient's outline
%
% Usage:
% global planC
% scanNum = 1;
% indexS = planC{end};
% scan3M = getScanArray(scanNum,planC);
% CToffset = planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
% scan3M = double(scan3M) - CToffset;
% ptMask3M = getPatientOutline(scan3M,1:size(scan3M,3),0); %Returns mask for all slices by default
%
% AI 7/13/19

%% Set default values
if ~exist('slicesV','var')
    slicesV = 1:size(scan3M,3);
end

if ~exist('minMaskSiz','var')
    minMaskSiz = 1500;
end

%% Mask out couch
couchStartIdx = getCouchLocationHough(scan3M);
sizV = size(scan3M);
couchMaskM = false(sizV(1),sizV(2));
couchMaskM(couchStartIdx:end,:) = true;

%% Mask out air

% Compute threshold
scanThreshV = scan3M(scan3M>outThreshold);
threshold = prctile(scanThreshV,5);

%Iterate over slices
ptMask3M = false([sizV(1:2),length(slicesV)]);
for n = 1:numel(slicesV)
    
    % Threshold image
    binM = scan3M(:,:,slicesV(n))>threshold;
    binM = binM & ~couchMaskM;
    
    % Fill holes
    binM = imdilate(binM,strel('disk',3,6));
    binM = imfill(binM,'holes');
    binM = imerode(binM,strel('disk',1,0));
    
    %Identify largest connected component
    cc = bwconncomp(binM);
    ccSiz = cellfun(@numel,[cc.PixelIdxList]);
    [maxCompSiz,largestCompIdx] = max(ccSiz);
    
    %Retain if > minMaskSiz
    maskM = false(size(binM));
    if maxCompSiz >= minMaskSiz
        idxV = cc.PixelIdxList{largestCompIdx};
        maskM(idxV) = true;
    end
    
    ptMask3M(:,:,slicesV(n)) = maskM;
    
end

end
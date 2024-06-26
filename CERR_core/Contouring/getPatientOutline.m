function connPtMask3M = getPatientOutline(scan3M,slicesV,outThreshold,...
                        minMaskSiz,normFlag)
% Returns mask of patient's outline
%-------------------------------------------------------------------------- 
% INPUTS
% scan3M
% slicesV
% outThreshold
% minMaskSiz
% normFlag
%--------------------------------------------------------------------------
% Usage:
% global planC
% scanNum = 1;
% indexS = planC{end};
% scan3M = getScanArray(scanNum,planC);
% CToffset = planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
% scan3M = double(scan3M) - CToffset;
% ptMask3M = getPatientOutline(scan3M,1:size(scan3M,3),0); %Returns mask for all slices by default
%--------------------------------------------------------------------------
% AI 7/13/19

%% Set default values
if ~exist('slicesV','var') || isempty(slicesV)
    slicesV = 1:size(scan3M,3);
end

if ~exist('minMaskSiz','var')|| isempty(minMaskSiz)
    minMaskSiz = 1500;
end

if ~exist('normFlag','var') || isempty(normFlag)
    normFlag = 0;
end


%% Mask out couch
couchStartIdx = getCouchLocationHough(scan3M);

sizV = size(scan3M);
couchMaskM = false(sizV(1),sizV(2));
couchMaskM(couchStartIdx:end,:) = true;

%% Mask out air
if normFlag
    scan3M = scan3M./(max(scan3M(:))+eps);
end

% Compute threshold
scanThreshV = scan3M(scan3M>outThreshold);
threshold = prctile(scanThreshV,5);
minInt = min(scan3M(:));

%Iterate over slices
ptMask3M = false([sizV(1:2),length(slicesV)]);
for n = 1:numel(slicesV)
    
    % Threshold image
    sliceM = scan3M(:,:,slicesV(n));
    threshM = sliceM>threshold;
    
    % Mask out couch
    binM = threshM & ~couchMaskM;
    
    % Separate pt outline from table
    binM = imopen(binM,strel('disk',5));
    
    % Fill holes in pt outline
    maskM = false(size(binM));
    if any(binM(:))
        
        %Identify largest connected component
        ccS = bwconncomp(binM);
        ccSiz = cellfun(@numel,[ccS.PixelIdxList]);
        [maxCompSiz,largestCompIdx] = max(ccSiz);
        
        %Retain if > minMaskSiz
        if maxCompSiz >= minMaskSiz
            
            idxV = ccS.PixelIdxList{largestCompIdx};
            maskM(idxV) = true;
            
            % Fill holes
            [keepIdxV,rowMaxV] = max(flipud(maskM));
            rowMaxIdx = size(binM,1) - min(rowMaxV(keepIdxV));
            sliceM(rowMaxIdx:end,:) = minInt;
            thresh2M = sliceM > 1.5*threshold;
            thresh2M = imfill(thresh2M,'holes');
            thresh2M = bwareaopen(thresh2M,200,8);
            thresh2M = morphClose(thresh2M,strel('disk',3));
            smoothedlabel3M = imboxfilt(double(thresh2M),5);
            maskM = smoothedlabel3M > 0.5;
            
        end
        
    end
    
    ptMask3M(:,:,slicesV(n)) = maskM;
    
end

%% 3D connected component filter
conn3dPtMask3M = false(size(ptMask3M));
ccS = bwconncomp(ptMask3M,26);
ccSiz = cellfun(@numel,[ccS.PixelIdxList]);
[~,largestCompIdx] = max(ccSiz);
idxV = ccS.PixelIdxList{largestCompIdx};
conn3dPtMask3M(idxV) = true;
connPtMask3M = conn3dPtMask3M;

%% 2D connected component filter to separate arms and other artifacts
% [numRows,numCols,numSlcs] = size(conn3dPtMask3M);
% connPtMask3M = false(numRows,numCols,numSlcs);

% for slc = 1:numSlcs
%     erodedSlc2M = imopen(conn3dPtMask3M(:,:,slc),strel('disk',10));
%     ccS = bwconncomp(erodedSlc2M,8);
%    cSiz = cellfun(@numel,[ccS.PixelIdxList]);
%    ccNumObjs = ccS.NumObjects;
%    fractionSizV = ccSiz/max(ccSiz);
%    if ccNumObjs > 1 && any(fractionSizV < 0.25)
%        
%        [~,largestCompIdx] = max(ccSiz);
%        idxV = ccS.PixelIdxList{largestCompIdx};
%        tmpSlcM = false(numRows,numCols);
%        tmpSlcM(idxV) = true;
%        connPtMask3M(:,:,slc) = tmpSlcM;
%    else
%        connPtMask3M(:,:,slc) = conn3dPtMask3M(:,:,slc);
%    end
%end


end
function [volToEval,maskBoundingBox3M,mask3M,minr,maxr,minc,maxc,mins,maxs,...
    uniqueSlices] = getROI(structNumV,rowMargin,colMargin,slcMargin,planC,randomShiftFlg)
% function [volToEval,maskBoundingBox3M,mask3M,minr,maxr,minc,maxc,mins,maxs,...
%     uniqueSlices] = getROI(structNum,rowMargin,colMargin,slcMargin,planC,randomShiftFlg)
%
% returns the roi around the passed structure, expanded by the passed
% margin parameters,
% 
% APA, 01/16/2017

if ~exist('planC','var')
    global planC
end
if ~exist('randomShiftFlg','var')
    randomShiftFlg = 0;
end

indexS = planC{end};

% Get the region of interest
rasterSegmentsM = [];
for structNum = structNumV
    rasterSegmentsM = [rasterSegmentsM; getRasterSegments(structNum,planC)];
end

scanNum = getStructureAssociatedScan(structNum,planC);
[mask3M, uniqueSlices]              = rasterToMask(rasterSegmentsM, scanNum, planC);
scanArray3M                         = getScanArray(planC{indexS.scan}(scanNum),planC);
scanArray3M = double(scanArray3M);
CTOffset = planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
scanArray3M = scanArray3M - CTOffset;

% expand the ROI
siz = size(scanArray3M);
[minr, maxr, minc, maxc]= compute_boundingbox(mask3M);
mins = min(uniqueSlices);
maxs = max(uniqueSlices);
minr = max(1,minr-rowMargin);
maxr = min(siz(1),maxr+rowMargin);
minc = max(1,minc-colMargin);
maxc = min(siz(2),maxc+colMargin);
mins = max(1,mins-slcMargin);
maxs = min(siz(3),maxs+slcMargin);

% Randomly shift in A-P and S-I directions by 70% of the margin
if randomShiftFlg
    minRshift = randi(round(rowMargin*0.5));
    maxRshift = randi(round(rowMargin*0.5));
    minSshift = randi(round(slcMargin*0.5));
    maxSshift = randi(round(slcMargin*0.5));
    maxr = maxr - maxRshift;
    minr = minr + minRshift;
    maxs = maxs - maxSshift;
    mins = mins + minSshift;
end

volToEval              = scanArray3M(minr:maxr,minc:maxc,mins:maxs);
volToEval = double(volToEval);
% Clip low intensities in L-R direction
croppedImg3M = bwareaopen(volToEval > -400, 100);
[~, ~, minc, maxc]= compute_boundingbox(croppedImg3M);
volToEval = volToEval(:,minc:maxc,:);
maskBoundingBox3M      = volToEval .^ 0;
% Pad the mask in S-I direction
mask3M = mask3M(minr:maxr,minc:maxc,:);
maskSiz = size(mask3M);
minSlc = min(uniqueSlices) - slcMargin;
numPadUp = length(min(uniqueSlices)-1:-1:max(1,minSlc));
maxSlc = max(uniqueSlices) + slcMargin;
numPadDwn = length(max(uniqueSlices)+1:1:min(siz(3),maxSlc));
zeroM = false(maskSiz(1),maskSiz(2));
mask3M = cat(3, repmat(zeroM,[1 1 numPadUp]), mask3M, ...
    repmat(zeroM,[1 1 numPadDwn]));


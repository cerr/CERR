function [volToEval,maskBoundingBox3M,mask3M,minr,maxr,minc,maxc,mins,maxs,...
    uniqueSlices] = getROI(structNum,rowMargin,colMargin,slcMargin,planC)
% function [volToEval,maskBoundingBox3M,mask3M,minr,maxr,minc,maxc,mins,maxs,...
%     uniqueSlices] = getROI(structNum,rowMargin,colMargin,slcMargin,planC)
%
% returns the roi around the passed structure, expanded by the passed
% margin parameters,
% 
% APA, 01/16/2017

if ~exist('planC','var')
    global planC
end
indexS = planC{end};

% Get the region of interest
[rasterSegments, planC, isError]    = getRasterSegments(structNum,planC);
scanNum = getStructureAssociatedScan(structNum,planC);
[mask3M, uniqueSlices]              = rasterToMask(rasterSegments, scanNum, planC);
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
volToEval              = scanArray3M(minr:maxr,minc:maxc,mins:maxs);
maskBoundingBox3M      = volToEval .^ 0;
volToEval = double(volToEval);

mask3M = mask3M(minr:maxr,minc:maxc,:);
maskSiz = size(mask3M);
minSlc = min(uniqueSlices) - slcMargin;
numPadUp = length(min(uniqueSlices)-1:-1:max(1,minSlc));
maxSlc = max(uniqueSlices) + slcMargin;
numPadDwn = length(max(uniqueSlices)+1:1:min(siz(3),maxSlc));
zeroM = false(maskSiz(1),maskSiz(2));
mask3M = cat(3, repmat(zeroM,[1 1 numPadUp]), mask3M, ...
    repmat(zeroM,[1 1 numPadDwn]));


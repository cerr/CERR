function [volToEval,maskBoundingBox3M,maskC,minr,maxr,minc,maxc,mins,maxs,...
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
    %minRshift = randi(round(rowMargin*0.5));
    %maxRshift = randi(round(rowMargin*0.5));
    minSshift = randi(round(slcMargin*0.5));
    maxSshift = randi(round(slcMargin*0.5));
    %maxr = maxr - maxRshift;
    %minr = minr + minRshift;
    maxs = maxs - maxSshift;
    mins = mins + minSshift;
end

volToEval              = scanArray3M(minr:maxr,minc:maxc,mins:maxs);
volToEval = double(volToEval);
% Clip low intensities in L-R direction
croppedImg3M = bwareaopen(volToEval > -400, 100);
%Changed AI 12/14/18
[~, ~, minc2, maxc2]= compute_boundingbox(croppedImg3M);
volToEval = volToEval(:,minc2:maxc2,:);
minc = minc + minc2 - 1;
maxc = minc + maxc2 - 1;
maskBoundingBox3M      = volToEval .^ 0;

% Pad the mask in S-I direction
maskC = cell(1,length(structNumV));
for n = 1:length(structNumV)
    rasterSegmentsM = getRasterSegments(structNumV(n),planC);
    mask3M = false(siz);
    [mask,uqslices] = rasterToMask(rasterSegmentsM, scanNum, planC);
    mask3M(:,:,uqslices) = mask;
    mask3M = mask3M(minr:maxr,minc:maxc,mins:maxs); 
    mask3M = mask3M(:,minc2:maxc2,:);
    maskC{n} = mask3M;
end







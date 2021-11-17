function positionMatrix = getDicomImageToPatientAffineMat(scanNum,planC)
% function positionMatrix = getDicomImageToPatientAffineMat(scanNum,planC)
% 
% Based on https://nipy.org/nibabel/dicom/dicom_orientation.html#dicom-slice-affine
%
% APA, 11/16/2021

if exist('planC','var')
    indexS = planC{end};
end
if isstruct(scanNum)
    scanS = scanNum;
else
    scanS = planC{indexS.scan}(scanNum);
end

ImageOrientationPatientV = scanS.scanInfo(1).imageOrientationPatient;

% Compute slice normal (n)
sliceNormV = ImageOrientationPatientV([2 3 1]) .* ImageOrientationPatientV([6 4 5]) ...
    - ImageOrientationPatientV([3 1 2]) .* ImageOrientationPatientV([5 6 4]);

% Calculate the distance of ‘ImagePositionPatient’ along the slice direction cosine
numSlcs = length(scanS.scanInfo);
distV = zeros(1,numSlcs);
for slcNum = 1:numSlcs
    ipp = scanS.scanInfo(slcNum).imagePositionPatient;
    distV(slcNum) = sum(sliceNormV .* ipp);
end

info1S = scanS.scanInfo(end);
info2S = scanS.scanInfo(end-1);

% sort z-values in ascending order since z increases from head
% to feet in CERR
[zV,zOrderV] = sort(distV);
%slice_distance = zV(2) - zV(1);
pos1V = info1S.imagePositionPatient; % mm
pos2V = info2S.imagePositionPatient; % mm
deltaPosV = pos2V-pos1V;
pixelSpacing = [info1S.grid2Units, info1S.grid1Units] * 10;

% Patient coordinate to DICOM image coordinate mapping
positionMatrix = [reshape(ImageOrientationPatientV,[3 2])*diag(pixelSpacing)...
    [deltaPosV(1) pos1V(1); deltaPosV(2) pos1V(2); deltaPosV(3) pos1V(3)]];
positionMatrix = [positionMatrix; 0 0 0 1];

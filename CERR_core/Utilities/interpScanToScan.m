function scanOut3M = interpScanToScan(baseScan,movScan,addToPlanCFlag,planC)
% function scanOut3M = interpScanToScan(baseScan,movScan,addToPlanCFlag,planC)
%
% This function interpolates movScan to baseScan grid by taking into
% account DICOM imageOrientation. baseScan and movScan must have sam eframe
% of reference for interpolation to be valid.
%
% baseScan = 1;
% movScan = 2;
% addToPlanCFlag = true;
% global planC % or load from file
% scanOut3M = interpScanToScan(baseScan,movScan,addToPlanCFlag,planC);
%
% APA, 3/7/2023

if ~exist('planC','var')
    global planC
end
indexS = planC{end};

% Check FOR
baseFOR = planC{indexS.scan}(baseScan).scanInfo(1).frameOfReferenceUID;
movFOR = planC{indexS.scan}(movScan).scanInfo(1).frameOfReferenceUID;

if ~isequal(baseFOR,movFOR)
    scanOut3M = [];
    return;
end

% Get physical (x,y,z) coordinates of baseScan in DICOM LPS
basePositionMatrix = planC{indexS.scan}(baseScan).Image2PhysicalTransM;
baseSizV = size(planC{indexS.scan}(baseScan).scanArray);
[rowM,colM] = meshgrid(1:baseSizV(1), 1:baseSizV(2));
rowColM = [rowM(:),colM(:)] - 1;
onesV = ones(size(rowColM,1),1);
numSlcVoxels = length(onesV);
xyzM = zeros(numSlcVoxels*baseSizV(3),4);
for slc = 1:baseSizV(3)
    rowColSlcM = [rowColM,onesV*(slc-1),onesV];
    xyzM(1+(slc-1)*numSlcVoxels:slc*numSlcVoxels,1:4) = (basePositionMatrix * rowColSlcM')';
end

% Get moving scan voxel indices (i,j,k) corresponding to (x,y,z) coordinates of the base scan
movSizV = size(planC{indexS.scan}(movScan).scanArray);
movPositionMatrix = planC{indexS.scan}(movScan).Image2PhysicalTransM;
ijkM = movPositionMatrix \ xyzM'; % col,row,slc
ijkM = round(ijkM);
nanV = sum(ijkM(1:3,:) < 0) > 0;
nanV = nanV | ijkM(2,:) > movSizV(1)-1 | ijkM(1,:) > movSizV(2)-1 | ijkM(3,:) > movSizV(3)-1;
indV = sub2ind(movSizV,ijkM(2,~nanV)+1,ijkM(1,~nanV)+1,ijkM(3,~nanV)+1);

% Get moving scan values at (i,j,k)
scanOut3M = zeros(baseSizV,'single');
movScan3M = single(planC{indexS.scan}(movScan).scanArray) - ...
    planC{indexS.scan}(movScan).scanInfo(1).CTOffset;
% slice order in cerr is opposite to dicom. (dicom 1st slice is inf, cerr 1st slice is sup)
% row, col order is same in cerr and dicom. i.e. (1st row, 1st col) is at the top left
% of the slice.
% Hence, flip moving scan along slice dim.
movScan3M = flip(movScan3M,3);
scanOut3M(~nanV) = movScan3M(indV);
scanOut3M = flip(scanOut3M,3);

% Add scan to planC
if addToPlanCFlag    
    [xVals, yVals, zVals] = getScanXYZVals(planC{indexS.scan}(baseScan));
    deltaXYZv = getScanXYZSpacing(baseScan,planC);
    zV = zVals(:);
    regParamsS.horizontalGridInterval = deltaXYZv(1);
    regParamsS.verticalGridInterval = deltaXYZv(2);
    regParamsS.coord1OFFirstPoint = xVals(1);
    regParamsS.coord2OFFirstPoint   = yVals(end);
    
    regParamsS.zValues  = zV;
    regParamsS.sliceThickness = [planC{indexS.scan}(baseScan).scanInfo(:).sliceThickness];
    
    assocTextureUID = '';
    scanType = [planC{indexS.scan}(movScan).scanType,'_interp_',...
        planC{indexS.scan}(baseScan).scanType];
    
    planC = scan2CERR(scanOut3M,scanType,'Passed',regParamsS,assocTextureUID,planC);
end

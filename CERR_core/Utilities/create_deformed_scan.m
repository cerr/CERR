function planC = create_deformed_scan(deformS, planC)
%
% function planC = create_deformed_scan(deformS)
%
% This function creates a new scan from the deformS object
%
% APA, 03/04/2014

global stateS
if ~exist('planC','var')
    global planC
end
indexS = planC{end};

[xValsd, yValsd, zValsd] = getDeformXYZVals(deformS);

[xValsM, yValsM] = meshgrid(xValsd, yValsd);

xV = xValsM(:);
clear xValsM
yV = yValsM(:);
clear yValsM
preRegTransM = planC{indexS.registration}(1).deformS(1).preRegTransM;
postRegTransM = planC{indexS.registration}(1).deformS(1).postRegTransM;
[xVals, yVals, zVals] = getScanXYZVals(planC{indexS.scan}(2));
minX = min(xVals);
minY = min(yVals);
minZ = min(zVals);
maxX = max(xVals);
maxY = max(yVals);
maxZ = max(zVals);
indStart = max(find((zValsd < minZ)));
indEnd = min(find((zValsd > maxZ)));
if isempty(indStart)
    indStart = 1;
end
if isempty(indEnd)
    indEnd = length(zValsd);
end

scanV = [];
for iZ = indStart:indEnd
    zV = zValsd(iZ)*xV.^0;
    [xT, yT, zT] = applyTransM(preRegTransM, xV, yV, zV);
    deltaX = deformS.xDeform3M(:,:,iZ);
    deltaY = deformS.yDeform3M(:,:,iZ);
    deltaZ = deformS.zDeform3M(:,:,iZ);    
    xT = xT(:) + deltaX(:);
    yT = yT(:) + deltaY(:);
    zT = zT(:) + deltaZ(:);
    [xT, yT, zT] = applyTransM(postRegTransM, xT, yT, zT);
    yT = yV - 2*(yT(:)-yV);
    zT = zV - 2*(zT(:)-zV);
    xT = xT(:);
    indZero = xT < minX | xT > maxX | yT < minY | yT > maxY | zT < minZ | zT > maxZ;
    sV = zeros(length(xT),1);
    sV(~indZero) = getScanAt(2, xT(~indZero), yT(~indZero), zT(~indZero), planC);
    scanV = [scanV; sV];
end

scanV = [zeros(length((1:indStart-1))*deformS.gridDimensions(2)*deformS.gridDimensions(1),1); scanV];
scanV = [scanV; zeros(length((indEnd:(length(zValsd)-1)))*deformS.gridDimensions(2)*deformS.gridDimensions(1),1)];
    

scan3M = reshape(scanV,[deformS.gridDimensions(2) deformS.gridDimensions(1) deformS.gridDimensions(3)]);

% Create new scan
ind = length(planC{indexS.scan}) + 1; 

%Create array of all zeros, size of y,x,z vals.
planC{indexS.scan}(ind).scanArray = uint16(scan3M);
planC{indexS.scan}(ind).scanType = planC{indexS.scan}(2).scanType;
planC{indexS.scan}(ind).scanUID = createUID('scan'); 
%planC{indexS.scan}(ind).uniformScanInfo = [];
%planC{indexS.scan}(ind).scanArrayInferior = [];
%planC{indexS.scan}(ind).scanArraySuperior = [];
%planC{indexS.scan}(ind).thumbnails = [];

scanInfo = initializeScanInfo;
scanInfo(1).grid2Units = double(deformS.gridResolution(1));
scanInfo(1).grid1Units = double(deformS.gridResolution(2));
scanInfo(1).sizeOfDimension1 = double(deformS.gridDimensions(2));
scanInfo(1).sizeOfDimension2 = double(deformS.gridDimensions(1));
scanInfo(1).xOffset = double(deformS.xOffset);
scanInfo(1).yOffset = double(deformS.yOffset);
scanInfo(1).imageType = planC{indexS.scan}(2).scanInfo(1).imageType;
scanInfo(1).CTOffset = planC{indexS.scan}(2).scanInfo(1).CTOffset;


sliceThickness = double(deformS.gridResolution(3));

%Populate scanInfo(1) array.
for i=1:length(zValsd)
    scanInfo(1).sliceThickness = sliceThickness;
    scanInfo(1).zValue = zValsd(i);
    planC{indexS.scan}(ind).scanInfo(i) = scanInfo(1);
end

if ~isempty(stateS) 
    scanUID = ['c',repSpaceHyp(planC{indexS.scan}(ind).scanUID(max(1,end-61):end))];
    stateS.scanStats.minScanVal.(scanUID) = single(min(planC{indexS.scan}(ind).scanArray(:)));
    stateS.scanStats.maxScanVal.(scanUID) = single(max(planC{indexS.scan}(ind).scanArray(:)));
end

% Populate CERR Options
planC{indexS.CERROptions} = CERROptions;

planC = setUniformizedData(planC);


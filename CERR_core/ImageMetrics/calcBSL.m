function [SUVmax,SUVmean,BKG,BSL,Thresh,equiVol] = calcBSL(structNum,planC,plotHistogramFlag,plotWaterShedsFlag)
% function [SUVmax,SUVmean,BKG,BSL,Thresh,equiVol] = calcBSL(structNum,planC,plotHistogramFlag,plotWaterShedsFlag)
%
% APA, 07/01/2013. Based on code by Ross Schmidtlein.

indexS = planC{end};

% Get scanNum based on input stricture
scanNum = getStructureAssociatedScan(structNum,planC);

% Get voxel size
voxX = planC{indexS.scan}(scanNum).scanInfo(1).grid2Units;
voxY = planC{indexS.scan}(scanNum).scanInfo(1).grid1Units;
voxZ = planC{indexS.scan}.scanInfo(1).sliceThickness;
voxVol = voxX*voxY*voxZ;

% Get PET data
PT = double(planC{indexS.scan}(scanNum).scanArray);

% sets minimum 3D VOI size using 6-voxel conectivity
minRegionSize = 71*(size(PT,1)/128)^2;

%structNum = 1;

%subplot(14,14,iplot)

% Get VOI mask from Structure and associate PET data
uSlices = []; maskRTS = []; maskRTStmp = [];
scanNum                     = getStructureAssociatedScan(structNum,planC);
[rasterSeg, planC, isError] = getRasterSegments(structNum,planC);
if isempty(rasterSeg)
    warning('Could not create conotour.')
    return
end
[maskRTStmp, uSlices]      = rasterToMask(rasterSeg, scanNum, planC);
maskRTS = double(maskRTStmp);
maskRTS = bwareaopen(maskRTS,minRegionSize,6); % remove stray contour fragments
numel(nonzeros(maskRTS));
rtsPT = PT(:,:,uSlices);

% Estimate BSL
[BSL, BKG, Thresh, equiVol, wsPT, bsl] = ...
    BSLestimate(rtsPT,double(maskRTS),voxVol);

SUVmean = BSL/equiVol;
SUVmax = max(nonzeros(maskRTS.*rtsPT));

PTthresh = wsPT.*rtsPT;
PTthresh(PTthresh < Thresh*max(PTthresh(:))) = 0;

% Visualization
regionPT = rtsPT; regionPT(regionPT < 0.1) = 0; regionPT(regionPT > 0) = 1;
s0 = regionprops(regionPT, {'Centroid','BoundingBox'});
x0(1) = s0.BoundingBox(2); x0(2) = s0.BoundingBox(2+3);
y0(1) = s0.BoundingBox(1); y0(2) = s0.BoundingBox(1+3);
z0(1) = s0.BoundingBox(3); z0(2) = s0.BoundingBox(3+3);
X = floor( x0(1) + 1:x0(1) + x0(2) );
Y = floor( y0(1) + 1:y0(1) + y0(2) );
Z = floor( z0(1) + 1:z0(1) + z0(2) );


% Plots
if plotHistogramFlag
    sBSL = smooth(bsl, max(ceil(numel(bsl)/15),8));
    figure,plot(bsl,'-k'), hold on
    plot(sBSL,'-r')
    title('BSL Histogram')
end

if plotWaterShedsFlag
    
    imMatThresh = []; imMatRegion = []; imMat = []; imMat2 = [];
    for i = 1:numel(Z)
        imMatThresh = [imMatThresh maskRTS(X,Y,i).*PTthresh(X,Y,i)];
        imMatRegion = [imMatRegion wsPT(X,Y,i).*rtsPT(X,Y,i)];
        imMat       = [imMat       maskRTS(X,Y,i).*rtsPT(X,Y,i)];
        imMat2      = [imMat2      rtsPT(X,Y,i)];
    end
    figure,imshow([imMatThresh ; imMatRegion ; imMat ; imMat2],[0 3*BKG]);
    title('Progression of watersheds')
    drawnow
end

% Output results
% [iFile SUVmax(iFile) SUVmean(iFile) BKG(iFile) BSL(iFile) Thresh(iFile) equiVol(iFile)]
structName = planC{indexS.structures}(structNum).structureName;
disp('StructureName     SUV-max       SUV-mean       BKG      BSL     Thresh     equiVol')
disp([structName '   ' num2str(SUVmax) '   ' num2str(SUVmean) '   ' num2str(BKG) '   ' num2str(BSL) '   ' num2str(Thresh) '   ' num2str(equiVol)])



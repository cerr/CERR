function ivhFeaturesS = getIvhParams(structNum, scanSet, IVHBinWidth,...
    xForIxV, xAbsForIxV, xForVxV, xAbsForVxV, planC)
% function ivhFeaturesS = getIvhParams(structNum, scanSet, IVHBinWidth,...
%     xForIxV, xAbsForIxV, xForVxV, xAbsForVxV, planC)
%
% This function calculates the IVH based features. The inputs can be based
% on planC or the raw voxel data.
%
% INPUTS:
% structNum:    The index of structure within planC (or scanV, i.e. 1-d array
%               of scan values for all the voxels)   
% scanSet:      The index of scan within planC  (or volsV, i.e. 1-d array
%               of corresponding scan voxel volumes) 
% IVHBinWidth:  The bin width for IVH (histogram) calculation
% xForIxV:      1-d array of percent volume cutoffs for Ix, MOHx and MOCx
% xAbsForIxV:   1-d array of absolute colume (cc) cutoffs for Ix
% xForVxV:      1-d array of percent dose cutoffs for Vx
% xAbsForVxV:   1-d array of absolute dose cutoffs for Vx
% planC:        CERR's planC data structure
%
% NOTE for passing the raw scan data instead of planC:
% In case of using the raw scan data instead of planC, pass scan and the
% volume of each voxel as 1-d arrays. structNum should be 1-d array containing
% scan value at each voxel and scanSet should be 1-d array containing
% the corresponding volumes for the scan voxels. For alomst all the medical
% images, the voxels are of same size, resulting in repeatitive values
% for voxel volumes. The planC input argument is not required in this case.
%
% APA, 03/31/2017

if ~exist('planC','var')
    scansV = structNum;
    volsV = scanSet;
else
    indexS = planC{end};
    [scansV, volsV] = getIVH(structNum, scanSet, planC);
    if isfield(planC{indexS.scan}(scanSet).scanInfo(1),'CTOffset')
        offset = planC{indexS.scan}(scanSet).scanInfo(1).CTOffset;
    else
        offset = 0;
    end
    scansV = scansV - offset;
end

% Return NaNs if empty
if nnz(scansV)<2
    ivhFeaturesS.meanHist = NaN;
    ivhFeaturesS.maxHist = NaN;
    ivhFeaturesS.minHist = NaN;
    ivhFeaturesS.I50 = NaN;
    ivhFeaturesS.rangeHist = NaN;
    ivhFeaturesS.IVHBinWidth = NaN;
    
    for i = 1:length(xForIxV)
        ivhFeaturesS.Ix(i) = NaN;
        ivhFeaturesS.xIx(i) = NaN;
        ivhFeaturesS.MOHx(i) = NaN;
        ivhFeaturesS.xMOHx(i) = NaN;
        ivhFeaturesS.MOCx(i) = NaN;
        ivhFeaturesS.xMOCx(i) = NaN;
    end
    for i = 1:length(xAbsForIxV)
        ivhFeaturesS.IabsX(i) = NaN;
        ivhFeaturesS.xIabsX(i) = NaN;
    end
    for i = 1:length(xForVxV)
        ivhFeaturesS.Vx(i) = NaN;
        ivhFeaturesS.xVx(i) = NaN;
    end
    for i = 1:length(xAbsForVxV)
        ivhFeaturesS.VabsX(i) = NaN;
        ivhFeaturesS.xVabsX(i) = NaN;
    end
    return
end

% Compute histogram
[scanBinsV, volsHistV] = doseHist(scansV, volsV, IVHBinWidth);

% calculate stats
ivhFeaturesS.meanHist = calc_meanDose(scanBinsV, volsHistV);
ivhFeaturesS.maxHist =  calc_maxDose(scanBinsV, volsHistV);
ivhFeaturesS.minHist =  calc_minDose(scanBinsV, volsHistV);
ivhFeaturesS.I50 = calc_Dx(scanBinsV, volsHistV,50);
ivhFeaturesS.IVHBinWidth = IVHBinWidth;
% ivhFeaturesS.slopeAtD50 = calc_Slope(scanBinsV, volsHistV, ivhFeaturesS.I50, 0);

ivhFeaturesS.rangeHist = ivhFeaturesS.maxHist - ivhFeaturesS.minHist;
absFlag = 1;

for i = 1:length(xForIxV)
    ivhFeaturesS.Ix(i) = calc_Dx(scanBinsV, volsHistV, xForIxV(i));
    ivhFeaturesS.xIx(i) = xForIxV(i);
    ivhFeaturesS.MOHx(i) = calc_MOHx(scanBinsV, volsHistV, xForIxV(i));
    ivhFeaturesS.xMOHx(i) = xForIxV(i);
    ivhFeaturesS.MOCx(i) = calc_MOCx(scanBinsV, volsHistV, xForIxV(i));
    ivhFeaturesS.xMOCx(i) = xForIxV(i);
end
for i = 1:length(xAbsForIxV)
    ivhFeaturesS.IabsX(i) = calc_Dx(scanBinsV, volsHistV, xAbsForIxV(i), absFlag);
    ivhFeaturesS.xIabsX(i) = xAbsForIxV(i);
end
for i = 1:length(xForVxV)
    absImgVal = xForVxV(i)*ivhFeaturesS.rangeHist/100 + ivhFeaturesS.minHist;
    ivhFeaturesS.Vx(i) = calc_Vx(scanBinsV, volsHistV, absImgVal);
    ivhFeaturesS.xVx(i) = xForVxV(i);
end
for i = 1:length(xAbsForVxV)
    ivhFeaturesS.VabsX(i) = calc_Vx(scanBinsV, volsHistV, xAbsForVxV(i));
    ivhFeaturesS.xVabsX(i) = xAbsForVxV(i);
end

return


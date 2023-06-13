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
        ivhFeaturesS.(['Ix',num2str(xForIxV(i))]) = NaN;
        ivhFeaturesS.(['MOHx',num2str(xForIxV(i))]) = NaN;
        ivhFeaturesS.(['MOCx',num2str(xForIxV(i))]) = NaN;
    end
    for i = 1:length(xAbsForIxV)
        ivhFeaturesS.(['IabsX',num2str(xAbsForIxV(i))]) = NaN;
    end
    for i = 1:length(xForVxV)
        ivhFeaturesS.(['Vx',num2str(xForVxV(i))]) = NaN;
    end
    for i = 1:length(xAbsForVxV)
        ivhFeaturesS.(['VabsX',num2str(xAbsForVxV(i))]) = NaN;
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
%ivhFeaturesS.IVHBinWidth = IVHBinWidth;
% ivhFeaturesS.slopeAtD50 = calc_Slope(scanBinsV, volsHistV, ivhFeaturesS.I50, 0);

ivhFeaturesS.rangeHist = ivhFeaturesS.maxHist - ivhFeaturesS.minHist;
normalizeVxByVolumeFlag = 1; % pass as input arg?

for i = 1:length(xForIxV)
    xString = num2str(xForIxV(i));
    ivhFeaturesS.(repSpaceHyp(['Ix',xString])) = calc_Dx(scanBinsV, volsHistV, xForIxV(i));
    ivhFeaturesS.(repSpaceHyp(['MOHx',xString])) = calc_MOHx(scanBinsV, volsHistV, xForIxV(i));
    ivhFeaturesS.(repSpaceHyp(['MOCx',xString])) = calc_MOCx(scanBinsV, volsHistV, xForIxV(i));
end
absFlag = 1;
for i = 1:length(xAbsForIxV)
    ivhFeaturesS.(repSpaceHyp(['IabsX',strrep(num2str(xAbsForIxV(i)),'-','Minus')])) = calc_Dx(scanBinsV, volsHistV, xAbsForIxV(i), absFlag);
end
for i = 1:length(xForVxV)
    absImgVal = xForVxV(i)*ivhFeaturesS.rangeHist/100 + ivhFeaturesS.minHist;    
    ivhFeaturesS.(repSpaceHyp(['Vx',num2str(xForVxV(i))])) = calc_Vx(scanBinsV, ...
        volsHistV, absImgVal, normalizeVxByVolumeFlag);
end
for i = 1:length(xAbsForVxV)
    ivhFeaturesS.(repSpaceHyp(['VabsX',num2str(xAbsForVxV(i))])) = calc_Vx(scanBinsV, ...
        volsHistV, xAbsForVxV(i), normalizeVxByVolumeFlag);
end

return


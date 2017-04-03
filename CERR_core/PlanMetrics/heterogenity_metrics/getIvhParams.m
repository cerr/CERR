function ivhFeaturesS = getIvhParams(structNum, scanSet, IVHBinWidth,...
    xForIxV, xAbsForIxV, xForVxV, xAbsForVxV, planC)
% function ivhFeaturesS = getIvhParams(structNum, scanSet, IVHBinWidth,...
%     xForIxV, xAbsForIxV, xForVxV, xAbsForVxV, planC)
%
% IVH based features
%
% APA, 03/31/2017

if ~exist('planC','var')
    scansV = structNum;
    volsV = scanSet;
else
    indexS = planC{end};
    [scansV, volsV] = getIVH(structNum, scanSet, planC);
end

% Compute histogram
[scanBinsV, volsHistV] = doseHist(scansV, volsV, IVHBinWidth);

% calculate stats
ivhFeaturesS.meanHist = calc_meanDose(scanBinsV, volsHistV);
ivhFeaturesS.maxHist =  calc_maxDose(scanBinsV, volsHistV);
ivhFeaturesS.minHist =  calc_minDose(scanBinsV, volsHistV);
ivhFeaturesS.I50 = calc_Dx(scanBinsV, volsHistV,50);
ivhFeaturesS.slopeAtD50 = calc_Slope(scanBinsV, volsHistV, ivhFeaturesS.I50, 0);

ivhFeaturesS.rangeHist = ivhFeaturesS.maxHist - ivhFeaturesS.minHist;
absFlag = 1;

for i = 1:length(xForIxV)
    ivhFeaturesS.Ix(i) = calc_Dx(scanBinsV, volsHistV, xForIxV(i));
    ivhFeaturesS.MOHx(i) = calc_MOHx(scanBinsV, volsHistV, xForIxV(i));
    ivhFeaturesS.MOCx(i) = calc_MOCx(scanBinsV, volsHistV, xForIxV(i));
end
for i = 1:length(xAbsForIxV)
    ivhFeaturesS.IabsX(i) = calc_Dx(scanBinsV, volsHistV, xAbsForIxV(i), absFlag);
end
for i = 1:length(xForVxV)
    absImgVal = xForVxV(i)*ivhFeaturesS.rangeHist/100 + ivhFeaturesS.minHist;
    ivhFeaturesS.Vx(i) = calc_Vx(scanBinsV, volsHistV, absImgVal);
end
for i = 1:length(xAbsForVxV)
    ivhFeaturesS.VabsX(i) = calc_Vx(scanBinsV, volsHistV, xAbsForVxV(i));
end

return


% call_calcFeatureImpact.m
%
% script to call the feature impact calculator for RLM features
%
% APA, 6/13/2017

hPool = parpool(50);

structNum = 26;
scanNum = 3;

%minIntensity = -140;
%maxIntensity = 100;
%numGreyLevels = 100;

firstOrderParamsS = struct;
higherOrderParamS = struct;
shapeParamS = struct;
peakValleyParamS = struct;
ivhParamS = struct;

shapeParamS.rcsV = [100, 100, 100];
paramS.shapeParamS = shapeParamS;

higherOrderParamS.minIntensity = -140;
higherOrderParamS.maxIntensity = 100;
higherOrderParamS.numGrLevels = 100;
higherOrderParamS.patchRadius2dV = [1 1 0];
higherOrderParamS.imgDiffThresh = 0;
higherOrderParamS.patchRadius3dV = [1 1 1];
paramS.higherOrderParamS = higherOrderParamS;

peakValleyParamS.peakRadius = [2 2 0];
paramS.peakValleyParamS = peakValleyParamS;

ivhParamS.xAbsForVxV =  -140:10:100; % CT;, 0:2:28; % PET
ivhParamS.xForIxV = 10:10:90; % percentage volume
ivhParamS.xAbsForIxV = 10:20:200; % absolute volume [cc]
ivhParamS.xForVxV = 10:10:90; % percent intensity cutoff
paramS.ivhParamS = ivhParamS;

whichFeatS = struct;
whichFeatS.shape = 0;
%whichFeatS.highOrder = 1;
whichFeatS.harFeat2Ddir = 0;
whichFeatS.harFeat2Dcomb = 0;
whichFeatS.harFeat3Ddir = 0;
whichFeatS.harFeat3Dcomb = 0;
whichFeatS.rlmFeat2Ddir = 1;
whichFeatS.rlmFeat2Dcomb = 0;
whichFeatS.rlmFeat3Ddir = 0;
whichFeatS.rlmFeat3Dcomb = 0;
whichFeatS.ngtdmFeatures2d = 0;
whichFeatS.ngtdmFeatures3d = 0;
whichFeatS.ngldmFeatures2d = 0;
whichFeatS.ngldmFeatures3d = 0;
whichFeatS.szmFeature2d = 0;
whichFeatS.szmFeature3d = 0;
whichFeatS.firstOrder = 0;
whichFeatS.ivh = 0;
whichFeatS.peakValley = 0;
paramS.whichFeatS = whichFeatS;
featureS(dirNum) = calcGlobalRadiomicsFeatures(scanNum, structNum,...
    paramS, planC);
featureFun = @calcGlobalRadiomicsFeatures;
featureName = 'rlmFeat2DdirS.MaxS.lrhgle';
patchRadiusV = [1 1 0];
feature3M = calcFeatureImpact(scanNum, structNum, ...
    patchRadiusV, featureFun, featureName, planC, paramS);

delete(hPool)


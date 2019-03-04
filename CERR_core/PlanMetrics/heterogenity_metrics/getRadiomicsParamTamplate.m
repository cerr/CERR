function radiomicsParamS = getRadiomicsParamTamplate()
% function radiomicsParamS = getRadiomicsParamTamplate()
%
% template parameters for radiomics feature extraction
%
% APA, 2/27/2019

%% Calculation Parameters

firstOrderParamS = struct;
higherOrderParamS = struct;
shapeParamS = struct;
peakValleyParamS = struct;
ivhParamS = struct;

firstOrderParamS.offsetForEnergy = 1000;
firstOrderParamS.binWidthEntropy = 25;
radiomicsParamS.firstOrderParamS = firstOrderParamS;

shapeParamS.rcsV = []; %stateS.optS.shape_rcsV; %[100, 100, 100];
radiomicsParamS.shapeParamS = shapeParamS;

higherOrderParamS.minIntensity = []; %stateS.optS.higherOrder_minIntensity; %-140;
higherOrderParamS.maxIntensity = []; %stateS.optS.higherOrder_maxIntensity; %100;
higherOrderParamS.minIntensityCutoff = [];
higherOrderParamS.maxIntensityCutoff = [];
higherOrderParamS.numGrLevels = []; %stateS.optS.higherOrder_numGrLevels; %100;
higherOrderParamS.binwidth = 25;
higherOrderParamS.neighborVoxelOffset = 1;
higherOrderParamS.patchRadius2dV = [2 2 0]; %stateS.optS.higherOrder_patchRadius2dV; % [1 1 0];
higherOrderParamS.imgDiffThresh = 0; %stateS.optS.higherOrder_imgDiffThresh; %0;
higherOrderParamS.patchRadius3dV = [1 1 1]; %stateS.optS.higherOrder_patchRadius3dV; %[1 1 1];
radiomicsParamS.higherOrderParamS = higherOrderParamS;

peakValleyParamS.peakRadius = [2 2 0]; %stateS.optS.peakValley_peakRadius; %[2 2 0];
radiomicsParamS.peakValleyParamS = peakValleyParamS;

ivhParamS.xAbsForVxV =  []; %stateS.optS.ivh_xAbsForIxV; % -140:10:100; % CT;, 0:2:28; % PET
ivhParamS.xForIxV = []; %stateS.optS.ivh_xForIxV; % 10:10:90; % percentage volume
ivhParamS.xAbsForIxV = []; %stateS.optS.ivh_xAbsForIxV; % 10:20:200; % absolute volume [cc]
ivhParamS.xForVxV = []; %stateS.optS.ivh_xForVxV; % 10:10:90; % percent intensity cutoff
radiomicsParamS.ivhParamS = ivhParamS;

whichFeatS = struct;
whichFeatS.shape = 1;
%whichFeatS.highOrder = 1;
whichFeatS.harFeat2Ddir = 0;
whichFeatS.harFeat2Dcomb = 0;
whichFeatS.harFeat3Ddir = 1;
whichFeatS.harFeat3Dcomb = 0;
whichFeatS.rlmFeat2Ddir = 0;
whichFeatS.rlmFeat2Dcomb = 0;
whichFeatS.rlmFeat3Ddir = 1;
whichFeatS.rlmFeat3Dcomb = 0;
whichFeatS.ngtdmFeatures2d = 0;
whichFeatS.ngtdmFeatures3d = 1;
whichFeatS.ngldmFeatures2d = 0;
whichFeatS.ngldmFeatures3d = 1;
whichFeatS.szmFeature2d = 0;
whichFeatS.szmFeature3d = 1;
whichFeatS.firstOrder = 1;
whichFeatS.ivh = 0;
whichFeatS.peakValley = 1;
radiomicsParamS.whichFeatS = whichFeatS;

% Flag to quantize the input data
radiomicsParamS.toQuantizeFlag = 1;

% Flag to perturb scan and mask
radiomicsParamS.toPerturbScanAndMaskFlag = 1;

% Perturbation workflow
radiomicsParamS.perturbString = 'RV'; % any combination of TRVCV

% Resolution to resample data along the X dimension in cm
radiomicsParamS.resampVoxSizX = 0.1;

% Resolution to resample data along the Y dimension in cm
radiomicsParamS.resampVoxSizY = 0.1;

% Resolution to resample data along the Z dimension in cm
radiomicsParamS.resampVoxSizZ = 0.1;

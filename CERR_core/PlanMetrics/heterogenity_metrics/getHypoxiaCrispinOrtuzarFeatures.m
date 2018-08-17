function featureS = getHypoxiaCrispinOrtuzarFeatures(ctStructNum,petStructNum,planC)
% function feature = getHypoxiaCrispinOrtuzarFeatures(ctStructNum,petStructNum,planC)
%
% The resulting radiomic signature consisted of 
% (I) ‘P90’ for the PET structure, (II) RLM ‘lrhgle’ for the CT structure
%
% Reference: 
% Mireia Crispin-Ortuzar, Aditya Apte, Milan Grkovski, Jung Hun Oh, Nancy Y. Lee, Heiko SchÃ¶der, John L. Humm, Joseph O. Deasy,
% Predicting hypoxia status using a combination of contrast-enhanced computed tomography and [18F]-Fluorodeoxyglucose positron emission tomography radiomics features,
% Radiotherapy and Oncology, Volume 127, Issue 1, 2018, Pages 36-42.
% ISSN 0167-8140,
% https://doi.org/10.1016/j.radonc.2017.11.025.
%
% APA, 8/17/2018

if ~exist('planC','var')
    global planC
end

indexS = planC{end};

% Statistics P90
ctOffset = 0;
binwidth = 0.1;
statsFeatureS = radiomics_first_order_stats(planC,petStructNum,ctOffset,binwidth);
featureS.P90 = statsFeatureS.P90;


% RLM LRHGLE

% Parameters
numGrLevels = 100;
minIntensity = -100;
maxIntensity = 150;

scanNum = getStructureAssociatedScan(structNum, planC);

% Get structure
[rasterSegments, planC, isError]    = getRasterSegments(ctStructNum,planC);
[mask3M, uniqueSlices]              = rasterToMask(rasterSegments, scanNum, planC);
scanArray3M                         = getScanArray(planC{indexS.scan}(scanNum));
scanArray3M                         = double(scanArray3M) - planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
SUVvals3M                           = mask3M.*double(scanArray3M(:,:,uniqueSlices));
[minr, maxr, minc, maxc, mins, maxs]= compute_boundingbox(mask3M);
maskBoundingBox3M                   = mask3M(minr:maxr,minc:maxc,mins:maxs);

% Assign NaN to image outside mask
volToEval                           = SUVvals3M(minr:maxr,minc:maxc,mins:maxs);
volToEval(~maskBoundingBox3M)       = NaN;

% Quantize the volume of interest
quantizedM                          = imquantize_cerr(volToEval,numGrLevels,minIntensity,maxIntensity);
quantizedM(~maskBoundingBox3M)      = NaN;
numVoxels = sum(~isnan(quantizedM(:)));

% Run-length features
fieldsC = {'sre','lre','gln','glnNorm','rln','rlnNorm','rp','lglre',...
    'hglre','srlgle','srhgle','lrlgle','lrhgle','glv','rlv','re'};
valsC = {0,0,0,0,0,0,0,0,0,0,0,0,13,0,0,0};
rlmFlagS = cell2struct(valsC,fieldsC,2);

% Original image
rlmFeaturesS = get_rlm(dirctn, rlmType, quantizedM, ...
    numGrLevels, numVoxels, rlmFlagS);

featureS.rlmGln = rlmFeaturesS.AvgS.gln;

rlmFeaturesS = get_rlm(dirctn, rlmType, quantizedM, numGrLevels, numVoxels, rlmFlagS);

featureS.lrhgle = rlmFeaturesS.AvgS.lrhgle;

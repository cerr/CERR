function featureS = getNcomms5006Feature(structNum,planC)
% function feature = getNcomms5006Feature(structNum,planC)
%
% The resulting radiomic signature consisted of 
% (I) ‘Statistics Energy’ (Supplementary Methods Feature 1) describing the 
% overall density of the tumour volume, (II) ‘Shape Compactness’ (Feature 16) 
% quantifying how compact the tumour shape is, (III) ‘Grey Level Nonuniformity’ 
% (Feature 48) a measure for intratumour heterogeneity and (IV) wavelet 
% ‘Grey Level Nonuniformity HLH’ (Feature Group 4), 
% also describing intratumour heterogeneity after decomposing the 
% image in mid-frequencies. The weights of each of the features in the 
% signature were fitted on the training data set Lung1.
%
% Reference: 
% Aerts HJWL, Velazquez ER, Leijenaar RTH, et al. Decoding tumour phenotype
% by noninvasive imaging using a quantitative radiomics approach. Nature 
% Communications. 2014;5:4006. doi:10.1038/ncomms5006.
%
%
% APA, 5/20/2017

if ~exist('planC','var')
    global planC
end

indexS = planC{end};

% parameters
% nL = 32; % number of gray levels. Determined from the deltaIntensity.
dirctn = 1; % all 13 directions
binwidth = 25; % Create a level for every 25 HUs
rlmType = 2; % average contributions from all the offsets in the RLM.
waveletDirString = 'HLH'; % directionality for Wavelet filtering
waveletType = 'coif1'; % Wavelet type

if numel(structNum) == 1
    scanNum = getStructureAssociatedScan(structNum, planC);
    ctOffset = planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
    scan3M = double(planC{indexS.scan}(scanNum).scanArray) - double(ctOffset);
    mask3M = getUniformStr(structNum,planC);      
else
    scan3M = structNum;
    mask3M = ~isnan(structNum);
    ctOffset = 0; % assume that the input scan3M is already offset.
end

% Change datatype to 32-bit float
scan3M = double(scan3M);

numVoxels = sum(mask3M(:));

% Statistics Energy
%statsFeatureS = radiomics_first_order_stats(scan3M(mask3M));
statsFeatureS = radiomics_first_order_stats(planC,structNum,ctOffset,binwidth);
featureS.statsEnergy = statsFeatureS.totalEnergy;

% Shape Compactnes
shapeS = getShapeParams(structNum,planC);
featureS.shapeCompactness = shapeS.Compactness2;

% Grey Level Nonuniformity
% xmin = min(scan3M(mask3M));
% xmax = max(scan3M(mask3M));
% nL = ceil((xmax-xmin)/deltaIntensity);
[minr, maxr, minc, maxc, mins, maxs] = compute_boundingbox(mask3M);
maskWithinStr3M = mask3M(minr:maxr, minc:maxc, mins:maxs);
scanWithinStr3M = scan3M(minr:maxr, minc:maxc, mins:maxs);
% quantized3M = imquantize_cerr(scanWithinStr3M,nL,xmin,xmax);
% quantized3M(~maskWithinStr3M) = NaN;

minIntensity = [];
maxIntensity = [];
numGrLevels = [];
quantizedM = imquantize_cerr(scanWithinStr3M,numGrLevels,...
    minIntensity,maxIntensity,binwidth);
quantizedM(~maskWithinStr3M) = NaN;
numGrLevels = max(quantizedM(:));

% Run-length features
fieldsC = {'shortRunEmphasis','longRunEmphasis','grayLevelNonUniformity',...
    'grayLevelNonUniformityNorm','runLengthNonUniformity',...
    'runLengthNonUniformityNorm','runPercentage','lowGrayLevelRunEmphasis',...
    'highGrayLevelRunEmphasis','shortRunLowGrayLevelEmphasis',...
    'shortRunHighGrayLevelEmphasis','longRunLowGrayLevelEmphasis',...
    'longRunHighGrayLevelEmphasis','grayLevelVariance','runLengthVariance','runEntropy'};
valsC = {0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0};
rlmFlagS = cell2struct(valsC,fieldsC,2);

% Original image
rlmFeaturesS = get_rlm(dirctn, rlmType, quantizedM, ...
    numGrLevels, numVoxels, rlmFlagS);

featureS.rlmGln = rlmFeaturesS.AvgS.grayLevelNonUniformity;

% Wavelet filtered image
scan3M = flip(scan3M,3);
if mod(size(scan3M,3),2) > 0
    scan3M(:,:,end+1) = 0*scan3M(:,:,1);
end
normFlag = 0;
scan3M = wavDecom3D(double(scan3M),waveletDirString,waveletType,normFlag);
if mod(size(scan3M,3),2) > 0
    scan3M = scan3M(:,:,1:end-1);
end
scan3M = flip(scan3M,3);

scanWithinStr3M = scan3M(minr:maxr, minc:maxc, mins:maxs);
minIntensity = [];
maxIntensity = [];
numGrLevels = [];
quantizedM = imquantize_cerr(scanWithinStr3M,numGrLevels,...
    minIntensity,maxIntensity,binwidth);
numGrLevels = max(quantizedM(:));
quantizedM(~maskWithinStr3M) = NaN;
rlmFeaturesS = get_rlm(dirctn, rlmType, quantizedM, ...
    numGrLevels, numVoxels, rlmFlagS);

featureS.wavFiltRlmGln = rlmFeaturesS.AvgS.gln;



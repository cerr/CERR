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
deltaIntensity = 25; % Create a level for every 25 HUs
offsetsM = getOffsets(1); % 3d directions. (input arg 2 for 2d)
rlmType = 1; % combine contributions from all the offsets in the RLM.
waveletDirString = 'HLH';
waveletType = 'coif1';

if numel(structNum) == 1
    scanNum = getStructureAssociatedScan(structNum, planC);
    ctOffset = planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
    scan3M = double(planC{indexS.scan}(scanNum).scanArray) - double(ctOffset);
    mask3M = getUniformStr(structNum,planC);      
else
    scan3M = structNum;
    mask3M = ~isnan(structNum);
end

% Change datatype to 32-bit float
scan3M = double(scan3M);

numVoxels = sum(mask3M(:));

% Statistics Energy
statsFeatureS = radiomics_first_order_stats(scan3M(mask3M));
featureS.statsEnergy = statsFeatureS.totalEnergy;

% Shape Compactnes
rcsV = [50 50 50];
shapeS = getShapeParams(structNum,planC,rcsV);
featureS.shapeCompactness = shapeS.Compactness2;

% Grey Level Nonuniformity
xmin = min(scan3M(mask3M));
xmax = max(scan3M(mask3M));
nL = ceil((xmax-xmin)/deltaIntensity);
[minr, maxr, minc, maxc, mins, maxs] = compute_boundingbox(mask3M);
maskWithinStr3M = mask3M(minr:maxr, minc:maxc, mins:maxs);
scanWithinStr3M = scan3M(minr:maxr, minc:maxc, mins:maxs);
quantized3M = imquantize_cerr(scanWithinStr3M,nL,xmin,xmax);
quantized3M(~maskWithinStr3M) = NaN;
rlmM = calcRLM(quantized3M, offsetsM, nL, rlmType);
fieldsC = {'sre','lre','gln','glnNorm','rln','rlnNorm','rp','lglre',...
    'hglre','srlgle','srhgle','lrlgle','lrhgle','glv','rlv'};
valsC = {0,0,1,0,0,0,0,0,0,0,0,0,0,0,0};
rlmFlagS = cell2struct(valsC,fieldsC,2);
rlmFeaturesS = rlmToScalarFeatures(rlmM, numVoxels, rlmFlagS);
featureS.rlmGln = rlmFeaturesS.gln;

% Grey Level Nonuniformity HLH
%wname = 'db5';
%[Lo_D,Hi_D,Lo_R,Hi_R] = wfilters(wname);
%dwtOut = dwt3(X,'db1','mode','per'); % single level
%wdec = wavedec3(scan3M,1,'db1','mode','per');

scan3M = wavDecom3D(scan3M,waveletDirString,waveletType);
xmin = min(scan3M(mask3M));
xmax = max(scan3M(mask3M));
nL = ceil((xmax-xmin)/deltaIntensity);
scanWithinStr3M = scan3M(minr:maxr, minc:maxc, mins:maxs);
quantized3M = imquantize_cerr(scanWithinStr3M,nL,xmin,xmax);
quantized3M(~maskWithinStr3M) = NaN;
rlmM = calcRLM(quantized3M, offsetsM, nL, rlmType);
rlmFeaturesS = rlmToScalarFeatures(rlmM, numVoxels, rlmFlagS);
featureS.wavFiltRlmGln = rlmFeaturesS.gln;



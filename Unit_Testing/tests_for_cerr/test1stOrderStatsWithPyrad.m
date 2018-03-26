% this script tests 1st Order Statistics features between CERR and pyradiomics.
%
% RKP, 03/22/2018



% % Structure from planC
% global planC
% indexS = planC{end};
% scanNum     = 1;
% structNum   = 16;
% 
% [rasterSegments, planC, isError]    = getRasterSegments(structNum,planC);
% [mask3M, uniqueSlices]              = rasterToMask(rasterSegments, scanNum, planC);
% scanArray3M                         = getScanArray(planC{indexS.scan}(scanNum));
% 
% SUVvals3M                           = mask3M.*double(scanArray3M(:,:,uniqueSlices));
% [minr, maxr, minc, maxc, mins, maxs]= compute_boundingbox(mask3M);
% maskBoundingBox3M                   = mask3M(minr:maxr,minc:maxc,mins:maxs);
% volToEval                           = SUVvals3M(minr:maxr,minc:maxc,mins:maxs);
% volToEval(maskBoundingBox3M==0)     = NaN;
% 
% testM = imquantize_cerr(volToEval,nL);

% Number of Gray levels
nL = 16;

% Random n x n x n matrix
n = 20;
testM = rand(n,n,5);
testM = imquantize_cerr(testM,nL);
maskBoundingBox3M = testM .^0;

VoxelVol = 1; 
offsetForEnergy = 0;

%generate results from pyradiomics
teststruct = PyradWrapper(testM, maskBoundingBox3M);

%% CERR First order features
% firstOrderS = radiomics_first_order_stats...
%     (maskBoundingBox3M, VoxelVol, offsetForEnergy);
firstOrderS = radiomics_first_order_stats(testM(logical(maskBoundingBox3M)), 1, 0);

cerrFirstOrderV = [firstOrderS.energy, firstOrderS.totalEnergy, firstOrderS.interQuartileRange, ...
    firstOrderS.kurtosis+3, firstOrderS.max, firstOrderS.mean, firstOrderS.meanAbsDev, ...
    firstOrderS.median, firstOrderS.medianAbsDev, firstOrderS.min, ...
    firstOrderS.P10, firstOrderS.P90, firstOrderS.interQuartileRange, ...
    firstOrderS.robustMeanAbsDev, firstOrderS.rms, firstOrderS.skewness, ...
    firstOrderS.std, firstOrderS.var];
pyradFirstorderNamC = {'Energy', 'TotalEnergy','InterquartileRange','Kurtosis',...
    'Maximum', 'Mean','MeanAbsoluteDeviation','Median','medianAbsDev',...
    'Minimum','10Percentile','90Percentile','InterquartileRange',...
    'RobustMeanAbsoluteDeviation','RootMeanSquared','Skewness',...
    'StandardDeviation','Variance'};

pyradFirstorderNamC = strcat(['original', '_firstorder_'],pyradFirstorderNamC);

pyRadFirstOrderV = [];
for i = 1:length(pyradFirstorderNamC)
    if isfield(teststruct,pyradFirstorderNamC{i})
        pyRadFirstOrderV(i) = teststruct.(pyradFirstorderNamC{i});
    else
        pyRadFirstOrderV(i) = NaN;
    end
end

diffFirstOrderV = (cerrFirstOrderV - pyRadFirstOrderV) ./ cerrFirstOrderV * 100
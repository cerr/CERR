function [gre3M,planC] = calcGRE(baseScanNum,movScanNum,mask3M,windowV,planC)
%Usage: [gre3M,planC] = calcGRE(baseScanNum,movScanNum,mask3M,windowV,planC);

% AI, 08/13/2018
% AI, 8/16/18 Updated to handle NaNs

if ~exist('planC','var')
    global planC
end
indexS = planC{end};

%Get window size
rowWindow = windowV(1);
colWindow = windowV(2);
slcWindow = windowV(3);

%Compute absolute difference between scans
siz = size(planC{indexS.scan}(baseScanNum).scanArray);
sA1 = zeros(siz,'single');
sA2 = zeros(siz,'single');
meanSa1 = mean(single(planC{indexS.scan}(baseScanNum).scanArray(mask3M)));
sdSa1 = std(single(planC{indexS.scan}(baseScanNum).scanArray(mask3M)));
sA1(mask3M) = (single(planC{indexS.scan}(baseScanNum).scanArray(mask3M)) - meanSa1)/sdSa1;
meanSa2 = mean(single(planC{indexS.scan}(movScanNum).scanArray(mask3M)));
sdSa2 = std(single(planC{indexS.scan}(movScanNum).scanArray(mask3M)));
sA2(mask3M) = (single(planC{indexS.scan}(movScanNum).scanArray(mask3M)) - meanSa2)/sdSa2;
diff3M = abs(sA1 - sA2);


%Calc. patchwise mean, variance, entropy
neighbM = getImageNeighbours(diff3M,mask3M,rowWindow,colWindow,slcWindow);
numLevels = 16;
numNeighbours = rowWindow*colWindow*slcWindow;
meanV = nanmean(neighbM);
varV = var(neighbM,'omitnan');
freqM = hist(neighbM,numLevels);
probM = freqM./numNeighbours;
entropyV = -sum(probM.*log2(probM+eps));

%Calc GRE
gre3M = zeros(siz);
greV = entropyV/(median(entropyV)+eps) + meanV/(median(meanV)+eps) + varV/(median(varV)+eps);
greV = greV/ 3;
gre3M(mask3M) = greV;

%Store as dose
register = 'UniformCT';  %Currently only option supported.  Dose has the same shape as the uniformized CT scan.
doseError = [];
doseEdition = 'Generalized Registration Error';
overWrite = 'no';  %Overwrite the last CERR dose?
if ~exist('assocScanNum','var')
    assocScanNum = 1;
end
fractionGroupID = 'GRE';
assocScanUID = planC{indexS.scan}(assocScanNum).scanUID;
description = '';
planC = dose2CERR(gre3M,doseError,fractionGroupID,doseEdition,description,register,[],overWrite,assocScanUID,planC);

end
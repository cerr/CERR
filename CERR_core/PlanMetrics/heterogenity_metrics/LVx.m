function varAtDistX = LVx(structNum,varCalcDist,planC)
% function varAtDistX = LVx(structNum,varCalcDis,planC)
%
% This function calculates the variance of absolute difference between
% voxels within structure (structNum) that are x cm (varCalcDist) apart.
%
% APA, 10/03/2013

indexS = planC{end};

% Get scan associated with this structNum
scanNum = getStructureAssociatedScan(structNum, planC);

% Get x,y,z vals for this structure voxels
[rasterSegments, planC, isError] = getRasterSegments(structNum, planC);
[mask3M, uniqueSlices] = rasterToMask(rasterSegments,scanNum,planC);
[i,j,k] = find3d(mask3M);
[xValsScan, yValsScan, zValsScan] = getScanXYZVals(planC{indexS.scan}(scanNum));
structXvals = xValsScan(j);
structYvals = yValsScan(i);
structZvals = zValsScan(uniqueSlices(k));
scanStructV = getScanAt(scanNum, structXvals, structYvals, structZvals, planC);

% Randomly sample 1000 points
numSamples = 1000;
randIndV = randi(length(structXvals),numSamples,1);
samplePtsXv = structXvals(randIndV);
samplePtsYv = structYvals(randIndV);
samplePtsZv = structZvals(randIndV);
sampleScanV = getScanAt(scanNum, samplePtsXv, samplePtsYv, samplePtsZv, planC);

% calculate distance between sample points and the structure voxels
distM = sepsq([samplePtsXv(:) samplePtsYv(:) samplePtsZv(:)]', [structXvals(:) structYvals(:) structZvals(:)]');
distM = distM.^0.5;

% Get scan resolution
dx = abs(xValsScan(1) - xValsScan(2));
dy = abs(yValsScan(1) - yValsScan(2));
dz = abs(zValsScan(1) - zValsScan(2));
res = max([dx dy dz])/2;
%indM = distM >= varCalcDist - res & distM <= varCalcDist + res;
indM = distM <= varCalcDist + res;

if ~any(indM(:))
    varAtDistX = NaN;
    warning(['Cannot sample points that are at ',num2str(varCalcDist),' cm'])
    return;
end
    
sampleScanM = repmat(sampleScanV',[1 length(scanStructV)]);
scanStructM = repmat(scanStructV,[length(sampleScanV) 1]);
absScanDiffAllPtsM = abs(scanStructM - sampleScanM);
absScanDiffSampledPtsV = absScanDiffAllPtsM(indM);

% Calculate variance for the samples
varAtDistX = var(absScanDiffSampledPtsV);


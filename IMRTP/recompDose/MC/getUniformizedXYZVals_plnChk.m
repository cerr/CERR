function [xVals, yVals, zVals] = getUniformizedXYZVals(planC)
%"getUniformizedXYZVals"
%   Return the X Y and Z vals of the uniformized dataset.
%
%   These are arrays, with a value for each row, col and slice in the
%   uniformized dataset.
%
%   In case of any error accessing the data 0 is returned for all vals.
%
% JRA 11/14/03
%
% Usage: [xVals, yVals, zVals] = getUniformizedXYZVals(planC)

indexS = planC{end};

[xVals, yVals, junk] = getScanXYZVals(planC{indexS.scan}(1));

scanInfo = planC{indexS.scan}(1).scanInfo(1);
sizeArray = getUniformizedSize(planC);

uniformScanInfo = planC{indexS.scan}(1).uniformScanInfo;
nZSlices = sizeArray(3);
zVals = uniformScanInfo.firstZValue : uniformScanInfo.sliceThickness : uniformScanInfo.sliceThickness * (nZSlices-1) + uniformScanInfo.firstZValue;          

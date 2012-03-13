function [xVals, yVals, zVals] = getUniformScanXYZVals(scanStruct)
%"getUniformScanXYZVals"
%   Return the X Y and Z vals of the uniformized scan from the passed
%   scanStruct.
%
%   These are arrays, with a value for each row, col and slice in the
%   uniformized dataset.
%
%   In case of any error accessing the data 0 is returned for all vals.
%
% JRA 11/17/04
%
% Usage: [xVals, yVals, zVals] = getUniformScanXYZVals(scanStruct)


scanInfo = scanStruct.scanInfo(1);

sizeDim1 = scanInfo.sizeOfDimension1-1;
sizeDim2 = scanInfo.sizeOfDimension2-1;

xVals = scanInfo.xOffset - (sizeDim2*scanInfo.grid2Units)/2 : scanInfo.grid2Units : scanInfo.xOffset + (sizeDim2*scanInfo.grid2Units)/2;
yVals = fliplr(scanInfo.yOffset - (sizeDim1*scanInfo.grid1Units)/2 : scanInfo.grid1Units : scanInfo.yOffset + (sizeDim1*scanInfo.grid1Units)/2);

sizeArray = getUniformScanSize(scanStruct);

uniformScanInfo = scanStruct.uniformScanInfo;
nZSlices = sizeArray(3);
zVals = uniformScanInfo.firstZValue : uniformScanInfo.sliceThickness : uniformScanInfo.sliceThickness * (nZSlices-1) + uniformScanInfo.firstZValue;          
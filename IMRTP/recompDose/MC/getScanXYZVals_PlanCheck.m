function [xVals, yVals, zVals] = getScanXYZVals(scanStruct, slice)
%"getScanXYZVals"
%   Returns the x, y, and z values of the cols, rows, and slices of the
%   passed scanStruct.  If specified, slice determines which element of
%   scanInfo is used to determine the x and y vals.  If slice is invalid or
%   not specified, 1 is used.
%
%   REMINDER: These x,y,z values are the coordinates of the MIDDLE of the
%   voxels of the scan.  They are not the coordinates of the dividers
%   between the voxels.
%
%   By JRA 12/26/03
%
%   scanStruct      : ONE planC{indexS.scan} struct.
%   slice           : slice to base x,y vals on
%
% xVals yVals zVals : x,y,z Values for scan.
%
% Usage:
%   function [xVals, yVals, zVals] = getScanXYZVals(scanStruct, slice)

try
    scanInfo = scanStruct.scanInfo(slice);
catch
    scanInfo = scanStruct.scanInfo(1);
end

sizeDim1 = scanInfo.sizeOfDimension1-1;
sizeDim2 = scanInfo.sizeOfDimension2-1;

xVals = scanInfo.xOffset - (sizeDim2*scanInfo.grid2Units)/2 : scanInfo.grid2Units : scanInfo.xOffset + (sizeDim2*scanInfo.grid2Units)/2;
yVals = fliplr(scanInfo.yOffset - (sizeDim1*scanInfo.grid1Units)/2 : scanInfo.grid1Units : scanInfo.yOffset + (sizeDim1*scanInfo.grid1Units)/2);
zVals = [scanStruct.scanInfo.zValue];
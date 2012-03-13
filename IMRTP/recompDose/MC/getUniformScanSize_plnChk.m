function sizeArray = getUniformScanSize(scanStruct)
%"getUniformScanSize"
%   Return the size of the uniformized scan ([x y z]) for the passed
%   scanStruct.
%
%   If the uniformized data does not exist, returns [0 0 0].
%
% JRA 11/17/04
%
% Usage:
%   function sizeArray = getUniformScanSize(scanStruct)

try
	uniformScanInfo = scanStruct.uniformScanInfo;
	scanInfo = scanStruct.scanInfo(1);
	
	%Find number of slices in whole uniformized set.
	nCTSlices = abs(uniformScanInfo.sliceNumSup - uniformScanInfo.sliceNumInf) + 1;
	nSupSlices = size(scanStruct.scanArraySuperior, 3);
	if isempty(scanStruct.scanArraySuperior), nSupSlices = 0;, end
	nInfSlices = size(scanStruct.scanArrayInferior, 3);
	if isempty(scanStruct.scanArrayInferior), nInfSlices = 0;, end
	zSize = nCTSlices + nSupSlices + nInfSlices;
	xSize = scanInfo(1).sizeOfDimension2;
	ySize = scanInfo(1).sizeOfDimension1;

    uniformScanInfo.size = [xSize ySize zSize];
    scanStruct.uniformScanInfo = uniformScanInfo;
catch
    scanStruct.uniformScanInfo.size = [0 0 0];
end

sizeArray = scanStruct.uniformScanInfo.size;
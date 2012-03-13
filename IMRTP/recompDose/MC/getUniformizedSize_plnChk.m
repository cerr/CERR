function [sizeArray, planC] = getUniformizedSize(planC)
%"getUniformizedSize"
%   Return the size of the uniformized dataset ([x y z]) and store it in
%   planC{indexS.scan}.uniformScanInfo.size for future reference.
%
%   If the uniformized data does not exist, returns and stores [0 0 0].
%
% JRA 11/14/03
%
% Usage: [sizeArray, planC] = getUniformizedSize(planC)

indexS = planC{end};

try
	uniformScanInfo = planC{indexS.scan}(1).uniformScanInfo;
	scanInfo = planC{indexS.scan}(1).scanInfo(1);
	
	%Find number of slices in whole uniformized set.
	nCTSlices = abs(uniformScanInfo.sliceNumSup - uniformScanInfo.sliceNumInf) + 1;
	nSupSlices = size(planC{indexS.scan}(1).scanArraySuperior, 3);
	if isempty(planC{indexS.scan}(1).scanArraySuperior), nSupSlices = 0;, end
	nInfSlices = size(planC{indexS.scan}(1).scanArrayInferior, 3);
	if isempty(planC{indexS.scan}(1).scanArrayInferior), nInfSlices = 0;, end
	zSize = nCTSlices + nSupSlices + nInfSlices;
	xSize = scanInfo(1).sizeOfDimension2;
	ySize = scanInfo(1).sizeOfDimension1;

    uniformScanInfo.size = [xSize ySize zSize];
    planC{indexS.scan}(1).uniformScanInfo = uniformScanInfo;
catch
    planC{indexS.scan}(1).uniformScanInfo.size = [0 0 0];
end

sizeArray = planC{indexS.scan}(1).uniformScanInfo.size;
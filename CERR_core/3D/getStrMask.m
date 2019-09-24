function mask3M = getStrMask(structNum, planC)
% function mask3M = getStrMask(structNum, planC)
%
% This function returns the 3D mask that is of the same size as the scan
% dimensions for the passed structure number
%
% INPUT: 
% structNum - structure index within planC
% 


scanNum = getStructureAssociatedScan(structNum, planC);
mask3M = false(size(getScanArray(scanNum,planC)));
rasterM = getRasterSegments(structNum,planC);
[slMask3M,slicesV] = rasterToMask(rasterM,scanNum,planC);
mask3M(:,:,slicesV) = slMask3M;




function [mask3M, planC] = getStrMask(structNumV, planC)
% function mask3M = getStrMask(structNumV, planC)
%
% This function returns the 3D mask that is of the same size as the scan
% dimensions for the passed structure numbers
%
% INPUT: 
% structNumV - structure indices within planC
% 

scanNum = getStructureAssociatedScan(structNumV(1), planC);
mask3M = false(size(getScanArray(scanNum,planC)));
[rasterM, planC] = getRasterSegments(structNumV,planC);
if ~isempty(rasterM)
    [slMask3M,slicesV] = rasterToMask(rasterM,scanNum,planC);
    mask3M(:,:,slicesV) = slMask3M;
end

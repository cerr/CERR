function sliceThicknessV = deduceSliceWidths(planC,scanNum)
%function sliceThicknessV = deduceSliceWidths(planC)
%
%This function deduces slice thicknesses when the treatment planning system
%provides only z Values.
%
%
%Created:  30 Apr 03, JOD.
% copyright (c) 2001-2006, Washington University in St. Louis.
% Permission is granted to use or modify only for non-commercial, 
% non-treatment-decision applications, and further only if this header is 
% not removed from any file. No warranty is expressed or implied for any 
% use whatever: use at your own risk.  Users can request use of CERR for 
% institutional review board-approved protocols.  Commercial users can 
% request a license.  Contact Joe Deasy for more information 
% (radonc.wustl.edu@jdeasy, reversed).
indexS = planC{end};

zValuesV = [planC{indexS.scan}(scanNum).scanInfo(:).zValue];

sliceThicknessV = ones(size(zValuesV)) * nan;

for i = 2 : length(zValuesV) - 1
  nextDelta = abs(zValuesV(i+1) - zValuesV(i));
  sliceThicknessV(i) = nextDelta;
end
if length(zValuesV) > 1
    sliceThicknessV(1) = 2 * (abs(zValuesV(2) - zValuesV(1)) - 0.5 * sliceThicknessV(2));
    sliceThicknessV(end) = 2 * (abs(zValuesV(end) - zValuesV(end - 1)) - 0.5 * sliceThicknessV(end - 1));
end

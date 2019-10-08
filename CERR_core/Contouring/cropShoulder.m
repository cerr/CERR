function maskZeroShoulders3M = cropShoulder(outerStrMask3M,planC)
% function maskZeroShoulders3M = cropShoulder(outerStrMask3M,planC)
%
% This function zeroes out the input mask inferior to patient shoulders.
%
% RKP 9/9/19
%
%------------------------------------------------------------------------
% INPUT
% outerStrMask3M : 3D mask of the patient outline.
%
% OUTPUT
% maskZeroShoulders3M      : 3D mask where slices inferior to shoulders are zeroed out.
%------------------------------------------------------------------------

[shoulderSliceNum,noseSliceNum] = getShoulderStartSlice(outerStrMask3M,planC);
maskZeroShoulders3M = outerStrMask3M;
maskZeroShoulders3M(:,:,shoulderSliceNum-3:end) = 0;
maskZeroShoulders3M(:,:,1:noseSliceNum) = 0;


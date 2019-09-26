function outMask3M = cropShoulder(outerStrMask3M,planC)
% Return mask with shoulders cropped
%
% RKP 9/9/19
%
%------------------------------------------------------------------------
% INPUT
% outerStrMask3M   : Mask of pt outline. Set to [] to use structure name
%                    instead.
%------------------------------------------------------------------------
sliceNum = getShoulderStartSlice(outerStrMask3M,planC);
outMask3M = outerStrMask3M;
outMask3M(:,:,sliceNum-15:end) = 0;
end
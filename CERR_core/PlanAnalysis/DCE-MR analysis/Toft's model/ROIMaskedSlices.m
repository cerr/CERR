function [maskedSlices, ROIRows, ROICols, ROIVoxels] = ROIMaskedSlices(inputSlices3M,maskM)
%  This function loads a 3D image array for masking with a single mask.
%  This could be an array of DCE images of one anatomic slice over time 
%  or an array of varied flip angle images at one slice for T1 calculation
%  The calling program supplies the slice mask from the 3D mask array.
%  This function generates a masked version of the 3D array and
%  it also returns the coordinates of each voxel in the ROI
%  and the total number of voxels in the ROI
%
%  Kristen Zakian
% 

% Get coordinates of in-ROI voxels
[ROIRows , ROICols] = find(maskM);     
% Get no. voxels in ROI
ROIVoxels = nnz(maskM);               

% Mask input array
%maskedSlices = bsxfun(@times, int16(maskM),int16(inputSlices));
maskedSlices = bsxfun(@times,maskM,double(inputSlices3M)); %CHANGED AI 2/7/17 
end
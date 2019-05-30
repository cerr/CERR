function ROIPointShift = getShiftFn(mSliceTcourse,maskM)
% This function plots the average ROI signal 
% (for first 20 time points) and returns the user-input point shift.
% -------------------------------------------------------------------------------
% AI
% Updated 8/9/17 (basepoints set to ROIPointShift-1 (when >1) and set to 1 otherwise (in getParams.m)

%Get avg value of in-ROI voxels for first 20 time points
maskM = logical(maskM);
sigAvgSlice = zeros(1,20);
numROIVox = nnz(maskM);
for t = 1:20
    maskedSliceM = mSliceTcourse(:,:,t);
    sigTotSliceV = sum(maskedSliceM(maskM));
    sigAvgSlice(t) = sigTotSliceV/numROIVox;       %Average of masked elements
end

%Plot the average ROI signal for slice
figtitle = 'Average ROI signal for slice';
figure ('Name', figtitle);
plot (0:19,sigAvgSlice,'--d');
ROIPointShift = input('\nInput the point shift (e.g. 2, to shift left 2 points):   ');
pause(4);
close(gcf)
%Enter no. of basepoints
%basepts = input('\nInput the no. of basepoints:   ');


end
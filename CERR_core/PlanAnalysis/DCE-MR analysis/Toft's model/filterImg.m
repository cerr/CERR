function fDCEData = filterImg(DCEData,fSize,fSigma)
% Program to apply a Gaussian lowpass filter of user-specified size and 
% std deviation, to the input image series.
% 
% DCEData   : Input image series.
% fSize     : Filter size.
% fSigma    : Filter standard deviation.
% 
% Kristen Zakian
% ----------------------------------------------------------------------

% Define filter
h = fspecial('gaussian', fSize, fSigma);

% Pre-allocate for output (filtered) image
fDCEData = zeros(size(DCEData));

% Filter input image
for idx = 1:size(DCEData,3)
    fDCEData(:,:,idx) = filter2(h,DCEData(:,:,idx));
end

end
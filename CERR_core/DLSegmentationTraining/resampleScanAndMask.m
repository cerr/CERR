function [outScan3M,outMask3M]  = resampleScanAndMask(scan3M,mask3M,outputImgSizeV,method)
% resampleScanAndMask.m
%
% Returns resampled scan and mask using input method.
% Supported methods include: sinc', 'cubic', 'linear', 'triangle'.
% Note: Masks are resampled using 'nearest' method.
%--------------------------------------------------------------------------
% INPUTS:
% scan3M         :  Scan array
% mask3M         :  Mask
% outputImgSizeV :  Required output size [numRows, numCols, numSlices].
% method         :  Supported methods: 'sinc','cubic','linear','triangle'.
%--------------------------------------------------------------------------
% AI 9/30/19

switch lower(method)
    case 'sinc'
        method = 'lanczos3';  %Lanczos-3 kernel
    case 'cubic'
        method = 'cubic';
    case 'linear'
        method = 'linear';
    case 'triangle'
        method = 'triangle';
    otherwise
        error('Interpolatin method not supported');
end

outScan3M = imresize3(scan3M,outputImgSizeV,'method',method);
outMask3M = imresize3(single(mask3M),outputImgSizeV,'method','nearest');

end
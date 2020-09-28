function [outScan3M,outMask3M,xResampleV,yResampleV,zResampleV] = ...
    resampleScanAndMask(scan3M,mask3M,inputResV,xValsV,yValsV,zValsV,...
    outputResV,method)
% resampleScanAndMask.m
%
% Returns resampled scan and mask using input method.
% Supported methods include: 'sinc','linear','cubic','nearest',
%                            'makima', and 'spline'.
% Note: Masks are resampled using 'nearest' method.
%--------------------------------------------------------------------------
% INPUTS:
% scan3M         :  Scan array
% mask3M         :  Mask
% inputResV      :  Input resolution (cm)
% xValsV         :  Input x grid vals (cm)
% yValsV         :  Input y grid vals (cm)
% zValsV         :  Input z grid vals (cm)
% outputResV     :  Output resolution (cm)
% method         :  Supported methods: 'sinc','cubic','linear','triangle',
%                   'spline', 'makima', 'nearest.
%--------------------------------------------------------------------------
% AI 9/30/19
% AI 9/24/20  Updated to call imgResample3d.m

extrapVal = 0;

%Resample scan
[outScan3M,xResampleV,yResampleV,zResampleV] = imgResample3d(scan3M,...
    inputResV,xValsV,yValsV,zValsV,outputResV,method,extrapVal);

%Resample mask
if ~isempty(mask3M)
    outMask3M = imgResample3d(mask3M,inputResV,xValsV,yValsV,zValsV,...
        outputResV,'nearest',extrapVal) >= 0.5;
else
    outMask3M = [];
end

end
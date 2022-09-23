function [outScan3M,outMask3M] = resampleScanAndMask(scan3M,mask3M,...
    xValsV,yValsV,zValsV,xResampleV,yResampleV,zResampleV,method)
% resampleScanAndMask.m
%
% Returns resampled scan and mask using input method.
% Supported methods include: 'sinc','linear','cubic','nearest',
%                            'makima', and 'spline'.
% Note: Masks are resampled using 'nearest' method.
%--------------------------------------------------------------------------
% INPUTS:
% scan3M         :  Scan array (leave empty to skip)
% mask3M         :  Mask (leave empty to skip)
% xValsV         :  Input x grid vals (cm)
% yValsV         :  Input y grid vals (cm)
% zValsV         :  Input z grid vals (cm)
% xResampleV     :  Output x grid vals (cm)
% yResampleV     :  Output y grid vals (cm)
% zResampleV     :  Output z grid vals (cm)
% method         :  Supported methods: 'sinc','cubic','linear','triangle',
%                   'spline', 'makima', 'nearest.
%--------------------------------------------------------------------------
% AI 9/30/19
% AI 9/24/20  Updated to call imgResample3d.m

extrapVal = 0;
if ~exist('method','var')
    method = 'linear';
end

%Resample scan
if ~isempty(scan3M)
    outScan3M = imgResample3d(scan3M,xValsV,yValsV,zValsV,xResampleV,...
        yResampleV,zResampleV,method,extrapVal);
else
    outScan3M = [];
end

%Resample mask
if ~isempty(mask3M)
    outMask3M = imgResample3d(mask3M,xValsV,yValsV,zValsV,xResampleV,...
        yResampleV,zResampleV,'nearest',extrapVal);
else
    outMask3M = [];
end

end
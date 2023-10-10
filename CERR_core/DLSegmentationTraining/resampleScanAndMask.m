function [outScan3M,outMask4M] = resampleScanAndMask(scan3M,mask4M,...
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
% mask4M         :  4-D array with 3D structure masks stacked along 
%                   the 4th dimension (leave empty to skip)
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
if ~isempty(mask4M)
    for nStr = 1:size(mask4M,4)
        mask3M = squeeze(mask4M(:,:,:,nStr));
        outMask3M = imgResample3d(mask3M,xValsV,yValsV,zValsV,...
            xResampleV,yResampleV,zResampleV,'nearest',extrapVal);
        outMask4M(:,:,:,nStr) = outMask3M;
    end
else
    outMask4M = [];
end

end
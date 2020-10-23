function [xResampleV,yResampleV,zResampleV] = ...
    getResampledGrid(resampResolutionV,xValsV,yValsV,zValsV,gridAlignMethod,varargin)
% function [xResampleV,yResampleV,zResampleV] = ...
%     getResampledGrid(resampResolutionV,xValsV,yValsV,zValsV,method)
%
% APA, 10/22/20

if ~exist('method','var')
    gridAlignMethod = 'center';   
end

% Set default perturbation offsets:
if nargin<6
    perturbX = 0;
    perturbY = 0;
    perturbZ = 0;
else
    perturbV = varargin{1};
    perturbX = perturbV(1);
    perturbY = perturbV(2);
    perturbZ = perturbV(3);
end

dx = abs(median(diff(xValsV)));
dy = abs(median(diff(yValsV)));
dz = abs(median(diff(zValsV)));

%% Get no. output rows, cols, slices
PixelSpacingX = resampResolutionV(1);
PixelSpacingY = resampResolutionV(2);
if ~isnan(resampResolutionV(3))
    resamp3DFlag = 1;
    PixelSpacingZ = resampResolutionV(3);
else
    %Resample in-plane
    resamp3DFlag = 0;
end

%% Get output grid coordinates
% Align grid centers
xCtr = (xValsV(1)+xValsV(end))/2 + perturbX;
yCtr = (yValsV(1)+yValsV(end))/2 + perturbY;
zCtr = (zValsV(1)+zValsV(end))/2 + perturbZ;

% Create output grid
xPlusV = xCtr+PixelSpacingX:PixelSpacingX:xCtr+(length(xValsV)-1)*dx/2;
xMinusV = flip(xCtr-PixelSpacingX:-PixelSpacingX:xCtr-(length(xValsV)-1)*dx/2);
xResampleV = [xMinusV, xCtr, xPlusV];

yPlusV = yCtr+PixelSpacingY:PixelSpacingY:yCtr+(length(yValsV)-1)*dy/2;
yMinusV = flip(yCtr-PixelSpacingY:-PixelSpacingY:yCtr-(length(yValsV)-1)*dy/2);
yResampleV = [yMinusV, yCtr, yPlusV];

if resamp3DFlag  
    zPlusV = zCtr+PixelSpacingZ:PixelSpacingZ:zCtr+(length(zValsV)-1)*dz/2;
    zMinusV = flip(zCtr-PixelSpacingZ:-PixelSpacingZ:zCtr-(length(zValsV)-1)*dz/2);
    zResampleV = [zMinusV, zCtr, zPlusV];    
else
    zResampleV = zValsV;
end

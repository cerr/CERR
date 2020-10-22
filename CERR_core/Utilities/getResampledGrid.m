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
    perturbV = varargin{2};
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
numCols = ceil((xValsV(end) - xValsV(1) + dx)/(PixelSpacingX+eps));
numRows = ceil((yValsV(end) - yValsV(1) + dy)/(PixelSpacingY+eps));
if ~isnan(resampResolutionV(3))
    resamp3DFlag = 1;
    PixelSpacingZ = resampResolutionV(3);
    numSlc = ceil((zValsV(end) - zValsV(1) + dz)/(PixelSpacingZ+eps));
else
    %Resample in-plane
    resamp3DFlag = 0;
    numSlc = length(zValsV);
end

%% Get output grid coordinates
% Align grid centers
%xCtr = dx/2+size(img3M,2)*dx/2 + perturbX;
%yCtr = dy/2+size(img3M,1)*dy/2 + perturbY;
xCtr = (xValsV(1)+xValsV(end))/2 + perturbX;
yCtr = (yValsV(1)+yValsV(end))/2 + perturbY;
zCtr = (zValsV(1)+zValsV(end))/2 + perturbZ;
% Create output grid
% xResampleV = [flip(xCtr-PixelSpacingX/2:-PixelSpacingX:0), ...
%     xCtr+PixelSpacingX/2:PixelSpacingX:size(img3M,2)*dx];
% yResampleV = [flip(yCtr-PixelSpacingY/2:-PixelSpacingY:0), ...
%     yCtr+PixelSpacingY/2:PixelSpacingY:size(img3M,1)*dy];
xResampleV = PixelSpacingX/2:PixelSpacingX:length(xValsV)*dx;
yResampleV = PixelSpacingY/2:PixelSpacingY:length(yValsV)*dy;
xResampCtr = (xResampleV(1)+xResampleV(end))/2;
yResampCtr = (yResampleV(1)+yResampleV(end))/2;
xDeltaCtr = xResampCtr - xCtr;
yDeltaCtr = yResampCtr - yCtr;
xResampleV = -xDeltaCtr + xResampleV;
yResampleV = -yDeltaCtr + yResampleV;

if resamp3DFlag
    %zCtr = dz/2+size(img3M,3)*dz/2 + perturbZ;
    %zResampleV = [flip(zCtr-PixelSpacingZ/2:-PixelSpacingZ:0), ...
     %  zCtr+PixelSpacingZ/2:PixelSpacingZ:size(img3M,3)*dz];
    zResampleV = PixelSpacingZ/2:PixelSpacingZ:length(zValsV)*dz;
    zResampCtr = (zResampleV(1)+zResampleV(end))/2;
    zDeltaCtr = zResampCtr - zCtr;
    zResampleV = -zDeltaCtr + zResampleV;
else
    zResampleV = zValsV;
end
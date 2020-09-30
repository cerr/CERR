function [resampImg3M,xResampleV,yResampleV,zResampleV] = ...
    imgResample3d(img3M,inputResV,xValsV,yValsV,zValsV,outputResV,...
    method,varargin)
% Function to resample image array to specified resolution.
% -------------------------------------------------------------------------
% INPUTS
% img3M      : Input image array
% inputResV  : Input resolution (cm) [dx,dy,dz]
% xValsV     : Input x grid vals (cm)
% yValsV     : Input y grid vals (cm)
% zValsV     : Input z grid vals (cm)
% outputResV : Output voxel resolution (cm) [dxo,dyo,dzo]
% method     : Interpolation method. Supported options: sinc, linear, cubic,
%              spline, makima, nearest.
% --- Optional--
% varargin{1}: extrapval input to interp3.m
% varargin{2}: [perturbX,perturbY,perturbZ]
%-------------------------------------------------------------------------
% AI 09/24/2020

%% Set default perturbation offsets:
if nargin<9
    perturbX = 0;
    perturbY = 0;
    perturbZ = 0;
else
    perturbV = varargin{2};
    perturbX = perturbV(1);
    perturbY = perturbV(2);
    perturbZ = perturbV(3);
end

%% Construct original image grid
dx = inputResV(1);
dy = inputResV(2);
dz = inputResV(3);
xOrigV = dx:dx:size(img3M,2)*dx;
yOrigV = dy:dy:size(img3M,1)*dy;
zOrigV = dz:dz:size(img3M,3)*dz;


%% Get no. output rows, cols, slices
PixelSpacingX = outputResV(1);
PixelSpacingY = outputResV(2);
numCols = ceil((xValsV(end) - xValsV(1) + dx)/PixelSpacingX);
numRows = ceil((yValsV(end) - yValsV(1) + dy)/PixelSpacingY);
if ~isnan(outputResV(3))
    resamp3DFlag = 1;
    PixelSpacingZ = outputResV(3);
    numSlc = ceil((zValsV(end) - zValsV(1) + dz)/PixelSpacingZ);
else
    %Resmaple in-plane
    resamp3DFlag = 0;
    numSlc = length(zValsV);
end

%% Get output grid coordinates
% Align grid centers
xCtr = dx/2+size(img3M,2)*dx/2 + perturbX;
yCtr = dy/2+size(img3M,1)*dy/2 + perturbY;
% Create output grid
xResampleV = [flip(xCtr-PixelSpacingX/2:-PixelSpacingX:0), ...
    xCtr+PixelSpacingX/2:PixelSpacingX:size(img3M,2)*dx];
yResampleV = [flip(yCtr-PixelSpacingY/2:-PixelSpacingY:0), ...
    yCtr+PixelSpacingY/2:PixelSpacingY:size(img3M,1)*dy];
if resamp3DFlag
    zCtr = dz/2+size(img3M,3)*dz/2 + perturbZ;
    zResampleV = [flip(zCtr-PixelSpacingZ/2:-PixelSpacingZ:0), ...
        zCtr+PixelSpacingZ/2:PixelSpacingZ:size(img3M,3)*dz];
else
    zResampleV = zOrigV;
end

%% Interpolation
% Get meshgrids
[xOrigM,yOrigM,zOrigM] = meshgrid(xOrigV,yOrigV,zOrigV);
[xResampM,yResampM,zResampM] = meshgrid(xResampleV,yResampleV,zResampleV);

switch method
    
    case {'linear','cubic','nearest','makima','spline'}
        if nargin>7 && ~isempty(varargin{1})
            extrapVal = varargin{1};
            resampImg3M = interp3(xOrigM,yOrigM,zOrigM,img3M,...
                xResampM,yResampM,zResampM,method,extrapVal);
        else
            resampImg3M = interp3(xOrigM,yOrigM,zOrigM,img3M,...
                xResampM,yResampM,zResampM,method);
        end
        
    case 'sinc'
        %Resize using sinc filter
        resizeMethod = 'lanczos3';
        resampImg3M = imresize3(img3M,[numRows,numCols,numSlc],...
            resizeMethod,'Antialiasing',false);
        %Get pixel spacing
        inPixelSpacingX = (xValsV(end) - xValsV(1) + dx)/numCols;
        inPixelSpacingY = (yValsV(end) - yValsV(1) + dy)/numRows;
        inPixelSpacingZ = (zValsV(end) - zValsV(1) + dz)/numSlc;
        %Align grid centers
        inXvalsV = inPixelSpacingX:inPixelSpacingX:...
            (numCols)*inPixelSpacingX;
        inYvalsV = inPixelSpacingY:inPixelSpacingY:...
            (numRows)*inPixelSpacingY;
        inZvalsV = inPixelSpacingZ:inPixelSpacingZ:...
            (numSlc)*inPixelSpacingZ;
        inXoffset = mean(xOrigV) - mean(inXvalsV);
        inYoffset = mean(yOrigV) - mean(inYvalsV);
        inZoffset = mean(zOrigV) - mean(inZvalsV);
        inXvalsV = inXvalsV + inXoffset;
        inYvalsV = inYvalsV + inYoffset;
        inZvalsV = inZvalsV + inZoffset;
        [inGridX3M,inGridY3M,inGridZ3M] = meshgrid(inXvalsV,...
            inYvalsV,inZvalsV);
        %Adjust pixel spacing
        resampImg3M = interp3(inGridX3M,inGridY3M,inGridZ3M,resampImg3M,...
            xResampM,yResampM,zResampM,'linear');
        
    otherwise
        error('Interpolation method %s not supported',method);
end


end
function resampImg3M = imgResample3d(img3M,xValsV,yValsV,zValsV,...
    xResampleV,yResampleV,zResampleV,method,varargin)
%resampImg3M = imgResample3d(img3M,xValsV,yValsV,zValsV,...
% xResampleV,yResampleV,zResampleV,...
% method,varargin);

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
% Moved calc. of resampling grid to getResampledGrid.

%% Interpolation
% Get meshgrids
[xOrigM,yOrigM,zOrigM] = meshgrid(xValsV,yValsV,zValsV);
[xResampM,yResampM,zResampM] = meshgrid(xResampleV,yResampleV,zResampleV);

switch method
    
    case {'linear','cubic','nearest','makima','spline'}
        if nargin>8 && ~isempty(varargin{1})
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
        numRows = length(xResampleV);
        numCols = length(yResampleV);
        numSlc = length(zResampleV);
        resampImg3M = imresize3(img3M,[numRows,numCols,numSlc],...
            resizeMethod);
        %Get pixel spacing
        dx = abs(median(diff(xValsV)));
        dy = abs(median(diff(yValsV)));
        dz = abs(median(diff(zValsV)));
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
        
        inXoffset = mean(xValsV) - mean(inXvalsV);
        inYoffset = mean(yValsV) - mean(inYvalsV);
        inZoffset = mean(zValsV) - mean(inZvalsV);
        inXvalsV = inXvalsV + inXoffset;
        inYvalsV = inYvalsV + inYoffset;
        inZvalsV = inZvalsV + inZoffset;
        
        [inGridX3M,inGridY3M,inGridZ3M] = meshgrid(inXvalsV,...
            inYvalsV,inZvalsV);
        resampImg3M = interp3(inGridX3M,inGridY3M,inGridZ3M,resampImg3M,...
            xResampM,yResampM,zResampM,'linear');
        
    otherwise
        error('Interpolation method %s not supported',method);
end


end
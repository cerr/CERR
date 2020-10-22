% function [resampImg3M,xResampleV,yResampleV,zResampleV] = ...
%     imgResample3d(img3M,inputResV,xValsV,yValsV,zValsV,outputResV,...
%     method,varargin)
function resampImg3M = imgResample3d(...
                                    img3M,...
                                    xValsV,yValsV,zValsV,...
                                    xResampleV,yResampleV,zResampleV,...
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

% %% Set default perturbation offsets:
% if nargin<9
%     perturbX = 0;
%     perturbY = 0;
%     perturbZ = 0;
% else
%     perturbV = varargin{2};
%     perturbX = perturbV(1);
%     perturbY = perturbV(2);
%     perturbZ = perturbV(3);
% end
% 
% %% Construct original image grid
% dx = inputResV(1);
% dy = inputResV(2);
% dz = inputResV(3);
% xOrigV = dx:dx:size(img3M,2)*dx;
% yOrigV = dy:dy:size(img3M,1)*dy;
% zOrigV = dz:dz:size(img3M,3)*dz;


% %% Get no. output rows, cols, slices
% PixelSpacingX = outputResV(1);
% PixelSpacingY = outputResV(2);
% numCols = ceil((xValsV(end) - xValsV(1) + dx)/(PixelSpacingX+eps));
% numRows = ceil((yValsV(end) - yValsV(1) + dy)/(PixelSpacingY+eps));
% if ~isnan(outputResV(3))
%     resamp3DFlag = 1;
%     PixelSpacingZ = outputResV(3);
%     numSlc = ceil((zValsV(end) - zValsV(1) + dz)/(PixelSpacingZ+eps));
% else
%     %Resample in-plane
%     resamp3DFlag = 0;
%     numSlc = length(zValsV);
% end
% 
% %% Get output grid coordinates
% % Align grid centers
% xCtr = dx/2+size(img3M,2)*dx/2 + perturbX;
% yCtr = dy/2+size(img3M,1)*dy/2 + perturbY;
% xCtr = (xValsV(1)+xValsV(end))/2 + perturbX;
% yCtr = (yValsV(1)+yValsV(end))/2 + perturbY;
% zCtr = (zValsV(1)+zValsV(end))/2 + perturbZ;
% % Create output grid
% % xResampleV = [flip(xCtr-PixelSpacingX/2:-PixelSpacingX:0), ...
% %     xCtr+PixelSpacingX/2:PixelSpacingX:size(img3M,2)*dx];
% % yResampleV = [flip(yCtr-PixelSpacingY/2:-PixelSpacingY:0), ...
% %     yCtr+PixelSpacingY/2:PixelSpacingY:size(img3M,1)*dy];
% xResampleV = PixelSpacingX/2:PixelSpacingX:size(img3M,2)*dx;
% yResampleV = PixelSpacingY/2:PixelSpacingY:size(img3M,1)*dy;
% xResampCtr = (xResampleV(1)+xResampleV(end))/2;
% yResampCtr = (yResampleV(1)+yResampleV(end))/2;
% xDeltaCtr = xResampCtr - xCtr;
% yDeltaCtr = yResampCtr - yCtr;
% xResampleV = -xDeltaCtr + xResampleV;
% yResampleV = -yDeltaCtr + yResampleV;
% 
% if resamp3DFlag
%     %zCtr = dz/2+size(img3M,3)*dz/2 + perturbZ;
%     %zResampleV = [flip(zCtr-PixelSpacingZ/2:-PixelSpacingZ:0), ...
%      %  zCtr+PixelSpacingZ/2:PixelSpacingZ:size(img3M,3)*dz];
%     zResampleV = PixelSpacingZ/2:PixelSpacingZ:size(img3M,3)*dz;
%     zResampCtr = (zResampleV(1)+zResampleV(end))/2;
%     zDeltaCtr = zResampCtr - zCtr;
%     xResampleV = -zDeltaCtr + zResampleV;
% else
%     zResampleV = zValsV;
% end

%% Interpolation
% Get meshgrids
% [xOrigM,yOrigM,zOrigM] = meshgrid(xOrigV,yOrigV,zOrigV);
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
        %Resample
        %if ~resamp3DFlag
         %   zResampleV = inZvalsV;
         %   [xResampM,yResampM,zResampM] = meshgrid(xResampleV,yResampleV,zResampleV);
        % end
        resampImg3M = interp3(inGridX3M,inGridY3M,inGridZ3M,resampImg3M,...
            xResampM,yResampM,zResampM,'linear');
        
    otherwise
        error('Interpolation method %s not supported',method);
end


end
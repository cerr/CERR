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

%Limit processing to 50 slices at a time to resolve out of memory errors
maxNumSlc = 50;  
numPadSlc = 1;
%Resample
switch method

    case {'linear','cubic','nearest','makima','spline'}
        numResampSlc = length(zResampleV);
        numBatch = ceil(numResampSlc/maxNumSlc);
        resampImg3M = nan(length(yResampleV),length(xResampleV),...
            length(zResampleV));
        if nargin>8 && ~isempty(varargin{1})
            extrapVal = varargin{1};
            for iBatch = 1:numBatch
                resampIndV = (iBatch-1)*maxNumSlc + 1: min(iBatch*maxNumSlc,...
                    numResampSlc);
                zMin = zResampleV(resampIndV(1));
                zMax = zResampleV(resampIndV(end));

                tol = 5*max(abs(diff(zValsV)));
                origIndV = zValsV >=zMin - tol & zValsV <=zMax + tol;

                resampImg3M(:,:,resampIndV) = interp3(xOrigM(:,:,origIndV),...
                    yOrigM(:,:,origIndV),zOrigM(:,:,origIndV),...
                    img3M(:,:,origIndV),xResampM(:,:,resampIndV), ...
                    yResampM(:,:,resampIndV),zResampM(:,:,resampIndV),...
                    method,extrapVal);
            end
        else
            for iBatch = 1:numBatch
                resampIndV = (iBatch-1)*maxNumSlc + 1: min(iBatch*maxNumSlc,...
                    numResampSlc) ;
                zMin = zResampleV(resampIndV(1));
                zMax = zResampleV(resampIndV(end));

                tol = 5*max(abs(diff(zValsV)));
                origIndV = zValsV >=zMin - tol & zValsV <=zMax + tol;
                
                 resampImg3M(:,:,resampIndV) = interp3(xOrigM(:,:,origIndV),...
                    yOrigM(:,:,origIndV),zOrigM(:,:,origIndV),...
                    img3M(:,:,origIndV),xResampM(:,:,resampIndV), ...
                    yResampM(:,:,resampIndV),zResampM(:,:,resampIndV),...
                    method);
            end
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
        xFieldV = [xResampleV(1),xResampleV(2)-xResampleV(1),xResampleV(end)];
        yFieldV = [yResampleV(1),yResampleV(2)-yResampleV(1),yResampleV(end)];
        resampImg3M = finterp3(inGridX3M(:),inGridY3M(:),inGridZ3M(:),resampImg3M,...
            xFieldV,yFieldV,zResampleV,0);
        resampImg3M = reshape(resampImg3M,size(inGridX3M));

    otherwise
        error('Interpolation method %s not supported',method);
end


end
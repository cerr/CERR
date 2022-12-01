function [xResampleV,yResampleV,zResampleV] = ...
    getResampledGrid(resampResolutionV,xValsV,yValsV,zValsV,...
    originV,gridAlignMethod,varargin)
%getResampledGrid_v2
% ------------------------------------------------------------------------
% INPUTS
% resampResolutionV  : Output voxel spacing in cm [dx dy dz]
% xValsV             : x coordinates of voxel centers in original scan
% yValsV             : y coordinates of voxel centers in original scan
% zValsV             : z coordinates of voxel centers in original scan 
%------------------------------------------------------------------------
%Ref: https://arxiv.org/pdf/1612.07003.pdf
%AI 12/01/22

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

%% Define voxel spacing
dx = abs(median(diff(xValsV)));
dy = abs(median(diff(yValsV)));
dz = abs(median(diff(zValsV)));
origResolutionV = [dx dy dz];

if length(resampResolutionV)==3 && ~isnan(resampResolutionV(3))
    resamp3DFlag = 1;
else
    %Resample in-plane
    resamp3DFlag = 0;
end

%% No. voxels
origSizeV = [length(xValsV) length(yValsV) length(zValsV)];
resampSizeV = ceil( origSizeV.* origResolutionV ./ resampResolutionV);

switch(gridAlignMethod)

    case 'center'

        %Get output grid origin
        % In world coordinates:
        resampOriginV = originV + (origResolutionV.*(origSizeV-1) - ...
            resampResolutionV.*(resampSizeV-1))/2;
        %In grid co-ords:
        %resampOriginV = 0.5* (origSizeV- 1 -
        %resampResolutionV.*(resampSizeV-1)/origResolutionV);

        %Generate output grid
        xResampleV = resampOriginV(1):resampResolutionV(1):...
            resampOriginV(1)+(resampSizeV(1)-1)*resampResolutionV(1);
        yResampleV = -(resampOriginV(2):resampResolutionV(2):...
            resampOriginV(2)+(resampSizeV(2)-1)*resampResolutionV(2));
        if resamp3DFlag
            zResampleV = -flip(resampOriginV(3):resampResolutionV(3):...
                resampOriginV(3)+(resampSizeV(3)-1)*resampResolutionV(3));
        else
            zResampleV = zValsV;
        end

    otherwise
        error('Unsupported grid alignment method %s',gridAlignMethod)
end

end
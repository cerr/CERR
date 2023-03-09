function [patchIntM,patchStatM,listOfStatsC] = ...
    firstOrderStatsByPatch(scan3M,mask3M,patchSizeV,voxelVol,...
    offsetForEnergy,binWidth,binNum)
% First-order statistics computed patch-wise
% AI 1/10/18
% AI 8/15/18 Extended to include 3D neighbours
%---------------------------------------------------------------------------------
% INPUTS
%scan3M        : scan array
%mask3M        : 3D mask
%patchSizeV(1) : no. rows defining neighbourhood around each voxel
%patchSizeV(2) : no. cols defining neighbourhood
%patchSizeV(3) : no. slices defining neighbourhood
%voxelVol      : Voxel volume
% ---- Optional-----
% offsetForEnergy  : CT offset for energy calc. (default:0)
% binWidth         : Bin size for image quantization (default: 25)
% binNum           : No. bins for image quantization (alt. to binWidth)
%--------------------------------------------------------------------------------
% AI 10/18/17

%Defaults
if ~exist('offsetForEnergy','var')
    offsetForEnergy = 0;
end
if ~exist('binWidth','var')
    if ~exist('binNum','var')
        binWidth = 25;
        binNum = [];
    end
end


%Get patchwise intensities 
patchIntM = getImageNeighbours(scan3M,mask3M,patchSizeV(1),patchSizeV(2),patchSizeV(3));

%Compute statistics 
RadiomicsFirstOrderS = radiomics_first_order_stats(patchIntM,voxelVol,...
    offsetForEnergy,binWidth,binNum);
listOfStatsC = fieldnames(RadiomicsFirstOrderS);
statC = struct2cell(RadiomicsFirstOrderS);
patchStatM = cell2mat(statC).';


end


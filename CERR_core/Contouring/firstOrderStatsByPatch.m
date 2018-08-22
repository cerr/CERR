function [patchIntM,patchStatM,listOfStatsC] = firstOrderStatsByPatch(scan3M,mask3M,patchSizeV,voxelVol)
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
%--------------------------------------------------------------------------------
% AI 10/18/17

%Get patchwise intensities 
patchIntM = getImageNeighbours(scan3M,mask3M,patchSizeV(1),patchSizeV(2),patchSizeV(3));

%Compute statistics 
RadiomicsFirstOrderS = radiomics_first_order_stats(patchIntM,voxelVol);
listOfStatsC = fieldnames(RadiomicsFirstOrderS);
statC = struct2cell(RadiomicsFirstOrderS);
patchStatM = cell2mat(statC).';


end


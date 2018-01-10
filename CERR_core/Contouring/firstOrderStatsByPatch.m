function [patchIntM,patchStatM] = firstOrderStatsByPatch(scan3M,bboxDimV,patchSizeV)
% First-order statistics computed patch-wise
%---------------------------------------------------------------------------------
% INPUTS
%scan3M        : scan array
%bboxDimV      : bboxDimV = [minr,maxr,minc,maxc,mins,maxs];
%patchSizeV(1) : no. rows defining neighbourhood around each voxel
%patchSizeV(2) : no. cols defining neighbourhood
%--------------------------------------------------------------------------------
% AI 10/18/17

%Get patchwise intensities 
patchIntM = getImageNeighbours(scan3M,bboxDimV,patchSizeV(1),patchSizeV(2));

%Compute statistics 
RadiomicsFirstOrderS = radiomics_first_order_stats(patchIntM.');
statC = struct2cell(RadiomicsFirstOrderS);
patchStatM = cell2mat(statC).';


end


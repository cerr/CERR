function [bbox3M, planC] = crop_for_constrictor(planC,paramS,varargin)
% Custom crop function for segmentation model
% AI 10/04/19

%% Limits of bounding box using chewing structures
indexS = planC{end};
strC = {planC{indexS.structures}.structureName};

bboxName = paramS.structureName.cropStructure;
idx1 = getMatchingIndex(bboxName,strC,'EXACT');
scanNum = getStructureAssociatedScan(idx1,planC);
[mask3M, planC]  = getStrMask(idx1,planC);
[minr,~,minc,maxc,mins,~] = compute_boundingbox(mask3M);

%% Limits of bbox around larynx
larynxStrName = paramS.structureName.larynx;
idx2 = getMatchingIndex(larynxStrName,strC,'EXACT');
[mask3M, planC]  = getStrMask(idx2,planC);
[~,maxr,~,~,~,maxs] = compute_boundingbox(mask3M);

%% Get bounding box for constrictors
tol_r = 30;
tol_s = 15;
maxr = maxr+tol_r;
maxs = min(maxs+tol_s,size(mask3M,3));  

bbox3M = false(size(getScanArray(scanNum,planC)));
bbox3M(minr:maxr,minc:maxc,mins:maxs) = true;


end
function [bbox3M, planC] = crop_for_constrictor(planC,paramS,varargin)
% Custom crop function for segmentation model
% AI 10/04/19

%% Limits of bounding box using chewing structures
indexS = planC{end};
strC = {planC{indexS.structures}.structureName};
bboxIdx = [];

%% Return bounding box if it exists
if isfield(paramS,'saveStrToPlanCFlag') && paramS.saveStrToPlanCFlag
    if isfield(paramS,'outStrName')
        outStrName = paramS.outStrName;
    else
        outStrName = 'crop_for_constrictor';
    end
    bboxIdx = getMatchingIndex(outStrName,strC,'EXACT');
end
if ~isempty(bboxIdx)
    bbox3M = getStrMask(bboxIdx,planC);
else
    bboxName = paramS.structureName.cropStructure;
    idx1 = getMatchingIndex(bboxName,strC,'EXACT');
    scanNum = getStructureAssociatedScan(idx1,planC);
    [mask3M, planC]  = getStrMask(idx1,planC);
    if sum(mask3M(:))>0
        [minr,~,minc,maxc,mins,~] = compute_boundingbox(mask3M);
    else
        minr = 1;
        minc = 1;
        maxc = size(mask3M,2);
        mins = 1;
    end
    %% Limits of bbox around larynx
    larynxStrName = paramS.structureName.larynx;
    idx2 = getMatchingIndex(larynxStrName,strC,'EXACT');
    [mask3M, planC]  = getStrMask(idx2,planC);
    if sum(mask3M(:))>0
        [~,maxr,~,~,~,maxs] = compute_boundingbox(mask3M);
    else
        maxr = size(mask3M,1);
        maxs = size(mask3M,3);
    end

    %% Get bounding box for constrictors
    tol_r = 30;
    tol_s = 15;
    maxr = min(maxr+tol_r,size(mask3M,1));
    maxs = min(maxs+tol_s,size(mask3M,3));

    bbox3M = false(size(getScanArray(scanNum,planC)));
    bbox3M(minr:maxr,minc:maxc,mins:maxs) = true;
end

end
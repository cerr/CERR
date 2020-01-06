function bbox3M = crop_for_larynx(planC,paramS,varargin)
% Custom crop function for larynx segmentation model
% AI 10/04/19?

%% Create union of masseters (left & right) and medial pterygoids (left & right)
indexS = planC{end};
strC = {planC{indexS.structures}.structureName};
unionStrListC = paramS.structureName.chewingStructures;

idxV = nan(1,length(unionStrListC));
for k = 1:length(unionStrListC)
    idxV(k) = getMatchingIndex(unionStrListC{k},strC,'EXACT');
    if k == 1
        endStr = idxV(k);
    else
        planC = createUnionStructure(idxV(k),endStr,planC);
        endStr = length(planC{indexS.structures});
    end
end

%Get limits of bbox around union str
mask3M = getStrMask(endStr,planC);
[minr,~,minc,maxc,mins,~] = compute_boundingbox(mask3M);

%% Get limits of bounding box around cropped pt outline
outStrName = paramS.structureName.cropStructure;
idx = getMatchingIndex(outStrName,strC,'EXACT');
cropMask3M = getStrMask(idx,planC);
[~,maxr,~,~,~,maxs] = compute_boundingbox(cropMask3M);

%Get final bounding box
bbox3M = false(size(mask3M));
bbox3M(minr:maxr,minc:maxc,mins:maxs) = true;


end
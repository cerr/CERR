function [maskV, structNamCOut] = getMaskIndices(planC,structNamC)

indexS = planC{end};
structureListC = {planC{indexS.structures}.structureName};

noMaskIdx = [];
maskV = zeros(1,numel(structNamC));

for i = 1:numel(structNamC)
    idx = getMatchingIndex(lower(structNamC{i}),lower(structureListC),'exact');
    if ~isempty(idx)
%         maskC{i} = uint8(getStrMask(idx, planC));
        maskV(i) = idx;
    else
        noMaskIdx = [noMaskIdx; i];
    end
end

structNamCOut = structNamC;

if ~isempty(noMaskIdx)
    maskV(noMaskIdx) = [];
    structNamCOut(noMaskIdx) = [];
end
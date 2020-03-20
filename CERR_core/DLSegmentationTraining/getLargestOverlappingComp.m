function [maskOut3M, planC] = getLargestOverlappingComp(strNum,roiStrNum,planC)
% maskOut3M = getLargestConnComps(strNum1,strNum2,planC)
% Returns largest connected component that overlaps with ROI.
% ------------------------------------------------------------------------
% INPUTS
% strNum             : Structure no.
% roiStrNum          : ROI structure no.
% planC          
% ------------------------------------------------------------------------
% Example usage:
% strNum = 1;
% roiStrNum = 5;
% maskOut3M = getOverlappingComp(strNum,roiStrNum,planC);
% planC = maskToCERRStructure(maskOut3M,0,1,'overlappingCC',planC);
% ------------------------------------------------------------------------
% AI 11/19/19


%Get ROI mask
[roiMask3M, planC] = getStrMask(roiStrNum,planC);

%Get connected components in str mask
[mask3M, planC] = getStrMask(strNum,planC);
cc = bwconncomp(mask3M,26);
ccSizV = cellfun(@numel,[cc.PixelIdxList]);

%Loop over components
numIntersect = zeros(length(ccSizV),1);

for compIdx = 1:length(ccSizV)
    
    idxV = cc.PixelIdxList{compIdx};
    compMask3M = false(size(mask3M));
    compMask3M(idxV) = true;
    %Calc. intersection
    numIntersect(compIdx)  = sum(compMask3M(:) & roiMask3M(:));
    
end

%Return mask of component with max overlap
[~,maxOverlapIdx] = max(numIntersect);
idxV = cc.PixelIdxList{maxOverlapIdx};
maskOut3M = false(size(mask3M));
maskOut3M(idxV) = true;


end
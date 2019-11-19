function maskOut3M = getLargestOverlappingComp(strNum,roiStrNum,planC)
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
roiMask3M = getStrMask(roiStrNum,planC);

%Get connected components in str mask
mask3M = getStrMask(strNum,planC);
cc = bwconncomp(mask3M,26);
ccSizV = cellfun(@numel,[cc.PixelIdxList]);

%Loop over components
isIntersect = false(length(ccSizV),1);

for compIdx = 1:length(ccSizV)
    
    idxV = cc.PixelIdxList{compIdx};
    compMask3M = false(size(mask3M));
    compMask3M(idxV) = true;
    %Calc. intersection
    isIntersect(compIdx)  = sum(compMask3M(:) & roiMask3M(:))>0;
    
end

%Return mask of largest overlapping component
ccSizV(~isIntersect)=nan;
[~,maxOverlapIdx] = nanmax(ccSizV);
idxV = cc.PixelIdxList{maxOverlapIdx};
maskOut3M = false(size(mask3M));
maskOut3M(idxV) = true;


end


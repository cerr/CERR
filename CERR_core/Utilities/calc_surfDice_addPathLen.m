function [surfDice,addedPathLen,addedPathLenNorm] = ...
    calc_surfDice_addPathLen(structNum1,structNum2,margin,planC)
% function [surfDice,addedPathLen,addedPathLenNorm] = ...
%     calc_surfDice_addPathLen(structNum1,structNum2,margin,planC)


mask1M = getSurfaceRing(structNum1,margin,planC);
mask2M = getSurfaceRing(structNum2,margin,planC);
avgMask = (sum(mask1M(:))+sum(mask2M(:)))/2;
intrsctM = mask1M & mask2M;
surfDice = sum(intrsctM(:))/avgMask;

% addedPathLenNorm = sum((mask1M(:) | mask2M(:)) & ~intrsctM(:))/(avgMask*2);
% addedPathLen = sum((mask1M(:) | mask2M(:)) & ~intrsctM(:));

scanNum = getStructureAssociatedScan(structNum1,planC);
% [~,~,numSlcs] = size(intrsctM);

indexS = planC{end};

[xScanV,yScanV,zScanV] = getScanXYZVals(planC{indexS.scan}(scanNum));
[~,~,zUnifScanV] = getUniformScanXYZVals(planC{indexS.scan}(scanNum));
numSlcs = length(zScanV);

structLen = 0;
intersectStructLen = 0;
for slc = 1:numSlcs
    if length(planC{indexS.structures}(structNum1).contour(slc).segments) ~= 1
        continue
    end
    xV = planC{indexS.structures}(structNum1).contour(slc).segments(1).points(:,1);
    yV = planC{indexS.structures}(structNum1).contour(slc).segments(1).points(:,2);
    %[rowV, colV] = xytom(xV, yV, slc, planC,scanNum);
    siz = size(intrsctM(:,:,slc));
    %indV = sub2ind(siz, round(rowV), round(colV));
    
    structXYv = [xV';yV'];
        
    d = hypot(diff(xV), diff(yV)); % Distance Of Each Segment
    contourLen = sum(d);
    
    structLen = structLen + contourLen;
    
    unifSlc = findnearest(zUnifScanV,zScanV(slc));
    cc = bwconncomp(intrsctM(:,:,unifSlc));
    intersectLen = 0;
    for comp = 1:cc.NumObjects
        compIndV = cc.PixelIdxList{comp};
        [compiV,compjV] = ind2sub(siz,compIndV);
        compXYv = [xScanV(compjV);yScanV(compiV)];
        
        distM = sepsq(structXYv,compXYv);
        [~,indMinV] = min(distM,[],1);
        indMinV = unique(indMinV);
        segX = xV(indMinV);
        segY = yV(indMinV);
        
        d = hypot(diff(segX), diff(segY)); % Distance Of Segment between points
        segDist = sum(d);
        
        intersectLen = intersectLen + segDist;
        
    end
    
    intersectStructLen = intersectStructLen + intersectLen;
    
end

addedPathLen = structLen - intersectStructLen;
addedPathLenNorm = addedPathLen / structLen;

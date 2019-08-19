function sliceNum = getShoulderStartSlice(outerStrMask3M,planC,outerStrName)
% Automatically identify shoulder start slice in H&N scans based on
% size of patient outline.
%
% AI 8/7/19
%
%------------------------------------------------------------------------
% INPUT
% outerStrMask3M   : Mask of pt outline. Set to [] to use structure name
%                    instead.
% outerStrName     : Structure name corresponding to pt outline
%------------------------------------------------------------------------


if ~isempty(outerStrMask3M)
    
    mask3M = outerStrMask3M;
    
else
    %Get mask of outer structure
    indexS = planC{end};
    strC = {planC{indexS.structures}.structureName};
    strIdx = getMatchingIndex(outerStrName,strC,'exact');
    scanIdx = getStructureAssociatedScan(strIdx,planC);
    
    rasterM = getRasterSegments(strIdx, planC);
    [maskSl3M, slicesV] = rasterToMask(rasterM,1,planC);
    mask3M = false(size(getScanArray(scanIdx,planC)));
    mask3M(:,:,slicesV) = maskSl3M;
end

%Get size on each slice
[sel,colIdxM] = max(mask3M, [], 2);
colIdxM = squeeze(sel.*(colIdxM)).';
colIdxM(colIdxM==0) = nan;
minColV = nanmin(colIdxM,[],2);

[sel,colIdxM] = max(fliplr(mask3M), [], 2);
colIdxM = squeeze(sel.*(colIdxM)).';
colIdxM(colIdxM==0) = nan;
maxColV = size(mask3M,2) - nanmin(colIdxM,[],2) + 1;

sizV = maxColV - minColV;

%Find sudden jump in size if any
sizV = movmean(sizV,10);
diffV = [0;diff(sizV)];
[~,argMax] = max(diffV);


if (sizV(argMax)-max(sizV(1:50))) / max(sizV(1:50)) > .2
    sliceNum = argMax;
else
    % If not substantially wider, return last slice
    % (assumes shoulders not included)
    sliceNum = size(mask3M,3)  ;
end

end
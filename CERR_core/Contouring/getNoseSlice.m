function [sliceNum, planC] = getNoseSlice(outerStrMask3M,planC,outerStrName)
% Automatically identify nose slice in H&N CT scans based on
% first non-zero row of mask.
%
% AI 10/1/19
%
%------------------------------------------------------------------------
% INPUT
% outerStrMask3M   : Mask of pt outline. Set to [] to use structure name
%                    instead.
% planC
% outerStrName     : Structure name corresponding to pt outline
%------------------------------------------------------------------------


if ~isempty(outerStrMask3M)
    mask3M = outerStrMask3M;
else
    %Get mask of outer structure
    indexS = planC{end};
    strC = {planC{indexS.structures}.structureName};
    strIdx = getMatchingIndex(outerStrName,strC,'exact');
    [mask3M, planC] = getStrMask(strIdx, planC);
end

startSliceIdx = 11;
endSliceIdx = min(size(mask3M,3),100);
supMask3M = double(mask3M(:,:,startSliceIdx:endSliceIdx));

%Identify first non-zero row
[sel,rowIdxM] = max(supMask3M, [], 1); 
rowIdxM = squeeze(sel.*(rowIdxM)).';
rowIdxM(rowIdxM==0) = nan;
minRowV = nanmin(rowIdxM,[],2);

%Smooth
minRowV = movmean(minRowV,5,'omitnan');

%Compute difference & identify min
%[~,mins] = min(diff([NaN;minRowV]));
[~,mins] = findpeaks(-minRowV,'MinPeakWidth',2, 'MaxPeakWidth',40);
if ~isempty(mins)
    sliceNum = mins(1) + startSliceIdx -1;
else
    sliceNum=1; %default
end


end
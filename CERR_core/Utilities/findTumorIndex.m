function indTumor = findTumorIndex(scanNum,planC)
% function indTumor = findTumorIndex(scanNum,planC)
%
% APA, 4/28/2021

indexS = planC{end};

indTumor = [];
numStructs = length(planC{indexS.structures});
assocScanV = getStructureAssociatedScan(1:numStructs,planC);
strIndV = find(assocScanV == scanNum);
strNamC = {planC{indexS.structures}(strIndV).structureName};

indPtv = getMatchingIndex('ptv',lower(strNamC),'exact');
if isempty(indPtv)
    indPtv = getMatchingIndex('ptv',lower(strNamC),'regex');
end
if length(indPtv) > 1
    indPtv = indPtv(1);
    indPtvTmp = getMatchingIndex('ptve_1',lower(strNamC),'exact');
    if ~isempty(indPtvTmp)
        indPtv = indPtvTmp(1);
    end        
    indPtvTmp = getMatchingIndex('ptv_1',lower(strNamC),'exact');
    if ~isempty(indPtvTmp)
        indPtv = indPtvTmp(1);
    end
end
if length(indPtv) > 1
    indPtv = find(strcmp('PTV',strNamC));
end

if ~isempty(indPtv)
    indTumor = strIndV(indPtv(1));
    return;
end

indGtv = getMatchingIndex('gtv',lower(strNamC),'exact');
if length(indGtv) > 1
    indGtv = find(strcmp('GTV',strNamC));
end
if ~isempty(indGtv)
    indTumor = strIndV(indGtv(1));
    return;
end


indCtv = getMatchingIndex('ctv',lower(strNamC));
if length(indCtv) > 1
    indCtv = find(strcmp('CTV',strNamC));
end
if ~isempty(indCtv)
    indTumor = strIndV(indCtv(1));
    return;
end

function planC = deleteScan(planC, scanNum)
% function planC = deleteScan(planC, scanNum)
%
% Function to delete scan in a batch mode.
%
% GP, 11/30/2016

indexS = planC{end};
assocScanV = getStructureAssociatedScan(1:length(planC{indexS.structures}), planC);
structToDelete = find(assocScanV == scanNum);
planC{indexS.structures}(structToDelete) = [];
%Delete structureArray
planC{indexS.structureArray}(scanNum) = [];
planC{indexS.structureArrayMore}(scanNum) = [];

%Update doses associated with this scan
while ~isempty(find(strcmpi({planC{indexS.dose}.assocScanUID},planC{indexS.scan}(scanNum).scanUID)))
    indAssoc = find(strcmpi({planC{indexS.dose}.assocScanUID},planC{indexS.scan}(scanNum).scanUID));
    n = indAssoc(1);
    transM = getTransM(planC{indexS.dose}(n),planC);
    planC{indexS.dose}(n).assocScanUID = [];
    planC{indexS.dose}(n).transM = transM;
end
%Delete the scan
planC{indexS.scan}(scanNum) = [];

function exportAISegToDICOM(planC,origScanNum,outputDicomPath,dcmExportOptS,allLabelNamesC)
% function exportAISegToDICOM(planC,outputDicomPath,dcmExportOptS,allLabelNamesC)
%
% APA, 4/28/2022

indexS = planC{end};

%Get custom options for DICOM export
% Handle special case of assignig reference UID fromanother structure
% (e.g. exporting registered images from MIM assistant changes their frameOfreferenceUID)
structRefForC = {};
count = 0;
if exist('dcmExportOptS','var') && isstruct(dcmExportOptS)
    structNameC = {planC{indexS.structures}.structureName};
    for iDcmOpt = 1:length(dcmExportOptS)
        if isfield(dcmExportOptS(iDcmOpt),'rt_struct') && ...
                isfield(dcmExportOptS(iDcmOpt).rt_struct,'referencedFrameOfReference')
            % Update to handle multiple structures
            toStructureName = dcmExportOptS(iDcmOpt).rt_struct.referencedFrameOfReference.toStructureName;
            fromStructureName = dcmExportOptS(iDcmOpt).rt_struct.referencedFrameOfReference.fromStructureName;
            strIndex = getMatchingIndex(fromStructureName,structNameC,'exact');
            assocScanV = getStructureAssociatedScan(strIndex,planC);
            strIndex = strIndex(assocScanV==origScanNum);
            if isempty(strIndex)
                continue
            end
            count = count + 1;
            structRefFrameOfReferenceUID = planC{indexS.structures}(strIndex).referencedFrameOfReferenceUID;
            refSeriesInstanceUID = planC{indexS.structures}(strIndex).referencedSeriesUID;
            sopClassUidC = {planC{indexS.structures}(strIndex).contour.referencedSopClassUID};
            sopInstanceUidC = {planC{indexS.structures}(strIndex).contour.referencedSopInstanceUID};
            structRefForC{count,1} = toStructureName;
            structRefForC{count,2} = structRefFrameOfReferenceUID;
            structRefForC{count,3} = refSeriesInstanceUID;
            structRefForC{count,4} = sopClassUidC;
            structRefForC{count,5} = sopInstanceUidC;
        end
    end
end


%Retain only user-input structures (in allLabelNamesC)
numStr = length(planC{indexS.structures});
allStrC = {planC{indexS.structures}.structureName};
keepStrNumV = zeros(length(allLabelNamesC),1);
for i=1:length(allLabelNamesC)
    matchStrNum = getMatchingIndex(allLabelNamesC{i},allStrC,'EXACT');
    keepStrNumV(i) =  max(matchStrNum);
end

allStrV = 1:numStr;
allStrV(keepStrNumV)=[];

planC = deleteStructure(planC,allStrV);

%Export DICOM RT structs to outputDicomPath
planC = generate_DICOM_UID_Relationships(planC,structRefForC);
export_RS_IOD(planC,outputDicomPath,fname);

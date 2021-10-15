function exportCERRtoDICOM(cerrPath,origScanNum,allLabelNamesC,outputCERRPath,outputDicomPath,dcmExportOptS,savePlancFlag)
% function exportCERRtoDICOM(cerrPath,allLabelNamesC,outputCERRPath,outputDicomPath,dcmExportOptS,savePlancFlag)
%
% This function exports selected structures from CERR format to DICOM RTSTRUCT.
%
% INPUTS:
% cerrPath           - directory containing CERR files with initial
%                      sementation
% allLabelNamesC     - Cell array of labelnames for export
%
% outputCERRPath     - directory to save CERR file with segmentation copied
%                      to original CERR file.
% outputDicomPath    - directory to export DICOM RTSTRUCT
%
% APA, 8/14/2018
% AI, 2/7/2020

dirS = dir(cerrPath);
dirS(1:2) = [];
init_ML_DICOM

for indBase = 1:length(dirS)
    
    
    %Load planC
    origFileName = fullfile(cerrPath,dirS(indBase).name);
    planC = loadPlanC(origFileName);
    indexS = planC{end};
    
    %Save planC to outputDicomPath 
    [~,fname,~] = fileparts(dirS(indBase).name);
    %fname = [fname,'_',algorithm];
    if savePlancFlag
        planC = save_planC(planC,[],'passed',...
            fullfile(outputDicomPath,[fname,'.mat']));
    end
    
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
    
end

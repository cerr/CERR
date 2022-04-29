function exportCERRtoDICOM(cerrPath,origScanNum,allLabelNamesC,...
    outputCERRPath,outputDicomPath,dcmExportOptS,savePlancFlag)
% function exportCERRtoDICOM(cerrPath,origScanNum,allLabelNamesC,...
%     outputCERRPath,outputDicomPath,dcmExportOptS,savePlancFlag)
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
    
    %Save planC to outputDicomPath
    [~,fname,~] = fileparts(dirS(indBase).name);
    %fname = [fname,'_',algorithm];
    if savePlancFlag
        planC = save_planC(planC,[],'passed',...
            fullfile(outputCERRPath,[fname,'.mat']));
    end
    
    exportAISegToDICOM(planC,origScanNum,outputDicomPath,fname,...
        dcmExportOptS,allLabelNamesC)

    
end

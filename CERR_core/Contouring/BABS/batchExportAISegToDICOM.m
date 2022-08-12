function batchExportAISegToDICOM(cerrPath,origScanNumV,allLabelNamesC,...
    outputCERRPath,outputDicomPath,dcmExportOptS,savePlancFlag)
% function batchExportAISegToDICOM(cerrPath,origScanNumV,allLabelNamesC,...
%     outputCERRPath,outputDicomPath,dcmExportOptS,savePlancFlag)
%
% This function exports selected structures to DICOM RTSTRUCT from a batch
% of CERR files
%--------------------------------------------------------------------------
% INPUTS:
% cerrPath          - directory containing CERR files with initial
%                      sementation
% origScanNumV      - Indices of scans to be segmented (one per CERR file).
% allLabelNamesC    - Cell array of labelnames for export
%
% outputCERRPath    - directory to save CERR file with segmentation copied
%                      to original CERR file.
% outputDicomPath   - directory to export DICOM RTSTRUCT
% dcmExportOptS     - Custom settings for dicom export
% savePlancFlag     - Set to true to save planC to file.
%--------------------------------------------------------------------------
% APA, 8/14/2018
% AI, 2/7/2020

dirS = dir(cerrPath);
dirS(1:2) = [];
init_ML_DICOM

for nFile = 1:length(dirS)
    
    
    %Load planC
    origFileName = fullfile(cerrPath,dirS(nFile).name);
    planC = loadPlanC(origFileName);
    
    %Save planC to outputDicomPath
    [~,fname,~] = fileparts(dirS(nFile).name);
    %fname = [fname,'_',algorithm];
    if savePlancFlag
        planC = save_planC(planC,[],'passed',...
            fullfile(outputCERRPath,[fname,'.mat']));
    end
    
    exportAISegToDICOM(planC,origScanNumV(nFile),outputDicomPath,fname,...
        dcmExportOptS,allLabelNamesC)

    
end

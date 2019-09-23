function exportCERRtoDICOM(cerrPath,segResultCERRRPath,outputCERRPath,outputDicomPath,algorithm)
% function exportCERRtoDICOM(cerrPath,segResultCERRRPath,outputCERRPath,outputDicomPath,algorithm)
%
% This function exports structures from CERR format to DICMO RTSTRUCT.
%
% INPUTS:
% cerrPath           - directory containing CERR files with initial
%                      sementation
% segResultCERRRPath - directory containing CERR files with sementation
%                      resulting from an algorithm
% outputCERRPath     - directory to save CERR file with segmentation copied
%                      to original CERR file.
% outputDicomPath    - directory to export DICOM RTSTRUCT
%
% APA, 8/14/2018


dirS = dir(cerrPath);
dirS(1:2) = [];
init_ML_DICOM

for indBase = 1:length(dirS)
    
    [~,fname,~] = fileparts(dirS(indBase).name);
    
    fname = [fname,'_',algorithm];
    
    %registeredDir = fullfile(registeredDirLoc,['registered_to_',fname]); 

        
    % Copy segmentation from segResultCERRRPath to planC
    origFileName = fullfile(cerrPath,dirS(indBase).name);
    % segFileName = fullfile(registeredDir,dirS(indBase).name);
    segFileName = fullfile(segResultCERRRPath,'cerrFile.mat'); 
    planC = loadPlanC(origFileName);
    planD = loadPlanC(segFileName);    
    indexS = planC{end};
    indexSD = planD{end};
    
    % Save planC to outputDicomPath (TO DO: a separate directory?)
    planD = save_planC(planD,[],'passed',...
        fullfile(outputDicomPath,[fname,'.mat']));
    
    
    scanIndV = 1;
    doseIndV = [];
    numSegStr = length(planD{indexSD.structures});
    numOrigStr = length(planC{indexS.structures});
    % structIndV = [numStr-1 numStr];
    structIndV = 1:numSegStr;
    planC = planMerge(planC, planD, scanIndV, doseIndV, structIndV, '');        
    numSegStr = numSegStr - numOrigStr;
    for iStr = 1:numSegStr
        planC = copyStrToScan(numOrigStr+iStr,1,planC);
    end
%     %planC = copyStrToScan(numStr,1,planC);
    planC = deleteScan(planC, 2);
%     for structNum = numOrigStr:-1:1
%         planC = deleteStructure(planC, structNum);
%     end
    planC = deleteStructure(planC, numOrigStr:-1:1);
    mergedFileName = fullfile(outputCERRPath,dirS(indBase).name);
    planC = save_planC(planC,[],'passed',mergedFileName);

    % Export DICOM to outputDicomPath
    %export_planC_to_DICOM(planC,outputDicomPath);
    planC = generate_DICOM_UID_Relationships(planC);
    export_RS_IOD(planC,outputDicomPath,fname);
    
end

function exportCERRtoDICOM(cerrPath,registeredDirLoc,outputCERRPath,outputDicomPath)
% function exportCERRtoDICOM(cerrPath,registeredDirLoc,outputCERRPath,outputDicomPath)
%
% APA, 8/14/2018

dirS = dir(cerrPath);
dirS(1:2) = [];
init_ML_DICOM

for indBase = 1:length(dirS)
    
    [~,fname,~] = fileparts(dirS(indBase).name);
    registeredDir = fullfile(registeredDirLoc,['registered_to_',...
        fname]); 
    
    % Copy BABS segmentation from registeredDir to planC
    origFileName = fullfile(cerrPath,dirS(indBase).name);
    segFileName = fullfile(registeredDir,dirS(indBase).name);
    planC = loadPlanC(origFileName);
    planD = loadPlanC(segFileName);
    indexSD = planD{end};
    scanIndV = 1;
    doseIndV = [];
    numStr = length(planD{indexSD.structures});
    structIndV = [numStr-1 numStr];
    planC = planMerge(planC, planD, scanIndV, doseIndV, structIndV, '');
    indexS = planC{end};
    numStr = length(planC{indexS.structures});
    planC = copyStrToScan(numStr-1,1,planC);
    planC = copyStrToScan(numStr,1,planC);
    planC = deleteScan(planC, 2);
    numStr = length(planC{indexS.structures});
    for structNum = numStr-2:-1:1
        planC = deleteStructure(planC, structNum);
    end
    mergedFileName = fullfile(outputCERRPath,dirS(indBase).name);
    planC = save_planC(planC,[],'passed',mergedFileName);

    % Export DICOM to outputDicomPath
    %export_planC_to_DICOM(planC,outputDicomPath);
    planC = generate_DICOM_UID_Relationships(planC);
    export_RS_IOD(planC,outputDicomPath,fname);
    
    % delete the registered_ directory
    rmdir(registeredDir,'s')
    
    % delete the ct file
    delete(origFileName)

end

function copyCERRfilewithBABSseg(cerrPath,registeredDirLoc,segResultCERRRPath)
% function exportCERRtoDICOM(cerrPath,registeredDirLoc,segResultCERRRPath)
%
% This function saves CERR file with parotid_l and parotid_r regmentation
% under segResultCERRRPath.
%
% INPUT:
% cerrPath           - directory containing CERR files with initial
%                      sementation
% registeredDirLoc   - directory containing atlas registrations and the
%                      final parotid contours
% segResultCERRRPath - directory to write CERR files with sementation
%                      resulting from the algorithm
%
% APA, 12/14/2018

dirS = dir(cerrPath);
dirS(1:2) = [];
init_ML_DICOM

for indBase = 1:length(dirS)
    
    [~,fname,~] = fileparts(dirS(indBase).name);
    registeredDir = fullfile(registeredDirLoc,['registered_to_',...
        fname]); 
    
    % Copy BABS segmentation from registeredDir to planC
    segFileName = fullfile(registeredDir,dirS(indBase).name);
    planC = loadPlanC(segFileName);
    indexS = planC{end};
    numStr = length(planC{indexS.structures});

    % delete all but the last two structures
    for structNum = numStr-2:-1:1
        planC = deleteStructure(planC, structNum);
    end

    % Save this file to segResultCERRRPath directory
    segFileName = fullfile(segResultCERRRPath,dirS(indBase).name);
    planC = save_planC(planC,[],'passed',segFileName);    
    
end

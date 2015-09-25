function batch_register_scans(baseScansC,movScansC)
% function batch_register_scans(baseScansC,movScansC)
%
% INPUT:
%  baseScansC: cellArray of full fileNames for base scans
%  movScansC: cellArray of full fileNames for moving scans
%
% APA, 08/06/2012

for baseNum = 1:length(baseScansC)
    
    % Load base planC
    planC = loadPlanC(baseScansC{baseNum},tempdir);
    planC = updatePlanFields(planC);
    planC = quality_assure_planC(baseScansC{baseNum},planC);
    uid = createUID('scan');
    
    indexS = planC{end};
    planC{indexS.deform}(:) = [];
    planC{indexS.scan}.scanUID = uid;

    for movNum = 1:length(movScansC)
        
        % Load moving planC as planD
        planD = loadPlanC(movScansC{movNum},tempdir);
        planD = updatePlanFields(planD);
        planD = quality_assure_planC(movScansC{movNum},planD);
        uid = createUID('scan');
        
        indexSD = planD{end};
        planD{indexSD.deform}(:) = [];
        planD{indexSD.scan}.scanUID = uid;
        
        % Register planD to planC
        baseScanNum = 1;
        movScanNum  = 1;
        algorithm = 'BSPLINE PLASTIMATCH';
        baseMask3M = [];
        movMask3M = [];
        threshold_bone = [];
        [planC, planD] = register_scans(planC, planD, baseScanNum, movScanNum, algorithm, baseMask3M, movMask3M, threshold_bone);        
        
        % Save base and moving scans
        planC = save_planC(planC,[],'passed',baseScansC{baseNum});
        planD = save_planC(planD,[],'passed',movScansC{movNum});        
        
        clear planD
        
    end
    clear planC
end



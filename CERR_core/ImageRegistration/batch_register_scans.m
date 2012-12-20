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
    
    for movNum = 1:length(movScansC)
        
        % Load moving planC as planD
        planD = loadPlanC(movScansC{movNum},tempdir);
        planD = updatePlanFields(planD);
        planD = quality_assure_planC(movScansC{movNum},planD);
        
        % Register planD to planC
        baseScanNum = 1;
        movScanNum  = 1;
        algorithm   = '';
        [planC, planD] = register_scans(planC, planD, baseScanNum, movScanNum, algorithm);
        
        % Save base and moving scans
        planC = save_planC(planC,[],'passed',baseScansC{baseNum});
        planD = save_planC(planD,[],'passed',movScansC{movNum});
        
    end
    
end



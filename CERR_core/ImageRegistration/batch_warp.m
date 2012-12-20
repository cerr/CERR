function batch_warp(baseScansC,movScansC,warp_scan_flag,warp_structures_flag,warp_doses_flag,warp_str_and_dose_to_base_flag)
% function batch_warp(baseScansC,movScansC,warp_scan_flag,warp_structures_flag,warp_doses_flag,warp_str_and_dose_to_base_flag)
%
% APA, 08/09/2012

for baseNum = 1:length(baseScansC)
    
    % Load base planC
    planC = loadPlanC(baseScansC{baseNum},tempdir);
    planC = updatePlanFields(planC);
    planC = quality_assure_planC(baseScansC{baseNum},planC);
    
    indexBaseS = planC{end};
    baseUIDc = {planC{indexBaseS.deform}.baseScanUID};
    movUIDc  = {planC{indexBaseS.deform}.movScanUID};
    
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
        
        % Find deformS matching base and moving scan UIDs
        deformS = findDeformObject(planC{indexS.deform},)
        
        
        % Warp scan
        if warp_scan_flag
            planC = warp_scan(deformS,movScanNum,movPlanC,planC);
        end
        
        % Save base and moving scans
        planC = save_planC(planC,[],'passed',baseScansC{baseNum});
        planD = save_planC(planD,[],'passed',movScansC{movNum});
        
    end
    
end



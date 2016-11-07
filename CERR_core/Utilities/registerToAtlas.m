function registerToAtlas(baseScanFile,movScanFileC,destnDir)
% function registerToAtlas(baseScanFile,movScanFileC,destnDir)
%
% INPUT:
%  baseScanFile: full fileName of the base scan
%  movScanFileC: cellArray of full fileNames for moving scans
%  destnDir: directory to write the base and the deformed scans.
%
% EXAMPLE USAGE:
%
%  distcomp.feature( 'LocalUseMpiexec', false )
%  pool = parpool(40);
%  baseScanFile = '/path/to/source/plan1.mat';
%  movScanFileC = {'/path/to/source/plan2.mat','/path/to/source/plan3.mat','/path/to/source/plan4.mat'};
%  destnDir     = '/path/to/destination/dir';
%  registerToAtlas(baseScanFile,movScanFileC,destnDir);
%
% APA, 08/23/2016


% Load base planC
planC = loadPlanC(baseScanFile,tempdir);
planC = updatePlanFields(planC);
planC = quality_assure_planC(baseScanFile,planC);

parfor movNum = 1:length(movScanFileC)
    
    % Load base planC
    planC = loadPlanC(baseScanFile,tempdir);
    planC = updatePlanFields(planC);
    planC = quality_assure_planC(baseScanFile,planC);
    indexS = planC{end};
    
    % Load moving planC as planD
    planD = loadPlanC(movScanFileC{movNum},tempdir);
    planD = updatePlanFields(planD);
    planD = quality_assure_planC(movScanFileC{movNum},planD);    
    %indexSD = planD{end};
    %planD{indexSD.deform}(:) = [];
    
    % Register planD to planC
    baseScanNum = 1;
    movScanNum  = 1;
    algorithm = 'BSPLINE PLASTIMATCH';
    baseMask3M = [];
    movMask3M = [];
    threshold_bone = [];
    [planC, planD] = register_scans(planC, planD, baseScanNum, movScanNum, algorithm, baseMask3M, movMask3M, threshold_bone);
    
    % Warp scan
    deformS = planC{indexS.deform}(end);
    planC = warp_scan(deformS,movScanNum,planD,planC);
    
    % Save base and moving scans
    [~,fName] = fileparts(movScanFileC{movNum});
    newFileName = fullfile(destnDir,fName);
    save_planC(planC,[],'passed',newFileName);
        
end



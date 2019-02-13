function registerToAtlasMultipleScans(baseScanFile,movScanFileC,destnDir,...
    strNameToWarp,initPlmCmdFile,refinePlmCmdFile)
% function registerToAtlasMultipleScans(baseScanFile,movScanFileC,destnDir,...
%     strNameToWarp,initPlmCmdFile,refinePlmCmdFile)
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
%  strNameToWarp = 'Parotid_L';
%  registerToAtlas(baseScanFile,movScanFileC,destnDir);
%
% APA, 08/23/2016

% Load base planC
planC = loadPlanC(baseScanFile,tempdir);
planC = updatePlanFields(planC);
planC = quality_assure_planC(baseScanFile,planC);

initRegFlag = 0;
if exist('initPlmCmdFile','var') && ~isempty(initPlmCmdFile)
    initRegFlag = 1;
end
parfor movNum = 1:length(movScanFileC)
    try % required to skip failed registrations
    % Load base planC
    planC = loadPlanC(baseScanFile,tempdir);
    planC = updatePlanFields(planC);
    planC = quality_assure_planC(baseScanFile,planC);
    indexS = planC{end};
    
    % Load moving planC as planD
    planD = loadPlanC(movScanFileC{movNum},tempdir);
    planD = updatePlanFields(planD);
    planD = quality_assure_planC(movScanFileC{movNum},planD);    
    indexSD = planD{end};
    %planD{indexSD.deform}(:) = [];
    
%     % Find the passed structure to warp
%     if exist('strNameToWarp','var')
%         strCreationScanNum = 1;
%         strC = {planD{indexSD.structures}.structureName};
%         %numCharsToMatch = 9;
%         %movStructNumsV = find(strncmp(strNameToWarp,strC,numCharsToMatch));
%         movStructNumsV = getMatchingIndex(strNameToWarp,strC,'exact');
%     end
    
    % Get masks for the dental artifacts
    baseMask3M = planC{indexS.scan}(1).scanArray < 3500;
    movMask3M = planD{indexSD.scan}(1).scanArray < 3500;
    %movMask3M = ~getUniformStr(7,planD); % hand delineated noise
    
    % Register all image representations to each other starting from the
    % transformation generated previously
    numScans = length(planC{indexS.scan});
    numScans = 1;
    allStrNumV = 1:length(planD{indexSD.structures})-1; % -1 to omit the "noise" structure
    assocScanV = getStructureAssociatedScan(allStrNumV,planD);
    
    
    % Align_center the moving scan and structures
    baseScanNum = 1;
    movScanNum = 1;
    algorithm = 'ALIGN CENTER';
    baseMaskAlgCtr3M = [];
    movMaskAlgCtr3M = [];
    threshold_bone = [];
    plmCmdFile = '';
    inBspFile = '';
    vfAlignCtrFile = fullfile(getCERRPath,'ImageRegistration','tmpFiles',...
        strcat(planC{indexS.scan}(1).scanUID,...
        planD{indexSD.scan}(1).scanUID,'_align_ctr.nrrd'));
    [planC, planD] = register_scans(planC, planD, baseScanNum, movScanNum,...
        algorithm, baseMaskAlgCtr3M, movMaskAlgCtr3M, threshold_bone, plmCmdFile, ...
        inBspFile, vfAlignCtrFile);
    numStructs = length(planC{indexS.structures});
    
    numScansMov = length(planD{indexSD.scan});
    % Deform scans and structures based on align_center
    for scanNum = 1:numScansMov
        planD = warp_scan(vfAlignCtrFile,scanNum,planD,planD);
        strV = find(getStructureAssociatedScan(1:numStructs,planD) == scanNum);
        if ~isempty(strV)
            strCreationScanNum = length(planD{indexSD.scan});
            planD = warp_structures(vfAlignCtrFile,strCreationScanNum,strV,planD,planD);
        end
    end
    
    % Delete original scans
    for scanNum = numScansMov:-1:1
        planD = deleteScan(planD,scanNum);
    end
    
    % Delete the Vf file for align_center
    delete(vfAlignCtrFile)
    
    % Remove Warped_ from structure names
    for strNum = 1:length(planD{indexSD.structures})
        indWarp = strfind(planD{indexSD.structures}(strNum).structureName,'Warped_');
        if ~isempty(indWarp)
            planD{indexSD.structures}(strNum).structureName = ...
                planD{indexSD.structures}(strNum).structureName(8:end);
        end
    end    
    
    
    % Create a starting registration transformation based on CT that will
    % be used by all the image representations
    inBspFile = '';
    outBspFile = '';
    if initRegFlag
        
        algorithm = 'BSPLINE PLASTIMATCH';
        algorithm = 'DEMONS PLASTIMATCH';
        baseScanNum = 1; % CT
        movScanNum = 1; % CT
        outBspFile = fullfile(getCERRPath,'ImageRegistration','tmpFiles',...
            strcat(planC{indexS.scan}(1).scanUID,...
            planD{indexSD.scan}(1).scanUID,'_init.nrrd'));
        threshold_bone = -500;
        [planC, planD] = register_scans(planC, planD, baseScanNum, movScanNum,...
            algorithm, baseMask3M, movMask3M, threshold_bone, initPlmCmdFile, ...
            inBspFile, outBspFile);
        
        % Use the outBspFile as input to subsequent registrations
        inBspFile = outBspFile;
        outBspFile = '';
        
    end
    
%     % Register all image representations to each other starting from the
%     % transformation generated previously
%     numScans = length(planC{indexS.scan});
%     numScans = 1;
%     allStrNumV = 1:length(planD{indexSD.structures})-1; % -1 to omit the "noise" structure
%     assocScanV = getStructureAssociatedScan(allStrNumV,planD);
    
    %inputCmdFile = '';
    
    for scanNum = 1:numScans
        
        % Register planD to planC
        baseScanNum = scanNum;
        movScanNum  = scanNum;
        movStructNumsV = find(assocScanV == scanNum);
        strCreationScanNum = scanNum;        
        algorithm = 'BSPLINE PLASTIMATCH';
        %algorithm = 'DEMONS PLASTIMATCH';
        %baseMask3M = [];
        %movMask3M = [];
        if scanNum == 1
            threshold_bone = -400;
        else
            threshold_bone = -7;
        end
        
        if strcmpi(algorithm,'DEMONS PLASTIMATCH')
            outBspFile = fullfile(getCERRPath,'ImageRegistration','tmpFiles',...
                strcat(planC{indexS.scan}(1).scanUID,...
                planD{indexSD.scan}(1).scanUID,'_final.nrrd'));            
        end
        
        [planC, planD] = register_scans(planC, planD, baseScanNum, movScanNum,...
            algorithm, baseMask3M, movMask3M, threshold_bone, refinePlmCmdFile, ...
            inBspFile, outBspFile);
        tic;
        while strcmpi(algorithm,'DEMONS PLASTIMATCH') && ~exist(outBspFile,'file')
            pause(1)
            if toc > 10
                break;
            end
        end
        %pause(1) % avoid feature accel error
        
        % Warp scan
        if strcmpi(algorithm,'DEMONS PLASTIMATCH')
            deformS = outBspFile;
        else            
            deformS = planC{indexS.deform}(end);
        end
        planC = warp_scan(deformS,movScanNum,planD,planC);
        
        % Warp the passed structure
        %if exist('strNameToWarp','var')
        %    planC = warp_structures(deformS,strCreationScanNum,movStructNumsV,planD,planC);
        %end
        
        planC = warp_structures(deformS,strCreationScanNum,movStructNumsV,planD,planC);        

        % delete the output nrrd file
        if strcmpi(algorithm,'DEMONS PLASTIMATCH')
            delete(outBspFile)            
        end
        
    end
    
    try
        delete(inBspFile)
    end
    
    % Save base and moving scans
    [~,fName] = fileparts(movScanFileC{movNum});
    newFileName = fullfile(destnDir,fName);
    save_planC(planC,[],'passed',newFileName);
    catch
    end
end



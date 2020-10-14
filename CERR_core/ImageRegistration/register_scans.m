function [basePlanC, movPlanC, bspFileName] = register_scans(basePlanC, movPlanC,...
    baseScanNum, movScanNum, algorithm, baseMask3M, movMask3M,...
    threshold_bone, inputCmdFile, inBspFile, outBspFile, tmpDirPath)
% function [basePlanC, movPlanC, bspFileName] = register_scans(basePlanC, movPlanC,...
%     baseScanNum, movScanNum, algorithm, baseMask3M, movMask3M,...
%     threshold_bone, inputCmdFile, inBspFile, outBspFile)
%
% APA, 07/12/2012

indexBaseS = basePlanC{end};
indexMovS  = movPlanC{end};

% Write temp files under CERR distribution if tempDirPath is not specified
if ~exist('tmpDirPath','var')
    tmpDirPath = fullfile(getCERRPath,'ImageRegistration','tmpFiles');
end

% "deform" masks are additional structure masks for LDDMM registration; if LDDMM is invoking "register_scan", the deform mask is passed as second cell and bounding crop mask is first cell.
if iscell(baseMask3M) && iscell(movMask3M)
    deformBaseMask3M = baseMask3M{2};
    baseMask3M = baseMask3M{1};
    
    deformMovMask3M = movMask3M{2};
    movMask3M = movMask3M{1};
else
    deformBaseMask3M = [];
    deformMovMask3M = [];
end

%% Create .mha file for base scan & mask(s)

[baseScanUniqName, baseScanUID] = genScanUniqName(basePlanC,baseScanNum);
baseScanFileName = fullfile(tmpDirPath,['baseScan_',baseScanUniqName,'.mha']);
success = createMhaScansFromCERR(baseScanNum, baseScanFileName, basePlanC);

if ~isempty(baseMask3M)
    baseMaskFileName = fullfile(tmpDirPath,['baseMask_',baseScanUniqName,'.mha']);
    success = createMhaMask(baseScanNum, baseMaskFileName, basePlanC, baseMask3M, []);
else
    baseMaskFileName = '';
end

if ~isempty(deformBaseMask3M)
    deformBaseMaskFileName = fullfile(tmpDirPath,['baseDeformMask_',baseScanUniqName,'.mha']);
    success = createMhaMask(baseScanNum, deformBaseMaskFileName, basePlanC, deformBaseMask3M, []);
else
    deformBaseMaskFileName = '';
end

%% Create .mha file for moving scan & mask(s)

[movScanUniqName, movScanUID] = genScanUniqName(movPlanC,movScanNum);
movScanFileName = fullfile(tmpDirPath,['movScan_',movScanUniqName,'.mha']);
success = createMhaScansFromCERR(movScanNum, movScanFileName, movPlanC);

if ~isempty(movMask3M)
    movMaskFileName = fullfile(tmpDirPath,['movMask_',movScanUniqName,'.mha']);
    success = createMhaMask(movScanNum, movMaskFileName, movPlanC, movMask3M, []);
else
    movMaskFileName = '';
end

if ~isempty(deformMovMask3M)
    deformMovMaskFileName = fullfile(tmpDirPath,['deformMovMask_',movScanUniqName,'.mha']);
    success = createMhaMask(movScanNum, deformMovMaskFileName, movPlanC, deformMovMask3M, []);
else
    deformMovMaskFileName = '';
end

%% initialize deformS
algorithmParamsS = [];
deformS = createNewDeformObject(baseScanUID,movScanUID,algorithm,algorithmParamsS);


%% Read build paths and options from CERROptions.json
optS = getCERROptions;

%% Determine registration program from supplied algorithm
plmFlag = 1; antsFlag = 0; elastixFlag = 0;
if any(strfind(upper(algorithm),'ELASTIX'))
    plmFlag = 0;
    elastixFlag = 1;
elseif any(strfind(upper(algorithm),'ANTS'))
    plmFlag = 0;
    antsFlag = 1;
end

%% PLASTIMATCH setup
% Create command file for plastimatch
if plmFlag
    
    % Create a command file path for plastimatch
    plmCommandDir = fullfile(tmpDirPath,'plastimatch_command');
    if ~exist(plmCommandDir,'dir')
        mkdir(plmCommandDir)
    end
    cmdFileName_rigid = fullfile(plmCommandDir,[baseScanUID,'_',movScanUID,'_rigid.txt']);
    cmdFileName_dir   = fullfile(plmCommandDir,[baseScanUID,'_',movScanUID,'_dir.txt']);
    
    if exist(cmdFileName_rigid,'file')
        delete(cmdFileName_rigid);
    end
    if exist(cmdFileName_dir,'file')
        delete(cmdFileName_dir);
    end
    
    % Create a file name and path for storing the resulting transform
    
    bspFileName_rigid = fullfile(tmpDirPath,['bsp_coeffs_',baseScanUID,'_',movScanUID,'_rigid.txt']);
    if exist(bspFileName_rigid,'file')
        delete(bspFileName_rigid)
    end
    
    
    % Deformable (DIR) step
    clear cmdFileC
    if exist('inputCmdFile','var') && ~isempty(inputCmdFile)
        userCmdFile = inputCmdFile;
    else
        optName = fullfile(getCERRPath,'CERROptions.json');
        optS = opts4Exe(optName);
        cmd_fileName = optS.plastimatch_command_file;
        userCmdFile = fullfile(getCERRPath,'ImageRegistration','plastimatch_command',cmd_fileName);
    end
    ursFileC = file2cell(userCmdFile);
    cmdFileC{1,1} = '[GLOBAL]';
    cmdFileC{end+1,1} = ['fixed=',escapeSlashes(baseScanFileName)];
    cmdFileC{end+1,1} = ['moving=',escapeSlashes(movScanFileName)];
    if ~isempty(baseMask3M)
        cmdFileC{end+1,1} = ['fixed_roi=',escapeSlashes(baseMaskFileName)];
    end
    if ~isempty(movMask3M)
        cmdFileC{end+1,1} = ['moving_roi=',escapeSlashes(movMaskFileName)];
    end
    if exist('inBspFile','var') && ~isempty(inBspFile)
        cmdFileC{end+1,1} = ['xform_in=',escapeSlashes(inBspFile)];
    end
    
    % Switch to plastimatch directory if it exists
    %prevDir = pwd;
    plmCommand = 'plastimatch';
    if exist(optS.plastimatch_build_dir,'dir') 
        %cd(optS.plastimatch_build_dir)
        %plmCommand = ['./',plmCommand];
        if isunix
            plmCommand = ['sh ', fullfile(optS.plastimatch_build_dir,plmCommand,' register')];
        else
            plmCommand = [fullfile(optS.plastimatch_build_dir,[plmCommand,'.exe']),' register'];
        end
        
    end
    
end

%% ELASTIX setup
if elastixFlag
    elxCommand = 'elastix';
    if ~exist(optS.elastix_build_dir,'dir')
        error(['Elastix executable path ' optS.elastix_build_dir ' not found on filesystem. Please review CERROptions']);
    end
    %cd(optS.elastix_build_dir)
    if isunix
        elxCommand = ['sh ', fullfile(optS.elastix_build_dir,elxCommand)];
    else
        elxCommand = fullfile(optS.elastix_build_dir,[elxCommand,'.exe']);
    end
end

%% ANTS setup
if antsFlag
    if ~exist(optS.antspath_dir,'dir')
        error(['ANTSPATH ' optS.antspath_dir ' not found on filesystem. Please review CERROptions.']);
    end
    antspath = fullfile(optS.antspath_dir,'bin');
    setenv('ANTSPATH', antspath);
    antsScriptPath = fullfile(optS.antspath_dir, 'Scripts');
    antsCERRScriptPath = fullfile(getCERRPath,'CERR_core','ImageRegistration','antsScripts');
    if isunix
        setenv('PATH',[antspath ':' antsScriptPath ':' antsCERRScriptPath ':' getenv('PATH')]);
    else
        setenv('PATH',[antspath ';' antsScriptPath ';' antsCERRScriptPath ';' getenv('PATH')]);
    end
        
    outPrefix = fullfile(tmpDirPath,[strrep(algorithm, ' ', '_') '_' baseScanUID '_' movScanUID '_']);
    
    bspFileName = '';
end

switch upper(algorithm)
    
    case 'ALIGN CENTER'
        
        %         alignC{1,1} = '#Insight Transform File V1.0';
        %         alignC{end+1,1} = '';
        %         alignC{end+1,1} = '#Transform 0';
        %         alignC{end+1,1} = '';
        %         alignC{end+1,1} = 'Transform: TranslationTransform_double_3_3';
        %         alignC{end+1,1} = '';
        
        %         indexS = basePlanC{end};
        %         [xBaseV, yBaseV, zBaseV] = getScanXYZVals(basePlanC{indexS.scan}(baseScanNum));
        %         indexS = movPlanC{end};
        %         [xMoveV, yMoveV, zMoveV] = getScanXYZVals(movPlanC{indexS.scan}(movScanNum));
        %
        %         deltaX = -(median(xMoveV) - median(xBaseV)) * 10;
        %         deltaY = -(median(yBaseV) - median(yMoveV)) * 10;
        %         deltaZ = -(median(zBaseV) - median(zMoveV)) * 10;
        
        %         alignC{end+1,1} = ['Parameters:',' ',num2str(deltaX),' ',num2str(deltaY),' ',num2str(deltaZ)];
        %         alignC{end+1,1} = '';
        %         alignC{end+1,1} = ['FixedParameters:'];
        %         cell2file(alignC,outBspFile);
        
        %         vf = nan([size(getScanArray(baseScanNum,basePlanC)),3]);
        %         vf(:,:,:,1) = deltaX;
        %         vf(:,:,:,2) = deltaY;
        %         vf(:,:,:,3) = deltaZ;
        %
        %         [~, uniformScanInfoS] = getUniformizedCTScan(0,baseScanNum,basePlanC);
        %         resolution = [uniformScanInfoS.grid2Units, uniformScanInfoS.grid1Units, uniformScanInfoS.sliceThickness] * 10;
        %         [xVals, yVals, zVals] = getUniformScanXYZVals(basePlanC{indexS.scan}(baseScanNum));
        %         offset = [xVals(1) -yVals(1) -zVals(end)] * 10;
        %
        %         writemetaimagefile(outBspFile, single(vf), resolution, offset);
        
        
        % Rigid step
        if exist('outBspFile','var') & ~isempty(outBspFile)
            vfFileName = outBspFile;
        else
            vfFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['align_center_vf_',baseScanUID,'_',movScanUID,'.mha']);
        end
        
        cmdFileC{end+1,1} = ['vf_out=',escapeSlashes(vfFileName)];
        cmdFileC{end+1,1} = '';
        cmdFileC{end+1,1} ='[STAGE]';
        cmdFileC{end+1,1} ='xform=align_center';
        cmdFileC{end+1,1} = '';
        cell2file(cmdFileC,cmdFileName_rigid)
        
        % Run plastimatch Registration
        system([plmCommand, cmdFileName_rigid]);
        
        % Cleanup
        bspFileName = vfFileName;
        
    case {'QUICKSYN ANTS','LDDMM ANTS'}
        antsCommand = buildAntsCommand(algorithm,inputCmdFile,baseScanFileName,movScanFileName, ...
            outPrefix,baseMaskFileName,movMaskFileName, ...
            deformBaseMaskFileName,deformMovMaskFileName);

        system(antsCommand);
        
        deformS.algorithmParamsS.antsCommand = antsCommand;
        deformS.algorithmParamsS.antsWarpProducts = getAntsWarpProducts(outPrefix);

        basePlanC = insertDeformS(basePlanC,deformS);
        movPlanC = insertDeformS(movPlanC,deformS);

    case 'BSPLINE PLASTIMATCH'
        
        deleteBspFlg = 1;
        if exist('outBspFile','var') && ~isempty(outBspFile)
            deleteBspFlg = 0;
            bspFileName = outBspFile;
        else
            %bspFileName = fullfile(getCERRPath,'ImageRegistration',...
            %    'tmpFiles',['bsp_coeffs_',baseScanUID,'_',movScanUID,'.txt']);
            bspFileName = fullfile(tmpDirPath,...
                ['bsp_coeffs_',baseScanUID,'_',movScanUID,'.txt']);
        end
        if exist(bspFileName,'file')
            delete(bspFileName)
        end
        
        
        %cmdFileC{end+1,1} = ['xform_in=',escapeSlashes(bspFileName_rigid)];
        cmdFileC{end+1,1} = ['xform_out=',escapeSlashes(bspFileName)];
        cmdFileC{end+1,1} = '';
        % Append the user-defined stages
        cmdFileC(end+1:end+size(ursFileC,2),1) = ursFileC(:);
        % Add background_max to all the stages if threshold_bone is not empty
        if ~isempty(threshold_bone)
            backgrC = cell(1);
            backgrC{1} = ['background_max=',num2str(threshold_bone)];
            indStageV = find(strcmp(cmdFileC,'[STAGE]'));
            for i = 1:length(indStageV)
                ind = indStageV(i)+i-1;
                cmdFileC(ind+2:end+1) = cmdFileC(ind+1:end);
                cmdFileC(ind+1) = backgrC;
            end
        end
        cell2file(cmdFileC,cmdFileName_dir)
        
        % Run plastimatch Registration
        system([plmCommand, ' ', cmdFileName_dir]);
        
        
        % Read bspline coefficients file
        [bsp_img_origin,bsp_img_spacing,bsp_img_dim,bsp_roi_offset,...
            bsp_roi_dim,bsp_vox_per_rgn,bsp_direction_cosines,bsp_coefficients]...
            = read_bsplice_coeff_file(bspFileName);
        
        % Cleanup
        try
            delete(baseScanFileName);
            delete(movScanFileName);
            if deleteBspFlg
                delete(bspFileName);
            end
            delete(baseMaskFileName);
            delete(movMaskFileName);
            delete(cmdFileName_dir);
        end
        
        % Create a structure for storing algorithm parameters
        algorithmParamsS.bsp_img_origin         = bsp_img_origin;
        algorithmParamsS.bsp_img_spacing        = bsp_img_spacing;
        algorithmParamsS.bsp_img_dim            = bsp_img_dim;
        algorithmParamsS.bsp_roi_offset         = bsp_roi_offset;
        algorithmParamsS.bsp_roi_dim            = bsp_roi_dim;
        algorithmParamsS.bsp_vox_per_rgn        = bsp_vox_per_rgn;
        algorithmParamsS.bsp_coefficients       = bsp_coefficients;
        algorithmParamsS.bsp_direction_cosines  = bsp_direction_cosines;
        
        deformS.algorithmParamsS = algorithmParamsS;
        
        basePlanC = insertDeformS(basePlanC, deformS);
        movPlanC = insertDeformS(movPlanC, deformS);
        
    case 'RIGID PLASTIMATCH'
        
        % Create a command file path for plastimatch
        cmdFileName_rigid = fullfile(getCERRPath,'ImageRegistration','plastimatch_command',[baseScanUID,'_',movScanUID,'_rigid.txt']);
        
        if exist(cmdFileName_rigid,'file')
            delete(cmdFileName_rigid);
        end
        
        % Create a file name and path for storing VF
        if exist('outBspFile','var') & ~isempty(outBspFile)
            vfFileName = outBspFile;
        else
            vfFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['rigid_vf_',baseScanUID,'_',movScanUID,'.mha']);
        end
        if exist(vfFileName,'file')
            delete(vfFileName)
        end
        
        % Rigid step
        ursFileC = file2cell(userCmdFile);
        cmdFileC{end+1,1} = ['vf_out=',escapeSlashes(vfFileName)];
        cmdFileC{end+1,1} = '';
        cmdFileC(end+1:end+size(ursFileC,2),1) = ursFileC(:);
        cell2file(cmdFileC,cmdFileName_rigid)
        
        % Run plastimatch Registration
        system([plmCommand, cmdFileName_rigid]);
        
        bspFileName = vfFileName;
        
        % Cleanup
        try
            delete(baseScanFileName);
            delete(movScanFileName);
            if deleteBspFlg
                delete(bspFileName);
            end
            delete(baseMaskFileName);
            delete(movMaskFileName);
            delete(cmdFileName_dir);
        end
        
        %         % Read output file
        %         fileC = file2cell(bspFileName_rigid);
        %         indParam = strfind(fileC{4},'Parameters:');
        %         rigidParamsV = str2num(fileC{4}(indParam+11:end));
        %         indParam = strfind(fileC{5},'FixedParameters:');
        %         fixedParamsV = str2num(fileC{5}(indParam+16:end));
        %         translationM = eye(4);
        %         translationM(1:3,1:3) = reshape(rigidParamsV(1:9),3,3)';
        %         translationM(1:3,4) = rigidParamsV(10:12)/10;
        %         %translationM(4,1:3) = rigidParamsV(10:12)/10;
        %         transM = translationM;
        %         transM(2:3,4) = -transM(2:3,4);
        %         %         translationM(1:3,4) = -rigidParamsV(4:6)/10;
        %         %         translationM(3,4) = -translationM(3,4);
        %         %         Rx = eye(4);
        %         %         Rx([2 3],[2 3]) = [cos(rigidParamsV(1)) sin(rigidParamsV(1)); -sin(rigidParamsV(1)) cos(rigidParamsV(1))];
        %         %         Ry = eye(4);
        %         %         Ry([1 3],[1 3]) = [cos(rigidParamsV(2)) -sin(rigidParamsV(2)); sin(rigidParamsV(2)) cos(rigidParamsV(2))];
        %         %         Rz = eye(4);
        %         %         Rz([1 2],[1 2]) = [cos(rigidParamsV(3)) sin(rigidParamsV(3)); -sin(rigidParamsV(3)) cos(rigidParamsV(3))];
        %         %         bakTransM = eye(4);
        %         %         bakTransM(1:3,4) = fixedParamsV/10;
        %         %         bakTransM(3,4) = -bakTransM(3,4);
        %         %         fwTransM = eye(4);
        %         %         fwTransM(1:3,4) = -fixedParamsV/10;
        %         %         fwTransM(3,4) = -fwTransM(3,4);
        %         %         transM = bakTransM*Rx*Ry*Rz*fwTransM*translationM;
        %         movPlanC{indexMovS.scan}(movScanNum).transM = transM;
        
        
    case 'BSPLINE ITK'
        
        
    case 'DEMONS PLASTIMATCH'
        
        deleteBspFlg = 1;
        if exist('outBspFile','var') && ~isempty(outBspFile)
            deleteBspFlg = 0;
            bspFileName = outBspFile;
        else
            bspFileName = fullfile(getCERRPath,'ImageRegistration',...
                'tmpFiles',['bsp_coeffs_',baseScanUID,'_',movScanUID,'.nrrd']);
        end
        if exist(bspFileName,'file')
            delete(bspFileName)
        end
        
        %cmdFileC{end+1,1} = ['xform_in=',escapeSlashes(bspFileName_rigid)];
        cmdFileC{end+1,1} = ['xform_out=',escapeSlashes(bspFileName)];
        cmdFileC{end+1,1} = '';
        % Append the user-defined stages
        cmdFileC(end+1:end+size(ursFileC,2),1) = ursFileC(:);
        % Add background_max to all the stages if threshold_bone is not empty
        if ~isempty(threshold_bone)
            backgrC = cell(1);
            backgrC{1} = ['background_max=',num2str(threshold_bone)];
            indStageV = find(strcmp(cmdFileC,'[STAGE]'));
            for i = 1:length(indStageV)
                ind = indStageV(i)+i-1;
                cmdFileC(ind+2:end+1) = cmdFileC(ind+1:end);
                cmdFileC(ind+1) = backgrC;
            end
        end
        cell2file(cmdFileC,cmdFileName_dir)
        
        % Run plastimatch Registration
        system([plmCommand, cmdFileName_dir]);
        
        % Cleanup
        try
            delete(baseScanFileName);
            delete(movScanFileName);
            if deleteBspFlg
                delete(bspFileName);
            end
            delete(baseMaskFileName);
            delete(movMaskFileName);
            delete(cmdFileName_dir);
        end
        
        
    case 'ELASTIX'
        
        deleteBspFlg = 1;
        if exist('outBspFile','var') && ~isempty(outBspFile)
            deleteBspFlg = 0;
            elxOutDir = outBspFile;
        else
            elxOutDir = fullfile(tmpDirPath,...
                ['bsp_coeffs_',baseScanUID,'_',movScanUID]);
        end
        if exist(elxOutDir,'dir')
            try
                rmdir(elxOutDir,'s')
            end
        end
        
        mkdir(elxOutDir)
        
        % 'elastix -f fixedImage.ext -m movingImage.ext -out outputDirectory -p parameterFile.txt'
        elxCommand = [elxCommand, ' -f ', escapeSlashes(baseScanFileName),...
            ' -m ',escapeSlashes(movScanFileName)];
        if ~isempty(baseMask3M)
            elxCommand = [elxCommand, ' -fMask ', escapeSlashes(baseMaskFileName)];
        end
        if ~isempty(movMask3M)
            elxCommand = [elxCommand, ' -mMask ', escapeSlashes(movMaskFileName)];
        end
        elxCommand = [elxCommand, ' -out ', escapeSlashes(elxOutDir)];
        if iscell(inputCmdFile)
            for iStage = 1:length(inputCmdFile)
                elxCommand = [elxCommand,  ' -p ', escapeSlashes(inputCmdFile{iStage})];
            end
        else
            elxCommand = [elxCommand,  ' -p ', escapeSlashes(inputCmdFile)];
        end
        
        % Run Elastix Registration
        system(elxCommand);
        
        % Create a structure for storing algorithm parameters
        dirS = dir(elxOutDir);
        namC = {dirS.name};
        indTransformParamV = strncmp({dirS.name},'TransformParameters',19);
        indTransformParamV = find(indTransformParamV);
        for i = 1:length(indTransformParamV)
            ind = indTransformParamV(i);
            fname = namC{ind};
            [~,fnameNoExt] = fileparts(fname);
            fnameNoExt = strrep(fnameNoExt,'.','_');
            algorithmParamsS.(fnameNoExt)= file2cell(fullfile(elxOutDir,fname));
        end
        
        % Create new deform object
%         deformS = createNewDeformObject(baseScanUID,movScanUID,algorithm,algorithmParamsS);
        deformS.algorithmParamsS = algorithmParamsS;
        
        % Add deform object to both base and moving planC's
        baseDeformIndex = length(basePlanC{indexBaseS.deform}) + 1;
        movDeformIndex  = length(movPlanC{indexMovS.deform}) + 1;
        basePlanC{indexBaseS.deform}  = dissimilarInsert(basePlanC{indexBaseS.deform},deformS,baseDeformIndex);
        movPlanC{indexMovS.deform}  = dissimilarInsert(movPlanC{indexMovS.deform},deformS,movDeformIndex);
                
        % Cleanup
        try
            delete(baseScanFileName);
            delete(movScanFileName);
            if deleteBspFlg
                rmdir(elxOutDir,'s');
            end
            delete(baseMaskFileName);
            delete(movMaskFileName);
            %delete(cmdFileName_dir);
        end        
       
        
    case 'DEMONS ITK'
        
end

% Switch back to the previous directory
% cd(prevDir)

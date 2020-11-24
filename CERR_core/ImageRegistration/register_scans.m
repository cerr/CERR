function [basePlanC, movPlanC, bspFileName] = register_scans(basePlanC, baseScanNum, movPlanC,movScanNum, algorithm, registration_tool, tmpDirPath, ... 
    baseMask3M, movMask3M, threshold_bone, inputCmdFile, inBspFile, outBspFile)
% Usage: [basePlanC, movPlanC, bspFileName] = register_scans(basePlanC, baseScanNum, movPlanC,movScanNum, algorithm, registration_tool, tmpDirPath, ... 
%     baseMask3M, movMask3M, threshold_bone, inputCmdFile, inBspFile, outBspFile)
%
%  Arguments: 
%         basePlanC - CERR planC struct (cell) or 3D image filename, contains fixed target scan (1)
%         baseScanNum - integer, identifies target scan in basePlanC (2)
%         movPlanc - CERR planC struct, contains moving scan (3) 
%         movScanNum - integer, identifies moving scan in movPlanC (4)
%         algorithm - string, identifies type of registration to run (5)
%         registration_tool - string, identifies registration software to use ('PLASTIMATCH','ELASTIX','ANTS'); (6)
%    optional varargin:
%         tmpDirPath - string to working directory location (7)
%         baseMask3M - 3D or 4D binary mask(s) in target space (8)
%         movMask3M - 3D or 4D binary mask(s) in moving space (9)
%         threshold_bone - scalar value for CT HU thresholding (10)
%         inputCmdFile - string or cell array of strings to parameter files  (11)
%         inBspFile - paramter file for plastimatch (12)
%         outBspFile - output filename for plastimatch (13)
%
% APA, 07/12/2012
% EML 10/2020

%check whether planC is a scan or filename
basegz = '';
if ~ischar(basePlanC) && ~iscell(basePlanC)
    error('Input should be filename string or planC cell array');
elseif ischar(basePlanC)
    xsplit = strsplit(basePlanC,'.');
    if any(strcmp(xsplit{end},{'bz2','gz'}))
        basegz = ['.' xsplit{end}];
        baseext = xsplit{end - 1};
    else
        baseext = xsplit{end};
    end
    if ~any(strcmp(baseext,{'mat','nii','mha','img','hdr'}))
        error('Base image filename should be planC (.mat) or 3D image volume (mha, nii, img/hdr');
    elseif strcmp(baseext,'mat')
        basePlanC = loadPlanC(basePlanC);
    end
end

movegz = '';
if ~ischar(movPlanC) && ~iscell(movPlanC)
    error('Input should be filename string or planC cell array');
elseif ischar(movPlanC)
    xsplit = strsplit(movPlanC,'.');
    if any(strcmp(xsplit{end},{'bz2','gz'}))
        movegz = ['.' xsplit{end}];
        moveext = xsplit{end - 1};
    else
        moveext = xsplit{end};
    end
    if ~any(strcmp(moveext,{'mat','nii','mha','img','hdr'}))
        error('Moving image filename should be for planC (.mat) or 3D image volume (mha, nii, img/hdr');
    elseif strcmp(moveext, 'mat')
        movPlanC = loadPlanC(movPlanC);
    end
end

if ~exist('outBspFile','var')
    outBspFile = '';
end

if ~exist('inBspFile', 'var')
    inBspFile = '';
end

if ~exist('inputCmdFile', 'var')
    inputCmdFile = '';
end

if ~exist('threshold_bone', 'var')
    threshold_bone = [];
end

if ~exist('movMask3M', 'var')
    movMask3M = [];
end

if ~exist('baseMask3M', 'var')
    baseMask3M = [];
end

if ~exist('tmpDirPath', 'var') || isempty(tmpDirPath)
    tmpDirPath = fullfile(getCERRPath, 'ImageRegistration', 'tmpFiles'); % Write temp files under CERR distribution if tmpDirPath is not specified
end

%% Set flag for registration program 
plmFlag = 0; elastixFlag = 0; antsFlag = 0;
switch upper(registration_tool)
    case 'PLASTIMATCH'
        plmFlag = 1;
        disp('Plastimatch selected');
    case 'ELASTIX'
        elastixFlag = 1;
        disp('Elastix selected');
    case 'ANTS'
        antsFlag = 1;
        disp('ANTs selected');
end

%% Parse input masks ("deform" masks are additional structure masks for LDDMM registration; if LDDMM is invoking "register_scan", the deform mask is passed as second volume, bounding mask is first volume)
if numel(size(baseMask3M)) > 3 && numel(size(movMask3M)) > 3
    deformBaseMask3M = baseMask3M(:,:,:,2);
    baseMask3M = baseMask3M(:,:,:,1);
    
    deformMovMask3M = movMask3M(:,:,:,2);
    movMask3M = movMask3M(:,:,:,1);
else
    deformBaseMask3M = [];
    deformMovMask3M = [];
end

%% Convert basePlanC scan & mask(s) to .mha file

[baseScanUniqName, baseScanUID] = genScanUniqName(basePlanC,baseScanNum);
if ischar(basePlanC)
    baseScanFileName = fullfile(tmpDirPath, ['baseScan_' baseScanUniqName '.' baseext basegz]);
    copyfile(basePlanC, baseScanFileName);
else
    baseScanFileName = fullfile(tmpDirPath,['baseScan_',baseScanUniqName,'.mha']);
    success = createMhaScansFromCERR(baseScanNum, baseScanFileName, basePlanC);
end

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

%% Convert movPlanC scan & mask(s) to .mha file
[movScanUniqName, movScanUID] = genScanUniqName(movPlanC,movScanNum);
if ischar(movPlanC)
    movScanFileName = fullfile(tmpDirPath, ['movScan_' movScanUniqName '.' moveext movegz]);
    copyfile(movPlanC, movScanFileName);
else
    movScanFileName = fullfile(tmpDirPath,['movScan_',movScanUniqName,'.mha']);
    success = createMhaScansFromCERR(movScanNum, movScanFileName, movPlanC);
end

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
deformS = createNewDeformObject(baseScanUID,movScanUID,algorithm,registration_tool,algorithmParamsS);


%% Read build paths and options from CERROptions.json
optS = getCERROptions;


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

% Run plastimatch cases
switch upper(algorithm)
    case 'ALIGN CENTER'
        
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
    case {'BSPLINE PLASTIMATCH','BSPLINE'}
        
        deleteBspFlg = 1;
        if exist('outBspFile','var') && ~isempty(outBspFile)
            deleteBspFlg = 0;
            bspFileName = outBspFile;
        else
            %bspFileName = fullfile(getCERRPath,'ImageRegistration',...
            %    'tmpFiles',['bsp_coeffs_',baseScanUID,'_',movScanUID,'.txt']);
            bspFileName = fullfile(tmpDirPath, ['bsp_coeffs_',baseScanUID,'_',movScanUID,'.txt']);
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
%             if deleteBspFlg
%                 delete(bspFileName);
%             end
            delete(baseMaskFileName);
            delete(movMaskFileName);
%             delete(cmdFileName_dir);
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
    
%    Run Elastix cases
switch upper(algorithm)
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
        basePlanC = insertDeformS(basePlanC,deformS);
        movPlanC = insertDeformS(movPlanC,deformS);              
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
        
end %elastix algorithms

end %elastix flag

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
    
    % Run ANTs cases
    switch upper(algorithm)
        case {'QUICKSYN ANTS', 'LDDMM ANTS', 'QUICKSYN', 'LDDMM'}
            antsCommand = buildAntsCommand(algorithm,inputCmdFile,baseScanFileName,movScanFileName, ...
                outPrefix,baseMaskFileName,movMaskFileName, ...
                deformBaseMaskFileName,deformMovMaskFileName);
            disp(['Executing: ' antsCommand]);
            system(antsCommand);
            
            deformS.algorithmParamsS.antsCommand = antsCommand;
            deformS.algorithmParamsS.antsWarpProducts = getAntsWarpProducts(outPrefix);
            
            if iscell(basePlanC)
                basePlanC = insertDeformS(basePlanC,deformS);
            end
            if iscell(movPlanC)
                movPlanC = insertDeformS(movPlanC,deformS);
            end
            
            %add warped image to planC
            if exist(deformS.algorithmParamsS.antsWarpProducts.Warped,'file')
                save_flag = 0; movScanOffset = 0;
                movScanName = ['deformed_' strrep(algorithm,' ','_')  '_' registration_tool];
                warpedMhaFile = deformS.algorithmParamsS.antsWarpProducts.Warped;
                [~,~,e] = fileparts(warpedMhaFile);
                if strcmp(e,'.mha')
                    infoS  = mha_read_header(warpedMhaFile);
                    data3M = mha_read_volume(infoS);
                    basePlanC  = mha2cerr(infoS,data3M, movScanOffset, movScanName, basePlanC, save_flag);
                else
                    basePlanC = nii2cerr(warpedMhaFile,movScanName,basePlanC,save_flag);
                end
            end
    end
end
    
end
% 
% function TF = checkPlanCInput(x)
%    TF = false;
%    if ~ischar(x) || ~iscell(x)
%        error('Input should be filename string or planC cell array');
%    elseif ischar(x)
%        xsplit = strsplit(x,'.');
%        if any(strcmp(xsplit{end},{'bz2','gz'}))
%            ext = xsplit{end - 1};
%        else
%            ext = xsplit{end};
%        end
%        if ~any(strcmp(ext,{'mat','nii','mha','img','hdr'}))
%            error('Filename should be for planC (.mat) or 3D image volume (mha, nii, img/hdr');
%        else
%            TF = true;
%        end
%    end
% end
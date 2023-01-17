function [basePlanC, movPlanC, deformS] = register_scans(basePlanC, baseScanNum, movPlanC,movScanNum, algorithm, registration_tool, tmpDirPath, ... 
    baseMask3M, movMask3M, threshold_bone, inputCmdFile, inBspFile, outBspFile, landmarkList, initialXyzTranslationV)
% Usage: [basePlanC, movPlanC, bspFileName] = register_scans(basePlanC, baseScanNum, movPlanC,movScanNum, algorithm, registration_tool, tmpDirPath, ... 
%     baseMask3M, movMask3M, threshold_bone, inputCmdFile, inBspFile, outBspFile, landmarkList, initialXyzTranslationV)
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

if ~exist('landmarkFlag','var') || isempty(landmarkFlag)
    landmarkFlag = 0;
end

if ~exist('landmarkList','var')
    landmarkList = [];
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
deformS = createNewDeformObject(baseScanUID,movScanUID,algorithm,...
    registration_tool,algorithmParamsS);

%% set output MHA image prefix
outPrefix = fullfile(tmpDirPath,[strrep(algorithm, ' ', '_') '_' baseScanUID '_' movScanUID]);


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
    
    cmdFileName = fullfile(plmCommandDir,[baseScanUID,'_',movScanUID,'_cmdFile.txt']);
    
    if exist(cmdFileName,'file')
        delete(cmdFileName);
    end
    
    % Create a file name and path for storing the resulting transform
    xformFileNameBase = fullfile(tmpDirPath,['xform_coeffs_',baseScanUID,'_',movScanUID,'_xform']);
    if exist(xformFileNameBase,'file')
        delete(xformFileNameBase);
    end
    
    % Compose cmdFileC command file
    if exist('inputCmdFile','var') && ~isempty(inputCmdFile)
        userCmdFile = inputCmdFile;
    else
        userCmdFile = '';
    end

    warpedMhaFile = [outPrefix '.mha'];
    
    % Create inBspFile for initial translation
    if exist('initialXyzTranslationV','var')
        inBspFile = fullfile(tmpDirPath,['xform_init_',baseScanUID,'_',movScanUID,'.txt']);
        createInitialTranslationTransform(inBspFile,initialXyzTranslationV)
    end
    
    cmdFileC = genPlastimatchCmdFile(baseScanFileName, movScanFileName, ...
        baseMaskFileName, movMaskFileName, warpedMhaFile, inBspFile, ...
        xformFileNameBase, algorithm, userCmdFile, threshold_bone, landmarkList);
    cell2file(cmdFileC,cmdFileName);
    
    % Run plastimatch cases
    plmCommand = 'plastimatch';
    
    deleteBspFlg = 1; % for b-splines
    
    if exist(optS.plastimatch_build_dir,'dir')
        plmCommand = fullfile(optS.plastimatch_build_dir,plmCommand);
    else
        if isunix
            plmCommand = [plmCommand,' register ' cmdFileName];
        else
            plmCommand = [plmCommand '.exe register ' cmdFileName];
        end
    end
    
    % Run plastimatch Registration
    system([plmCommand ' ' cmdFileName]);
    
    %Return xform coefficients
    
    algorithmParamsS = readPlastimatchCoeffs(xformFileNameBase,algorithm);
    
    deformS.algorithmParamsS = algorithmParamsS;
    
    basePlanC = insertDeformS(basePlanC, deformS);
    movPlanC = insertDeformS(movPlanC, deformS);
    
    %add warped image to planC
    if exist(warpedMhaFile,'file')
        save_flag = 0; 
        movScanName = ['deformed_' strrep(algorithm,' ','_')  '_' registration_tool];
        infoS  = mha_read_header(warpedMhaFile);
        data3M = mha_read_volume(infoS);
        movScanOffset = -min(0,min(data3M(:)));
        basePlanC  = mha2cerr(infoS,data3M, movScanOffset, movScanName, basePlanC, save_flag);
        indexS = basePlanC{end};
        imageOrientationPatient = basePlanC{indexS.scan}(baseScanNum).scanInfo(1).imageOrientationPatient;
        numSlcs = length(basePlanC{indexS.scan}(end).scanInfo);
        for slcNum = 1:numSlcs
            basePlanC{indexS.scan}(end).scanInfo(slcNum).imageOrientationPatient = imageOrientationPatient;
        end
    end
    
    % Cleanup
    try
        delete(baseScanFileName);
        delete(movScanFileName);
        if deleteBspFlg
            delete(cmdFileName);
        end
        delete(baseMaskFileName);
        delete(movMaskFileName);
        %delete(cmdFileName_dir);
        [workingDir,baseFile,~] = fileparts(baseScanFileName);
        [workingDir,movFile,~] = fileparts(movScanFileName);
        baseLandmarkFile = fullfile(workingDir,[baseFile '.csv']);
        movLandmarkFile = fullfile(workingDir,[movFile '.csv']);
        if exist(baseLandmarkFile,'file')
            delete(baseLandmarkFile)
        end
        if exist(movLandmarkFile,'file')
            delete(movLandmarkFile)
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
                save_flag = 0;
                movScanName = ['deformed_' strrep(algorithm,' ','_')  '_' registration_tool];
                warpedMhaFile = deformS.algorithmParamsS.antsWarpProducts.Warped;
                [~,~,e] = fileparts(warpedMhaFile);
                if strcmp(e,'.mha')
                    infoS  = mha_read_header(warpedMhaFile);
                    data3M = mha_read_volume(infoS);
                    movScanOffset = -min(0,min(data3M(:)));
                    basePlanC  = mha2cerr(infoS,data3M, movScanOffset, movScanName, basePlanC, save_flag);
                else
                    basePlanC = nii2cerr(warpedMhaFile,movScanName,basePlanC,save_flag);
                end
            end
    end
end

%% Add associated base and moving scanUIDs
warpedScanNum = length(basePlanC{indexS.scan});
basePlanC{indexS.scan}(warpedScanNum).assocBaseScanUID = baseScanUID;
basePlanC{indexS.scan}(warpedScanNum).assocMovingScanUID = movScanUID;

    
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
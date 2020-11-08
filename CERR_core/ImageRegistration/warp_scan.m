function planC = warp_scan(deformS,movScanNum,movPlanC,planC,tmpDirPath,interpolation,inverseFlag)
% function planC = warp_scan(deformS,movScanNum,movPlanC,planC,tmpDirPath,interpolation)
%
% APA, 07/19/2012

if ~isstruct(deformS)
    error('deformS must be in form of deformS --> baseScanUID, movScanUID, algorithm, algorithmParamsS')
end


if ~exist('interpolation','var')
    interpolation = '';
end


if ~exist('inverseFlag','var')
    inverseFlag = '';
end


if ~exist('tmpDirPath','var')
    tmpDirPath = fullfile(getCERRPath,'ImageRegistration','tmpFiles');
end


%% Read in CERR options
optS = getCERROptions;

% Create b-spline coefficients file
algorithm = deformS.algorithm;
% else
%     algorithm = 'PLASTIMATCH';
% end

%% Convert moving scan to .mha
indexMovS = movPlanC{end};
movScanOffset = movPlanC{indexMovS.scan}(movScanNum).scanInfo(1).CTOffset;
movScanName = [movPlanC{indexMovS.scan}(movScanNum).scanType '_deformed'];

[movScanUniqName,movScanUID] = genScanUniqName(movPlanC, movScanNum);
movScanFileName = fullfile(tmpDirPath,['movScan_',movScanUniqName,'.mha']);
success = createMhaScansFromCERR(movScanNum, movScanFileName, movPlanC);


%%  Convert reference (target) scan to .mha (req for ANTs)
refScanNum = findScanByUID(planC,deformS.baseScanUID);
if ~isempty(refScanNum)
    [refScanUniqName, baseScanUID] = genScanUniqName(planC, refScanNum);
    refScanFileName = fullfile(tmpDirPath,['refScan_',refScanUniqName,'.mha']);
    success = createMhaScansFromCERR(refScanNum, refScanFileName, planC);
else
    baseScanUID = deformS.baseScanUID;
end


%% Output prefix
warpOutPrefix = fullfile(tmpDirPath,['warped_scan_', baseScanUID, '_', movScanUID]);


%% Run scan warp
switch upper(algorithm)
    case 'ELASTIX'
        % Generate name for the output directory 
        warpedDir = warpOutPrefix;   
        
        if ~exist(warpedDir,'dir')
            mkdir(warpedDir)
        end
        
        % Read Elastix build path from CERROptions.json
        elxTransformCmd = 'transformix';
        if ~exist(optS.elastix_build_dir,'dir')
            error(['ELASTIX executable not found on path ' optS.elastix_build_dir]);
        end
            %cd(optS.elastix_build_dir)
            
        if isunix
            elxTransformCmd = ['sh ', fullfile(optS.elastix_build_dir,elxTransformCmd)];
        else
            elxTransformCmd = fullfile(optS.elastix_build_dir,[elxTransformCmd,'.exe']);
        end

        transformC = fieldnames(deformS.algorithmParamsS);
        for iTransform = 1:length(transformC)
            fileC = deformS.algorithmParamsS.(transformC{iTransform});
            transformFileName = fullfile(warpedDir,[transformC{iTransform},'.txt']);
            fileC = fileC(:);
            numRows = length(fileC);
            ind = [];
            indNoTf = [];
            for row = 1:numRows
                ind = strfind(fileC{row},'(InitialTransformParametersFileName');
                indNoTf = strfind(fileC{row},...
                    '(InitialTransformParametersFileName "NoInitialTransform")');
                if ~isempty(ind) || ~isempty(indNoTf)
                    break
                end
            end            
            if ~isempty(ind) && isempty(indNoTf)
                indV = strfind(fileC{row},'"');
                strTf = fileC{row};
                tfFileName = strTf(indV(1)+1:indV(2)-1);
                [~,fname,ext] = fileparts(tfFileName);
                fname = [fname(1:end-2),'_',fname(end)];
                fname = fullfile(warpedDir,[fname,ext]);                
                newStr = ['(InitialTransformParametersFileName "',fname,'")'];
                fileC{row} = newStr;
            end
            cell2file(fileC,transformFileName);
        end
        indV = cellfun(@(x) str2double(x(end)),transformC); % will work only up to 9 transforms
        lastTransform = max(indV);
        lastTransformName = fullfile(warpedDir,...
            ['TransformParameters_',num2str(lastTransform),'.txt']);
        %elxTransformCmd = [elxTransformCmd,' -def all -out ',...
        %    outputDirectory, ' -tp ',lastTransformName]; % DVF
        % fullfile(outputDirectory,'deformationField.mhd'); % Name of mhd
        % file containing DVF
        elxTransformCmd = [elxTransformCmd,' -in ',movScanFileName,...
            ' -out ',warpedDir, ' -tp ',lastTransformName];
        system(elxTransformCmd)    
        
        warpedNrrdFileName = fullfile(warpedDir,'result.nrrd');
        
        % Read the warped output .nrrd file within CERR
        [data3M, infoS] = nrrd_read(warpedNrrdFileName);
        data3M = permute(data3M,[2,1,3]); % required since mha2cerr.m does this: permute(data3M,[2,1,3])
        datamin = min(data3M(:));
        movScanOffset = 0;
        if datamin < 0
            movScanOffset = -datamin;
        end
        save_flag = 0;
        planC  = mha2cerr(infoS,data3M,movScanOffset,movScanName, planC, save_flag);
        
        % Cleanup
        try
            delete(movScanFileName)
            rmdir(warpedDir,'s')
        end       
                
    case {'LDDMM ANTS','QUICKSYN ANTS'}
        warpedMhaFileName = [warpOutPrefix '.mha']; %fullfile(tmpDirPath,['warped_scan_', refScanUID, '_', movScanUID, '.mha']);
        % ANTs path setup
        if ~exist(optS.antspath_dir,'dir')
            error(['ANTSPATH ' optS.antspath_dir ' not found on filesystem. Please review CERROptions.']);
        end
        antspath = fullfile(optS.antspath_dir,'bin');
        setenv('ANTSPATH', antspath);
        antsScriptPath = fullfile(optS.antspath_dir, 'Scripts');
        antsCERRScriptPath = fullfile(getCERRPath,'CERR_core','ImageRegistration','antsScripts');
        if isunix
            setenv('PATH',[antspath ':' antsScriptPath ':' antsCERRScriptPath ':' getenv('PATH')]);
            antsCommand = '';
        else
            setenv('PATH',[antspath ';' antsScriptPath ';' antsCERRScriptPath ';' getenv('PATH')]);
            antsCommand = '';
        end
        % generate transform command
        transformParams = buildAntsTransform(deformS.algorithmParamsS.antsWarpProducts);
%         transformParams ='';
%         if ~isempty(deformS.algorithmParamsS.antsWarpProducts.Warp) 
%             if exist(deformS.algorithmParamsS.antsWarpProducts.Warp,'file')
%                 transformParams = [' -t ' deformS.algorithmParamsS.antsWarpProducts.Warp ' '];
%             else
%                 error(['Unable to complete transform, warp product missing: ' deformS.algorithmParamS.antsWarpProducts.Warp]);
%             end
%         end
%         if ~isempty(deformS.algorithmParamsS.antsWarpProducts.Affine)
%             if exist(deformS.algorithmParamsS.antsWarpProducts.Affine, 'file')
%                 transformParams = [transformParams ' -t ' deformS.algorithmParamsS.antsWarpProducts.Affine ' '];
%             else
%                 error(['Unable to complete transform, affine product missing: ' deformS.algorithmParamsS.antsWarpProducts.Affine]);
%             end
%         end
%         if isempty(transformParams)
%             error('ANTs: No transformation products specified');
%         end
        if ~isempty(interpolation)
            interpParams = [' -n ' interpolation];
        else
            interpParams = ' ';
        end
        
        antsCommand = [antsCommand ' antsApplyTransforms -d 3 -r ' refScanFileName ' -i ' movScanFileName ' -o ' warpedMhaFileName ' ' transformParams ' ' interpParams];
        disp(antsCommand);
        system(antsCommand);
        disp('Warp complete, importing warped scan to planC...');
        
        infoS  = mha_read_header(warpedMhaFileName);
        data3M = mha_read_volume(infoS);
        save_flag = 0;
        planC  = mha2cerr(infoS,data3M,movScanOffset,movScanName, planC, save_flag);
        disp('Warp scan import complete. Cleaning up...');
        
        % clean up
        try
            delete(movScanFileName);
            delete(refScanFileName);
            delete(warpedMhaFileName);
        catch err
            disp(err);
            disp('Unable to clean up ANTs output files');
        end

        
    otherwise % PLASTIMATCH
        % Generate name for the output .mha file
        warpedMhaFileName = [warpOutPrefix '.mha']; %fullfile(tmpDirPath, ['warped_scan_',baseScanUID,'_',movScanUID,'.mha']);        
        
%         if ~isstruct(deformS)
%             bspFileName = deformS;
            %indexS = planC{end};
            %movScanUID = movPlanC{indexMovS.scan}(movScanNum).scanUID;
            %baseScanUID = planC{indexS.scan}(movScanNum).scanUID;
        %         else
        bspFileName = fullfile(getCERRPath,...
            'ImageRegistration','tmpFiles',...
            ['bsp_coeffs_',baseScanUID,'_',movScanUID,'.txt']);
        %         end
        success = write_bspline_coeff_file(bspFileName,deformS.algorithmParamsS);
        
        % Switch to plastimatch directory if it exists
        prevDir = pwd;
        
        % Build plastimatch warp command
        plmCommand = 'plastimatch warp ';
        optName = fullfile(getCERRPath,'CERROptions.json');
        optS = opts4Exe(optName);
        if exist(optS.plastimatch_build_dir,'dir') && isunix
            cd(optS.plastimatch_build_dir)
            plmCommand = ['./',plmCommand];
        end
        
        % Issue plastimatch warp command
        fail = system([plmCommand, '--input ', movScanFileName,...
            ' --output-img ', warpedMhaFileName, ' --xf ', bspFileName]);
        if fail % try escaping slashes
            system([plmCommand, '--input ', escapeSlashes(movScanFileName),...
                ' --output-img ', escapeSlashes(warpedMhaFileName),...
                ' --xf ', escapeSlashes(bspFileName)])
        end
        
        % Switch back to the previous directory
        cd(prevDir)      
        
        % Read the warped output .mha file within CERR
        infoS  = mha_read_header(warpedMhaFileName);
        data3M = mha_read_volume(infoS);
        %[data3M,infoS] = readmha(warpedMhaFileName);
        save_flag = 0;
        planC  = mha2cerr(infoS,data3M,movScanOffset,movScanName, planC, save_flag);
        
        % Cleanup
        try
            if isstruct(deformS)
                delete(bspFileName)
            end
            delete(movScanFileName)
            delete(warpedMhaFileName)
        end
        
        
end


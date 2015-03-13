function [basePlanC, movPlanC] = register_scans(basePlanC, movPlanC, baseScanNum, movScanNum, algorithm, baseMask3M, movMask3M, threshold_bone)
% function [basePlanC, movPlanC] = register_scans(basePlanC, movPlanC, baseScanNum, movScannum, algorithm, baseMask3M, movMask3M, threshold_bone)
%
% APA, 07/12/2012

indexBaseS = basePlanC{end};
indexMovS  = movPlanC{end};

% Create .mha file for base scan
baseScanUID = basePlanC{indexBaseS.scan}(baseScanNum).scanUID;
randPart = floor(rand*1000);
baseScanUniqName = [baseScanUID,num2str(randPart)];
baseScanFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['baseScan_',baseScanUniqName,'.mha']);
baseMaskFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['baseMask_',baseScanUniqName,'.mha']);
if exist(baseScanFileName,'file')
    delete(baseScanFileName);
end
if exist(baseMaskFileName,'file')
    delete(baseMaskFileName);
end
success = createMhaScansFromCERR(baseScanNum, baseScanFileName, basePlanC);
success = createMhaMask(baseScanNum, baseMaskFileName, basePlanC, baseMask3M, threshold_bone);

% Create .mha file for moving scan
movScanUID = movPlanC{indexMovS.scan}(movScanNum).scanUID;
randPart = floor(rand*1000);
movScanUniqName = [movScanUID,num2str(randPart)];
movScanFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['movScan_',movScanUniqName,'.mha']);
movMaskFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['movMask_',movScanUniqName,'.mha']);
if exist(movScanFileName,'file')
    delete(movScanFileName);
end
if exist(movMaskFileName,'file')
    delete(movMaskFileName);
end
success = createMhaScansFromCERR(movScanNum, movScanFileName, movPlanC);
%success = createMhaMask(movScanNum, movMaskFileName, movPlanC, movMask3M, threshold_bone);
success = createMhaMask(movScanNum, movMaskFileName, movPlanC, movMask3M, []);


switch upper(algorithm)
    
    case 'BSPLINE PLASTIMATCH'
        
        %         % Create .mha file for base scan
        %         baseScanUID = basePlanC{indexBaseS.scan}(baseScanNum).scanUID;
        %         randPart = floor(rand*1000);
        %         baseScanUniqName = [baseScanUID,num2str(randPart)];
        %         baseScanFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['baseScan_',baseScanUniqName,'.mha']);
        %         baseMaskFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['baseMask_',baseScanUniqName,'.mha']);
        %         if exist(baseScanFileName,'file')
        %             delete(baseScanFileName);
        %         end
        %         if exist(baseMaskFileName,'file')
        %             delete(baseMaskFileName);
        %         end
        %         success = createMhaScansFromCERR(baseScanNum, baseScanFileName, basePlanC);
        %         success = createMhaMask(baseScanNum, baseMaskFileName, basePlanC, baseMask3M, threshold_bone);
        %
        %         % Create .mha file for moving scan
        %         movScanUID = movPlanC{indexMovS.scan}(movScanNum).scanUID;
        %         randPart = floor(rand*1000);
        %         movScanUniqName = [movScanUID,num2str(randPart)];
        %         movScanFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['movScan_',movScanUniqName,'.mha']);
        %         movMaskFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['movMask_',movScanUniqName,'.mha']);
        %         if exist(movScanFileName,'file')
        %             delete(movScanFileName);
        %         end
        %         if exist(movMaskFileName,'file')
        %             delete(movMaskFileName);
        %         end
        %         success = createMhaScansFromCERR(movScanNum, movScanFileName, movPlanC);
        %         %success = createMhaMask(movScanNum, movMaskFileName, movPlanC, movMask3M, threshold_bone);
        %         success = createMhaMask(movScanNum, movMaskFileName, movPlanC, movMask3M, []);
        %
        % Create a command file path for plastimatch
        cmdFileName_rigid = fullfile(getCERRPath,'ImageRegistration','plastimatch_command',[baseScanUID,'_',movScanUID,'_rigid.txt']);
        cmdFileName_dir   = fullfile(getCERRPath,'ImageRegistration','plastimatch_command',[baseScanUID,'_',movScanUID,'_dir.txt']);
        
        if exist(cmdFileName_rigid,'file')
            delete(cmdFileName_rigid);
        end
        if exist(cmdFileName_dir,'file')
            delete(cmdFileName_dir);
        end
        
        % Create a file name and path for storing bspline coefficients
        bspFileName_rigid = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['bsp_coeffs_',baseScanUID,'_',movScanUID,'_rigid.txt']);
        bspFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['bsp_coeffs_',baseScanUID,'_',movScanUID,'.txt']);
        if exist(bspFileName_rigid,'file')
            delete(bspFileName_rigid)
        end
        if exist(bspFileName,'file')
            delete(bspFileName)
        end
        
        % ----------- Call appropriate command file based on algorithm -------
        
        %         % Rigid step
        %         userCmdFile = fullfile(getCERRPath,'ImageRegistration','plastimatch_command','bspline_register_cmd_rigid.txt');
        %         ursFileC = file2cell(userCmdFile);
        %         cmdFileC{1,1} = '[GLOBAL]';
        %         cmdFileC{end+1,1} = ['fixed=',escapeSlashes(baseScanFileName)];
        %         cmdFileC{end+1,1} = ['moving=',escapeSlashes(movScanFileName)];
        %         cmdFileC{end+1,1} = ['xform_out=',escapeSlashes(bspFileName_rigid)];
        %         cmdFileC{end+1,1} = '';
        %         cmdFileC(end+1:end+size(ursFileC,2),1) = ursFileC(:);
        %         cell2file(cmdFileC,cmdFileName_rigid)
        %
        %         % Run plastimatch Registration
        %         system(['plastimatch register ', cmdFileName_rigid]);
        
        
        % Deformable (DIR) step
        clear cmdFileC
        optS = CERROptions;
        cmd_fileName = optS.plastimatch_command_file;
        userCmdFile = fullfile(getCERRPath,'ImageRegistration','plastimatch_command',cmd_fileName);
        ursFileC = file2cell(userCmdFile);
        cmdFileC{1,1} = '[GLOBAL]';
        cmdFileC{end+1,1} = ['fixed=',escapeSlashes(baseScanFileName)];
        cmdFileC{end+1,1} = ['moving=',escapeSlashes(movScanFileName)];
        if ~isempty(baseMask3M) || ~isempty(threshold_bone)
            cmdFileC{end+1,1} = ['fixed_roi=',escapeSlashes(baseMaskFileName)];
        end
        if ~isempty(movMask3M) || ~isempty(threshold_bone)
            cmdFileC{end+1,1} = ['moving_roi=',escapeSlashes(movMaskFileName)];
        end
        %cmdFileC{end+1,1} = ['xform_in=',escapeSlashes(bspFileName_rigid)];
        cmdFileC{end+1,1} = ['xform_out=',escapeSlashes(bspFileName)];
        cmdFileC{end+1,1} = '';
        if ~isempty(threshold_bone)
            cmdFileC{end+1,1} = ['background_max=',num2str(threshold_bone)];
            cmdFileC{end+1,1} = '';
        end
        cmdFileC(end+1:end+size(ursFileC,2),1) = ursFileC(:);
        cell2file(cmdFileC,cmdFileName_dir)
        
        % Run plastimatch Registration
        system(['plastimatch register ', cmdFileName_dir]);
        
        
        % Read bspline coefficients file
        [bsp_img_origin,bsp_img_spacing,bsp_img_dim,bsp_roi_offset,bsp_roi_dim,bsp_vox_per_rgn,bsp_direction_cosines,bsp_coefficients] = read_bsplice_coeff_file(bspFileName);
        
        % Cleanup
        try
            delete(baseScanFileName);
            delete(movScanFileName);
            delete(cmdFileName);
            delete(bspFileName);
            delete(baseMaskFileName);
            delete(movMaskFileName);
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
        
        % Create new deform object
        deformS = createNewDeformObject(baseScanUID,movScanUID,algorithm,algorithmParamsS);
        
        % Add deform object to both base and moving planC's
        baseDeformIndex = length(basePlanC{indexBaseS.deform}) + 1;
        movDeformIndex  = length(movPlanC{indexMovS.deform}) + 1;
        basePlanC{indexBaseS.deform}  = dissimilarInsert(basePlanC{indexBaseS.deform},deformS,baseDeformIndex);
        movPlanC{indexMovS.deform}  = dissimilarInsert(movPlanC{indexMovS.deform},deformS,movDeformIndex);


    case 'RIGID PLASTIMATCH'
        
        % Create a command file path for plastimatch
        cmdFileName_rigid = fullfile(getCERRPath,'ImageRegistration','plastimatch_command',[baseScanUID,'_',movScanUID,'_rigid.txt']);
        
        if exist(cmdFileName_rigid,'file')
            delete(cmdFileName_rigid);
        end
        
        % Create a file name and path for storing bspline coefficients
        bspFileName_rigid = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['bsp_coeffs_',baseScanUID,'_',movScanUID,'_rigid.txt']);
        bspFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['bsp_coeffs_',baseScanUID,'_',movScanUID,'.txt']);
        if exist(bspFileName_rigid,'file')
            delete(bspFileName_rigid)
        end
        if exist(bspFileName,'file')
            delete(bspFileName)
        end

        % Create a file name and path for storing bspline coefficients
        bspFileName_rigid = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['bsp_coeffs_',baseScanUID,'_',movScanUID,'_rigid.txt']);
        if exist(bspFileName_rigid,'file')
            delete(bspFileName_rigid)
        end
        
        % Rigid step
        userCmdFile = fullfile(getCERRPath,'ImageRegistration','plastimatch_command','bspline_register_cmd_rigid.txt');
        ursFileC = file2cell(userCmdFile);
        cmdFileC{1,1} = '[GLOBAL]';
        cmdFileC{end+1,1} = ['fixed=',escapeSlashes(baseScanFileName)];
        cmdFileC{end+1,1} = ['moving=',escapeSlashes(movScanFileName)];
        cmdFileC{end+1,1} = ['xform_out=',escapeSlashes(bspFileName_rigid)];
        cmdFileC{end+1,1} = '';
        cmdFileC(end+1:end+size(ursFileC,2),1) = ursFileC(:);
        cell2file(cmdFileC,cmdFileName_rigid)
        
        % Run plastimatch Registration
        system(['plastimatch register ', cmdFileName_rigid]);
        
        % Read output file
        fileC = file2cell(bspFileName_rigid);
        indParam = strfind(fileC{4},'Parameters:');
        rigidParamsV = str2num(fileC{4}(indParam+11:end));
        indParam = strfind(fileC{5},'FixedParameters:');
        fixedParamsV = str2num(fileC{5}(indParam+16:end));
        translationM = eye(4);
        translationM(1:3,4) = -rigidParamsV(4:6)/10;
        translationM(3,4) = -translationM(3,4);
        Rx = eye(4);
        Rx([2 3],[2 3]) = [cos(rigidParamsV(1)) sin(rigidParamsV(1)); -sin(rigidParamsV(1)) cos(rigidParamsV(1))];
        Ry = eye(4);
        Ry([1 3],[1 3]) = [cos(rigidParamsV(2)) -sin(rigidParamsV(2)); sin(rigidParamsV(2)) cos(rigidParamsV(2))];
        Rz = eye(4);
        Rz([1 2],[1 2]) = [cos(rigidParamsV(3)) sin(rigidParamsV(3)); -sin(rigidParamsV(3)) cos(rigidParamsV(3))];
        bakTransM = eye(4);
        bakTransM(1:3,4) = fixedParamsV/10;
        bakTransM(3,4) = -bakTransM(3,4);
        fwTransM = eye(4);
        fwTransM(1:3,4) = -fixedParamsV/10;
        fwTransM(3,4) = -fwTransM(3,4);
        transM = bakTransM*Rx*Ry*Rz*fwTransM*translationM;
        movPlanC{indexMovS.scan}(movScanNum).transM = transM;
        
    case 'BSPLINE ITK'
        
        
    case 'DEMONS PLASTIMATCH'
        
        
    case 'DEMONS ITK'
        
end


function [basePlanC, movPlanC] = register_scans(basePlanC, movPlanC, baseScanNum, movScanNum, algorithm, baseMask3M, movMask3M, threshold_bone)
% function [basePlanC, movPlanC] = register_scans(basePlanC, movPlanC, baseScanNum, movScannum, algorithm, baseMask3M, movMask3M, threshold_bone)
%
% APA, 07/12/2012

indexBaseS = basePlanC{end};
indexMovS  = movPlanC{end};

switch upper(algorithm)
    
    case 'BSPLINE PLASTIMATCH'
        
        % Create .mha file for base scan
        baseScanUID = basePlanC{indexBaseS.scan}(baseScanNum).scanUID;
        randPart = floor(rand*1000);
        baseScanUniqName = [baseScanUID,num2str(randPart)];
        baseScanFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['baseScan_',baseScanUniqName,'.mha']);
        baseMaskFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['baseMask_',baseScanUniqName,'.mha']);
        try
            delete(baseScanFileName);
        end
        try
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
        try
            delete(movScanFileName);
        end
        try
            delete(movMaskFileName);
        end        
        success = createMhaScansFromCERR(movScanNum, movScanFileName, movPlanC);
        success = createMhaMask(movScanNum, movMaskFileName, movPlanC, movMask3M, threshold_bone);
        
        % Create a command file path for plastimatch
        cmdFileName_rigid = fullfile(getCERRPath,'ImageRegistration','plastimatch_command',[baseScanUID,'_',movScanUID,'_rigid.txt']);
        cmdFileName_dir   = fullfile(getCERRPath,'ImageRegistration','plastimatch_command',[baseScanUID,'_',movScanUID,'_dir.txt']);        
        try
            delete(cmdFileName_rigid);
            delete(cmdFileName_dir);
        end
        
        % Create a file name and path for storing bspline coefficients
        bspFileName_rigid = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['bsp_coeffs_',baseScanUID,'_',movScanUID,'_rigid.txt']);
        bspFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['bsp_coeffs_',baseScanUID,'_',movScanUID,'.txt']);
        try
            delete(bspFileName_rigid)
            delete(bspFileName)
        end
        
        % ----------- Call appropriate command file based on algorithm -------
        
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
        
        
        % Deformable (DIR) step
        clear cmdFileC
        userCmdFile = fullfile(getCERRPath,'ImageRegistration','plastimatch_command','bspline_register_cmd_dir.txt');
        ursFileC = file2cell(userCmdFile);
        cmdFileC{1,1} = '[GLOBAL]';
        cmdFileC{end+1,1} = ['fixed=',escapeSlashes(baseScanFileName)];
        cmdFileC{end+1,1} = ['moving=',escapeSlashes(movScanFileName)];
        if ~isempty(baseMask3M) || ~isempty(threshold_bone)
            cmdFileC{end+1,1} = ['fixed_mask=',escapeSlashes(baseMaskFileName)];
        end
        if ~isempty(movMask3M) || ~isempty(threshold_bone)
            cmdFileC{end+1,1} = ['moving_mask=',escapeSlashes(movMaskFileName)];
        end
        cmdFileC{end+1,1} = ['xform_in=',escapeSlashes(bspFileName_rigid)];
        cmdFileC{end+1,1} = ['xform_out=',escapeSlashes(bspFileName)];
        cmdFileC{end+1,1} = '';
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
        
        
    case 'BSPLINE ITK'
        
        
    case 'DEMONS PLASTIMATCH'
        
        
    case 'DEMONS ITK'
        
end

% Create new deform object
deformS = createNewDeformObject(baseScanUID,movScanUID,algorithm,algorithmParamsS);

% Add deform object to both base and moving planC's
baseDeformIndex = length(basePlanC{indexBaseS.deform}) + 1;
movDeformIndex  = length(movPlanC{indexMovS.deform}) + 1;
basePlanC{indexBaseS.deform}  = dissimilarInsert(basePlanC{indexBaseS.deform},deformS,baseDeformIndex);
movPlanC{indexMovS.deform}  = dissimilarInsert(movPlanC{indexMovS.deform},deformS,movDeformIndex);

%movPlanC{indexMovS.deform}(movDeformIndex) = deformS;



function basePlanC = register_scans(basePlanC, movPlanC, baseScanNum, movScanNum, algorithm)
% function basePlanC = register_scans(basePlanC, movPlanC, baseScanNum, movScannum, algorithm)
%
% APA, 07/12/2012

indexBaseS = basePlanC{end};
indexMovS  = movPlanC{end};

% Create .mha file for base scan
baseScanUID = basePlanC{indexBaseS.scan}(baseScanNum).scanUID;
randPart = floor(rand*1000);
baseScanUniqName = [baseScanUID,randPart];
baseScanFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['baseScan_',baseScanUniqName,'.mha']);
try
    delete(baseScanFileName)
end
success = createMhaScansFromCERR(baseScanNum, baseScanFileName, basePlanC);

% Create .mha file for moving scan
movScanUID = movPlanC{indexMovS.scan}(movScanNum).scanUID;
randPart = floor(rand*1000);
movScanUniqName = [movScanUID,randPart];
movScanFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['movScan_',movScanUniqName,'.mha']);
try
    delete(movScanFileName)
end
success = createMhaScansFromCERR(movScanNum, movScanFileName, movPlanC);

% Create a command file for plastimatch
cmdFileName = fullfile(getCERRPath,'ImageRegistration','plastimatch_command',[baseScanUniqName,'_',movScanUniqName,'.txt']);
try
    delete(cmdFileName)
end

% Create a file name for storing bspline coefficients
bspFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['bsp_coeffs_',baseScanUniqName,'_',movScanUniqName,'.txt']);
try
    delete(bspFileName)
end

% Call appropriate command file based on algorithm
userCmdFile = fullfile(getCERRPath,'ImageRegistration','plastimatch_command','bspline_register_cmd.txt');
ursFileC = file2cell(userCmdFile);
cmdFileC{1,1} = '[GLOBAL]';
cmdFileC{2,1} = ['fixed=',baseScanFileName];
cmdFileC{3,1} = ['moving=',movScanFileName];
cmdFileC{4,1} = ['xform_out=',bspFileName];
cmdFileC{5,1} = '';
cmdFileC(6:5+size(ursFileC,2),1) = ursFileC(:);
cell2file(cmdFileC,cmdFileName)

% Run plastimatch Registration
system(['plastimatch register ', cmdFileName]);

% Read bspline coefficients file
[bsp_img_origin,bsp_img_spacing,bsp_img_dim,bsp_roi_offset,bsp_roi_dim,bsp_vox_per_rgn,bsp_coefficients] = read_bsplice_coeff_file(bspFileName);

% Create new deform object
deformS = initializeCERR('deform');
deformS.baseScanUID = baseScanUID;
deformS.movScanUID = movScanUID;
deformS.deformUID = createUID('deform');
deformS.bsp_img_origin = bsp_img_origin;
deformS.bsp_img_spacing = bsp_img_spacing;
deformS.bsp_img_dim = bsp_img_dim;
deformS.bsp_roi_offset = bsp_roi_offset;
deformS.bsp_roi_dim = bsp_roi_dim;
deformS.bsp_vox_per_rgn = bsp_vox_per_rgn;
deformS.bsp_coefficients = bsp_coefficients;

% Add deform object to both base and moving planC's
baseDeformIndex = length(basePlanC{indexBaseS.deform}) + 1;
movDeformIndex  = length(movPlanC{indexMovS.deform}) + 1;
basePlanC{indexBaseS.deform}(baseDeformIndex)  = deformS;
movPlanC{indexMovS.deform}(movDeformIndex) = deformS;


function basePlanC = register_scans(basePlanC, movPlanC, baseScanNum, movScanNum, algorithm)
% function basePlanC = register_scans(basePlanC, movPlanC, baseScanNum, movScannum, algorithm)
%
% APA, 07/12/2012

indexBaseS = basePlanC{end};
indexMovS  = movPlanC{end};
% Create .mha file for base scan
scanUID = basePlanC{indexBaseS.scan}(baseScanNum).scanUID;
randPart = floor(rand*1000);
baseScanUniqName = [scanUID,randPart];
baseScanFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['baseScan_',baseScanUniqName,'.mha']);
success = createMhaScansFromCERR(baseScanNum, baseScanFileName, basePlanC);

% Create .mha file for moving scan
scanUID = movPlanC{indexMovS.scan}(movScanNum).scanUID;
randPart = floor(rand*1000);
movScanUniqName = [scanUID,randPart];
movScanFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['movScan_',movScanUniqName,'.mha']);
success = createMhaScansFromCERR(movScanNum, movScanFileName, movPlanC);

% Create a command file for plastimatch
cmdFileName = fullfile(getCERRPath,'ImageRegistration','plastimatch_command',[baseScanUniqName,'_',movScanUniqName,'.txt']);

% Create a file name for storing bspline coefficients
bspFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',[baseScanUniqName,'_',movScanUniqName,'.txt']);

% Call appropriate command file based on algorithm
userCmdFile = fullfile(getCERRPath,'ImageRegistration','plastimatch_command','bspline_register_cmd.txt');
ursFileC = file2cell(userCmdFile);
cmdFileC{1,1} = '[GLOBAL]';
cmdFileC{2,1} = ['fixed=',baseScanFileName];
cmdFileC{3,1} = ['moving=',movScanFileName];
cmdFileC{4,1} = ['xform_out=',bspFileName];
cmdFileC{5,1} = '';
cmdFileC{6:5+size(ursFileC,1),1} = userCmdFile(:,1);
cell2file(cmdFileC,cmdFileName)

% Run plastimatch Registration
system(['plastimatch register ', cmdFileName])

% Read bspline coefficients

% Write bspline coefficients to planC{indexS.deformS}




function planC = warp_scan(deformS,movScanNum,movPlanC,planC)
% function planC = warp_scan(deformS,movScanNum,movPlanC,planC)
%
% APA, 07/19/2012

% Create b-spline coefficients file
baseScanUID = deformS.baseScanUID;
movScanUID  = deformS.movScanUID;
bspFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['bsp_coeffs_',baseScanUID,'_',movScanUID,'.txt']);
success = write_bspline_coeff_file(bspFileName,deformS);

% Convert moving scan to .mha
indexMovS = movPlanC{end};
movScanUID = movPlanC{indexMovS.scan}(movScanNum).scanUID;
randPart = floor(rand*1000);
movScanUniqName = [movScanUID,num2str(randPart)];
movScanFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['movScan_',movScanUniqName,'.mha']);
try
    delete(movScanFileName);
end
success = createMhaScansFromCERR(movScanNum, movScanFileName, movPlanC);


% Generate name for the output .mha file
warpedMhaFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['warped_scan_',baseScanUID,'_',movScanUID,'.mha']);

% Issue plastimatch warp command
system(['plastimatch warp --input ', escapeSlashes(movScanFileName), ' --output-img ', escapeSlashes(warpedMhaFileName), ' --xf ', escapeSlashes(bspFileName)])

% Read the warped output .mha file within CERR
infoS  = mha_read_header(warpedMhaFileName);
data3M = mha_read_volume(infoS);
planC  = mha2cerr(infoS,data3M, planC);

function planC = warp_scan(deformS,movScanNum,movPlanC,planC)
% function planC = warp_scan(deformS,movScanNum,movPlanC,planC)
%
% APA, 07/19/2012

% Create b-spline coefficients file
if isstruct(deformS)
    baseScanUID = deformS.baseScanUID;
    movScanUID  = deformS.movScanUID;
    bspFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['bsp_coeffs_',baseScanUID,'_',movScanUID,'.txt']);
    success     = write_bspline_coeff_file(bspFileName,deformS.algorithmParamsS);
else
    bspFileName = deformS;
    indexS = planC{end};
    %movScanUID = movPlanC{indexMovS.scan}(movScanNum).scanUID;
    baseScanUID = planC{indexS.scan}(movScanNum).scanUID;
end

% Convert moving scan to .mha
indexMovS = movPlanC{end};
movScanUID = movPlanC{indexMovS.scan}(movScanNum).scanUID;
movScanOffset = movPlanC{indexMovS.scan}(movScanNum).scanInfo(1).CTOffset;
movScanName = movPlanC{indexMovS.scan}(movScanNum).scanType;
movScanName = [movScanName,'_deformed'];
randPart = floor(rand*1000);
movScanUniqName = [movScanUID,num2str(randPart)];
movScanFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['movScan_',movScanUniqName,'.mha']);
success = createMhaScansFromCERR(movScanNum, movScanFileName, movPlanC);


% Generate name for the output .mha file
warpedMhaFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['warped_scan_',baseScanUID,'_',movScanUID,'.mha']);

% Switch to plastimatch directory if it exists
prevDir = pwd;
plmCommand = 'plastimatch warp ';
optName = fullfile(getCERRPath,'CERROptions.json');
optS = opts4Exe(optName);
if exist(optS.plastimatch_build_dir,'dir') && isunix
    cd(optS.plastimatch_build_dir)
    plmCommand = ['./',plmCommand];
end

% Issue plastimatch warp command
fail = system([plmCommand, '--input ', movScanFileName, ' --output-img ', warpedMhaFileName, ' --xf ', bspFileName]);
if fail % try escaping slashes
    system([plmCommand, '--input ', escapeSlashes(movScanFileName), ' --output-img ', escapeSlashes(warpedMhaFileName), ' --xf ', escapeSlashes(bspFileName)])
end

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

% Switch back to the previous directory
cd(prevDir)

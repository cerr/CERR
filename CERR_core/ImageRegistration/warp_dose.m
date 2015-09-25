function planC = warp_dose(deformS,doseCreationScanNum,movDoseNum,movPlanC,planC)
% function planC = warp_dose(deformS,doseCreationScanNum,movPlanC,planC)
%
% APA, 07/19/2012

indexMovS = movPlanC{end};
indexS = planC{end};

% Create b-spline coefficients file
baseScanUID = deformS.baseScanUID;
movScanUID  = deformS.movScanUID;
bspFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['bsp_coeffs_',baseScanUID,'_',movScanUID,'.txt']);
success = write_bspline_coeff_file(bspFileName,deformS.algorithmParamsS);

% Convert structure mask to .mha
movDoseUID = movPlanC{indexMovS.dose}(movDoseNum).doseUID;
randPart = floor(rand*1000);
movDoseUniqName = [movDoseUID,num2str(randPart)];
movDoseFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['movDose_',movDoseUniqName,'.mha']);

% Write .mha file for this dose
success = createMhaDosesFromCERR(movDoseNum, movDoseFileName, planC);

% Generate name for the output .mha file
warpedMhaFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['warped_dose_',baseScanUID,'_',movScanUID,'.mha']);

% Issue plastimatch warp command with nearest neighbor interpolation
system(['plastimatch warp --input ', escapeSlashes(movDoseFileName), ' --output-img ', escapeSlashes(warpedMhaFileName), ' --xf ', escapeSlashes(bspFileName)])

% Read the warped output .mha file within CERR
%infoS  = mha_read_header(warpedMhaFileName);
%data3M = mha_read_volume(infoS);
[data3M,infoS] = readmha(warpedMhaFileName);
doseName = movPlanC{indexMovS.dose}(movDoseNum).fractionGroupID;
planC = dose2CERR(flipdim(permute(data3M,[2,1,3]),3),[],['Warped_',doseName],[],[],'UniformCT',[],'no',planC{indexS.scan}(doseCreationScanNum).scanUID,planC);

% Cleanup
try
    delete(movDoseFileName)
    delete(warpedMhaFileName)
    delete(bspFileName)
end



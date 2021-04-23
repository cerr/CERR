function basePlanC = calc_vf_jacobain(deformS,basePlanC,refScanNum)
% function basePlanC = calc_vf_jacobain(deformS,basePlanC,refScanNum)
% 
% APA, 02/17/2021

% Obtain base and moving scan UIDs
baseScanUID = deformS.baseScanUID;
movScanUID  = deformS.movScanUID;

[refScanUniqName, ~] = genScanUniqName(basePlanC,refScanNum);
refScanFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['baseScan_',refScanUniqName,'.mha']);
success = createMhaScansFromCERR(refScanNum, refScanFileName, basePlanC);

% Create b-spline coefficients file
bspFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['bsp_coeffs_',baseScanUID,'_',movScanUID,'.txt']);
% bspFileName = fullfile(tempdir,'tmpFiles',['bsp_coeffs_',baseScanUID,'_',movScanUID,'.txt']);
success     = write_bspline_coeff_file(bspFileName,deformS.algorithmParamsS);

% Obtain Vf from b-splice coefficients
vfFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['vf_',baseScanUID,'_',movScanUID,'.mha']);
%vfFileName = fullfile(tempdir,'tmpFiles',['vf_',baseScanUID,'_',movScanUID,'.mha']);
system(['plastimatch xf-convert --input ',escapeSlashes(bspFileName),...
    ' --output ', escapeSlashes(vfFileName), ' --output-type vf'])
% system(['plastimatch xf-convert --input ',escapeSlashes(bspFileName)
%     ' --output ', escapeSlashes(vfFileName), ' --output-type vf'
%     ' --fixed ', escapeSlashes(refScanFileName)])
%system(['plastimatch convert --xf ',escapeSlashes(bspFileName), ' --output-vf=', escapeSlashes(vfFileName)])
delete(bspFileName)

% Calculate Jacobian
jacobianFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['jacobian_',baseScanUID,'_',movScanUID,'.mha']);
system(['plastimatch jacobian --input ',escapeSlashes(vfFileName),...
        ' --output-img ', escapeSlashes(jacobianFileName)])

%delete(vfFileName)
delete(refScanFileName)


% infoS  = mha_read_header(vfFileName);
% vf = mha_read_volume(infoS);
% [vf,infoS] = readmha(jacobianFileName);
%vf = flipdim(permute(vf,[2,1,3]),3);

%infoS  = mha_read_header(vfFileName);
infoS  = mha_read_header(jacobianFileName);
data3M = mha_read_volume(infoS);
delete(jacobianFileName)
delete(vfFileName)
save_flag = 0;
scanOffset = 0;
movScanName = 'Jacobian';
%data3M = data3M(:,:,:,1).^2 + data3M(:,:,:,2).^2 + data3M(:,:,:,3).^2;
basePlanC = mha2cerr(infoS,data3M,scanOffset,movScanName,basePlanC,save_flag);

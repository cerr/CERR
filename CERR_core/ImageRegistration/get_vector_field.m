function vf_out = get_vector_field(deformS,toPlanC,toScanNum,fromPlanC,fromScanNum)
% function vf = get_vector_field(deformS,toPlanC,toScanNum,fromPlanC,fromScanNum)
% 
% APA, 09/24/2012

% Obtain base and moving scan UIDs
baseScanUID = deformS.baseScanUID;
movScanUID  = deformS.movScanUID;

% Figure out whether an inverse Vector field is required
indexToS = toPlanC{end};
indexFromS = fromPlanC{end};

toScanUID = toPlanC{indexToS.scan}(toScanNum).scanUID;
fromScanUID = fromPlanC{indexFromS.scan}(fromScanNum).scanUID;
if isequal(baseScanUID, fromScanUID)
    calc_inv_vf_flag = 0;
else
    calc_inv_vf_flag = 1;
end

% Create b-spline coefficients file
%bspFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['bsp_coeffs_',baseScanUID,'_',movScanUID,'.txt']);
bspFileName = fullfile(tempdir,'tmpFiles',['bsp_coeffs_',baseScanUID,'_',movScanUID,'.txt']);
success     = write_bspline_coeff_file(bspFileName,deformS.algorithmParamsS);

% Obtain Vf from b-splice coefficients
%vfFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['vf_',baseScanUID,'_',movScanUID,'.mha']);
vfFileName = fullfile(tempdir,'tmpFiles',['vf_',baseScanUID,'_',movScanUID,'.mha']);
system(['plastimatch xf-convert --input ',escapeSlashes(bspFileName), ' --output ', escapeSlashes(vfFileName), ' --output-type vf'])
%system(['plastimatch convert --xf ',escapeSlashes(bspFileName), ' --output-vf=', escapeSlashes(vfFileName)])
delete(bspFileName)

if calc_inv_vf_flag
    % Get dims, origin, spacing for toScan
    [uniformCT, uniformScanInfoS] = getUniformizedCTScan(0,toScanNum,toPlanC);
    uniformCT = permute(uniformCT, [2 1 3]);
    uniformCT = flipdim(uniformCT,3);
    % Change data type to int16 to allow (-)ve values
    uniformCT = int16(uniformCT) - int16(toPlanC{indexToS.scan}(toScanNum).scanInfo(1).CTOffset);    
    % [dx, dy, dz]
    resolution = [uniformScanInfoS.grid2Units, uniformScanInfoS.grid1Units, uniformScanInfoS.sliceThickness] * 10;    
    [xVals, yVals, zVals] = getUniformScanXYZVals(toPlanC{indexToS.scan}(toScanNum));    
    offset = [xVals(1) -yVals(1) -zVals(end)] * 10;
    img_size = size(uniformCT);   
    system(['vf_invert --input ', escapeSlashes(vfFileName), ' --output ', escapeSlashes(vfFileName), ' --dims="',num2str(img_size),'" --origin="',num2str(offset),'" --spacing="',num2str(resolution),'"'])
end

% infoS  = mha_read_header(vfFileName);
% vf = mha_read_volume(infoS);
[vf,infoS] = readmha(vfFileName);
%vf = flipdim(permute(vf,[2,1,3]),3);
delete(vfFileName)

vf_out(:,:,:,1) = flipdim(permute(vf(:,:,:,1),[2,1,3]),3)/10;
vf_out(:,:,:,2) = flipdim(permute(-vf(:,:,:,2),[2,1,3]),3)/10;
vf_out(:,:,:,3) = flipdim(permute(-vf(:,:,:,3),[2,1,3]),3)/10;

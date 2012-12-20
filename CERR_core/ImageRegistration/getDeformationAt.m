function [xDeformV,yDeformV,zDeformV] = getDeformationAt(deformS,toPlanC,toScanNum,fromPlanC,fromScanNum,fromXYZv)
% function [xDeformV,yDeformV,zDeformV] = getDeformationAt(deformS,toPlanC,toScanNum,fromPlanC,fromScanNum,fromXYZv)
%
% APA, 08/20/2012

% Obtain base and moving scan UIDs
baseScanUID = deformS.baseScanUID;
movScanUID  = deformS.movScanUID;

% Figure out whether an inverse Vector field is required
indexToS = toPlanC{end};
indexFromS = fromPlanC{end};

toScanUID = toPlanC{indexToS.scan}(toScanNum).scanUID;
fromScanUID = fromPlanC{indexFromS.scan}(fromScanNum).scanUID;
if baseScanUID == fromScanUID
    calc_inv_vf_flag = 1;
else
    calc_inv_vf_flag = 0;
end

% Create b-spline coefficients file
bspFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['bsp_coeffs_',baseScanUID,'_',movScanUID,'.txt']);
success     = write_bspline_coeff_file(bspFileName,deformS.algorithmParamsS);

% Obtain Vf from b-splice coefficients
vfFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['vf_',baseScanUID,'_',movScanUID,'.mha']);
system(['plastimatch xf-convert --input ',escapeSlashes(bspFileName), ' --output ', escapeSlashes(vfFileName), ' --output-type vf'])
  
% Obtain Inverse Vf if required
if calc_inv_vf_flag
    vf_invert --input=vf_in --output=vf_out
    --dims="x y z" --origin="x y z" --spacing="x y z"
    system(['plastimatch vf_invert --input ', escapeSlashes(vfFileName), ' --output ', escapeSlashes(vfFileName), ' --dims="x y z" --origin="x y z" --spacing="x y z"'])
end

% Interolate fromXYZv points to get Vf based on the "fromScan" grid


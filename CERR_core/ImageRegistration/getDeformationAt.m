function [xDeformV,yDeformV,zDeformV] = getDeformationAt(deformS,toPlanC,toScanNum,fromPlanC,fromScanNum,fromXYZv)
% function [xDeformV,yDeformV,zDeformV] = getDeformationAt(deformS,toPlanC,toScanNum,fromPlanC,fromScanNum,fromXYZv)
%
% APA, 08/20/2012

% % Obtain base and moving scan UIDs
% baseScanUID = deformS.baseScanUID;
% movScanUID  = deformS.movScanUID;
% 
% Figure out whether an inverse Vector field is required
indexToS = toPlanC{end};
indexFromS = fromPlanC{end};
% 
% toScanUID = toPlanC{indexToS.scan}(toScanNum).scanUID;
% fromScanUID = fromPlanC{indexFromS.scan}(fromScanNum).scanUID;
% if baseScanUID == fromScanUID
%     calc_inv_vf_flag = 1;
% else
%     calc_inv_vf_flag = 0;
% end
% 
% % Create b-spline coefficients file
% bspFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['bsp_coeffs_',baseScanUID,'_',toScanUID,'.txt']);
% success     = write_bspline_coeff_file(bspFileName,deformS.algorithmParamsS);
% 
% % Obtain Vf from b-splice coefficients
% vfFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['vf_',baseScanUID,'_',toScanUID,'.mha']);
% system(['plastimatch xf-convert --input ',escapeSlashes(bspFileName), ' --output ', escapeSlashes(vfFileName), ' --output-type vf'])
%   
% % Obtain Inverse Vf if required
% if calc_inv_vf_flag   
%     system(['plastimatch vf_invert --input ', escapeSlashes(vfFileName), ' --output ', escapeSlashes(vfFileName), ' --dims="x y z" --origin="x y z" --spacing="x y z"'])
% end
% 
% % Read .mha file for Vf
% infoS  = mha_read_header(vfFileName);
% data3M = mha_read_volume(infoS);
% xDeform3M = flipdim(permute(data3M(:,:,:,1),[2,1,3]),3);
% yDeform3M = flipdim(permute(data3M(:,:,:,2),[2,1,3]),3);
% zDeform3M = flipdim(permute(data3M(:,:,:,3),[2,1,3]),3);

vf = get_vector_field(deformS,toPlanC,toScanNum,fromPlanC,fromScanNum);

% Get grid coordinates for "fromScan"
[xV, yV, zV] = getScanXYZVals(fromPlanC{indexFromS.scan}(fromScanNum));

% Interolate fromXYZv points to get Vf based on the "fromScan" grid
xDeformV = finterp3(fromXYZv(:,1), fromXYZv(:,2), fromXYZv(:,3), vf(:,:,:,1), [xV(1)-eps*10^10 xV(2)-xV(1) xV(end)+eps*10^10], [yV(end)-eps*10^10 yV(1)-yV(2) yV(1)+eps*10^10], zV, 0);
yDeformV = finterp3(fromXYZv(:,1), fromXYZv(:,2), fromXYZv(:,3), vf(:,:,:,2), [xV(1)-eps*10^10 xV(2)-xV(1) xV(end)+eps*10^10], [yV(end)-eps*10^10 yV(1)-yV(2) yV(1)+eps*10^10], zV, 0);
zDeformV = finterp3(fromXYZv(:,1), fromXYZv(:,2), fromXYZv(:,3), vf(:,:,:,3), [xV(1)-eps*10^10 xV(2)-xV(1) xV(end)+eps*10^10], [yV(end)-eps*10^10 yV(1)-yV(2) yV(1)+eps*10^10], zV, 0);

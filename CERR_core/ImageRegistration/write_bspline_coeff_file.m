function success = write_bspline_coeff_file(bspFileName,bsplineParamsS)
% function success = write_bspline_coeff_file(bspFileName,bsplineParamsS)
% 
% APA, 07/17/2012

bsp_img_origin          = bsplineParamsS.bsp_img_origin;
bsp_img_spacing         = bsplineParamsS.bsp_img_spacing;
bsp_img_dim             = bsplineParamsS.bsp_img_dim;
bsp_roi_offset          = bsplineParamsS.bsp_roi_offset;
bsp_roi_dim             = bsplineParamsS.bsp_roi_dim;
bsp_vox_per_rgn         = bsplineParamsS.bsp_vox_per_rgn;
bsp_direction_cosines   = bsplineParamsS.bsp_direction_cosines;
bsp_coefficients        = bsplineParamsS.bsp_coefficients;

fid = fopen(bspFileName,'wb');

fprintf(fid,'MGH_GPUIT_BSP <experimental>\n');
fprintf(fid,['img_origin = ', sprintf('%0.20g ',bsp_img_origin),'\n']);
fprintf(fid,['img_spacing = ', sprintf('%0.20g ',bsp_img_spacing),'\n']);
fprintf(fid,['img_dim = ', sprintf('%0.20g ',bsp_img_dim),'\n']);
fprintf(fid,['roi_offset = ', sprintf('%0.20g ',bsp_roi_offset),'\n']);
fprintf(fid,['roi_dim = ', sprintf('%0.20g ',bsp_roi_dim),'\n']);
fprintf(fid,['vox_per_rgn = ', sprintf('%0.20g ',bsp_vox_per_rgn),'\n']);
fprintf(fid,['direction_cosines = ', sprintf('%0.20g ',bsp_direction_cosines),'\n']);
fprintf(fid,sprintf('%0.20g\n',bsp_coefficients));

%cell2file(fileC,bspFileName);
fclose(fid);

success = 1;


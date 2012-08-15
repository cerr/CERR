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


fileC{1,1} = 'MGH_GPUIT_BSP <experimental>';
fileC{2,1} = ['img_origin = ', num2str(bsp_img_origin(1)),' ',num2str(bsp_img_origin(2)),' ', num2str(bsp_img_origin(3))];
fileC{3,1} = ['img_spacing = ', num2str(bsp_img_spacing(1)),' ',num2str(bsp_img_spacing(2)),' ',num2str(bsp_img_spacing(3))];
fileC{4,1} = ['img_dim = ', num2str(bsp_img_dim(1)),' ',num2str(bsp_img_dim(2)),' ',num2str(bsp_img_dim(3))];
fileC{5,1} = ['roi_offset = ', num2str(bsp_roi_offset(1)),' ',num2str(bsp_roi_offset(2)),' ',num2str(bsp_roi_offset(3))];
fileC{6,1} = ['roi_dim = ', num2str(bsp_roi_dim(1)),' ',num2str(bsp_roi_dim(2)),' ',num2str(bsp_roi_dim(3))];
fileC{7,1} = ['vox_per_rgn = ', num2str(bsp_vox_per_rgn(1)),' ',num2str(bsp_vox_per_rgn(2)),' ',num2str(bsp_vox_per_rgn(3))];
fileC{8,1} = ['direction_cosines = ', num2str(bsp_direction_cosines(1)),' ',num2str(bsp_direction_cosines(2)),' ',num2str(bsp_direction_cosines(3)),' ',num2str(bsp_direction_cosines(4)),' ',num2str(bsp_direction_cosines(5)),' ',num2str(bsp_direction_cosines(6)),' ',num2str(bsp_direction_cosines(7)),' ',num2str(bsp_direction_cosines(8)),' ',num2str(bsp_direction_cosines(9))];
for i = 1:length(bsp_coefficients)
    fileC{end+1,1} = num2str(bsp_coefficients(i));
end

cell2file(fileC,bspFileName);

success = 1;


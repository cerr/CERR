function [bsp_img_origin,bsp_img_spacing,bsp_img_dim,bsp_roi_offset,bsp_roi_dim,bsp_vox_per_rgn,bsp_direction_cosines,bsp_coefficients] = read_bsplice_coeff_file(bspFileName)
% function [bsp_img_origin,bsp_img_spacing,bsp_img_dim,bsp_roi_offset,bsp_roi_dim,bsp_vox_per_rgn,bsp_coefficients] = read_bsplice_coeff_file(bspFileName)
%
% APA, 07/13/2012

bspCoeffC = file2cell(bspFileName);

% Image origin
bsp_img_origin = bspCoeffC{2};
[~,remStr] = strtok(bsp_img_origin,'=');
bsp_img_origin = str2num(remStr(2:end));

% Image spacing
bsp_img_spacing = bspCoeffC{3};
[~,remStr] = strtok(bsp_img_spacing,'=');
bsp_img_spacing = str2num(remStr(2:end));

% Image dimensions
bsp_img_dim = bspCoeffC{4};
[~,remStr] = strtok(bsp_img_dim,'=');
bsp_img_dim = str2num(remStr(2:end));

% ROI offset
bsp_roi_offset = bspCoeffC{5};
[~,remStr] = strtok(bsp_roi_offset,'=');
bsp_roi_offset = str2num(remStr(2:end));

% ROI dimensions
bsp_roi_dim = bspCoeffC{6};
[~,remStr] = strtok(bsp_roi_dim,'=');
bsp_roi_dim = str2num(remStr(2:end));

% ROI dimensions
bsp_vox_per_rgn = bspCoeffC{7};
[~,remStr] = strtok(bsp_vox_per_rgn,'=');
bsp_vox_per_rgn = str2num(remStr(2:end));

% Direction cosines
bsp_direction_cosines = bspCoeffC{8};
[~,remStr] = strtok(bsp_direction_cosines,'=');
bsp_direction_cosines = str2num(remStr(2:end));

bsp_coefficients = cellfun(@str2num,bspCoeffC(9:end));

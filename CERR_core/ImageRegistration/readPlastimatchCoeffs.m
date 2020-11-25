function algorithmParamsS = readPlastimatchCoeffs(xformFileNameBase)

srch = dir([xformFileNameBase '.*']);
xformFileName = fullfile(srch.folder,srch.name);

[~,~,e] = fileparts(xformFileName);

if strcmp(e, '.txt')
    
    % Read bspline coefficients file
    [bsp_img_origin,bsp_img_spacing,bsp_img_dim,bsp_roi_offset,...
        bsp_roi_dim,bsp_vox_per_rgn,bsp_direction_cosines,bsp_coefficients]...
        = read_bsplice_coeff_file(xformFileName);
    
    % Create a structure for storing algorithm parameters
    algorithmParamsS.bsp_img_origin         = bsp_img_origin;
    algorithmParamsS.bsp_img_spacing        = bsp_img_spacing;
    algorithmParamsS.bsp_img_dim            = bsp_img_dim;
    algorithmParamsS.bsp_roi_offset         = bsp_roi_offset;
    algorithmParamsS.bsp_roi_dim            = bsp_roi_dim;
    algorithmParamsS.bsp_vox_per_rgn        = bsp_vox_per_rgn;
    algorithmParamsS.bsp_coefficients       = bsp_coefficients;
    algorithmParamsS.bsp_direction_cosines  = bsp_direction_cosines;
    
else
    algorithmParamsS.vf_filename = xformFileName;   
end
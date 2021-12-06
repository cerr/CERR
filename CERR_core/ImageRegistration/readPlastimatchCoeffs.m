function algorithmParamsS = readPlastimatchCoeffs(xformFileNameBase,algorithm)

srch = dir([xformFileNameBase '.*']);
xformFileName = fullfile(srch.folder,srch.name);

[~,~,e] = fileparts(xformFileName);

if strcmp(e, '.txt')
    
    switch(lower(algorithm))
        
        case 'affine'
            %Ref:https://itk.org/pipermail/insight-users/2014-January/049706.html
            
            affineOutC = file2cell(xformFileName);
            affTransC = affineOutC{4};
            fixedParC = affineOutC{5};
            
            affTransC = strtok(affTransC,'Parameters:');
            fixedParC = strtok(fixedParC,'FixedParameters:');
            
            affTransV = str2num(affTransC(2:end));
            rotationM = reshape(affTransV([1:3, 5:7, 9:11]),3,3).';
            translationV = affTransV([4, 8, 12]);
            
            affineM = [[rotationM;0,0,0],[translationV,1].'];
            fixedV = str2num(fixedParC(2:end));
            
            algorithmParamsS.affineTransM = affineM;
            algorithmParamsS.centerOfRotation = fixedV;
            
        otherwise
            %case {'bspline plastimatch','bspline'}
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
            
    end
    
else
    algorithmParamsS.vf_filename = xformFileName;   
end
function success = write_plm_transform_file(algorithm,plmXformFileName,paramS)
%function success = write_plm_transform_file(algorithm,plmXformFileName,paramS)
%--------------------------------------------------------------------------
% INPUTS
% algorithm         : Plastimatch alogirthm. Supported options: 'affine',
%                     'bspline plastimatch'/'bspline
% plmXformFileName  : Output file for writing Plastimatch transform parameters
% paramS            : Parameter dictionary containing affine transform
%                     (affineTransM) and center (centerOfRotation).
%--------------------------------------------------------------------------
% AI 12/2/21

switch(lower(algorithm))
    
    case 'affine'
        
        affineM = paramS.affineTransM;
        affineV = affineM(1:3,:).';
        affineV = affineV(:);
        fixedV = paramS.centerOfRotation;
        
        fid = fopen(plmXformFileName,'wb');
        fprintf(fid,'#Insight Transform File V1.0\n');
        fprintf(fid,'#Transform 0\n');
        fprintf(fid,'Transform: AffineTransform_double_3_3\n');
        fmt = ['Parameters: ',repmat('%0.20g ',1,numel(affineV)-1),'%g]\n'];
        fprintf(fid,fmt,affineV);
        fmt = ['FixedParameters: ',repmat('%0.20g ',1,numel(fixedV)-1),'%g]\n'];
        fprintf(fid,fmt,fixedV);
        fclose(fid);
        success = 1;
        
    case  {'bspline plastimatch','bspline'}
        success = write_bspline_coeff_file(plmXformFileName,paramS) ;
        
    otherwise
        error(['write_plm_transform_file.m: Plastimatch algorithm %s not',... 
            ' supported'],algorithm);
        
end

end
function affineOutM = getAffineMatrixforTransform(affineInM,operation,varargin)
% Composition of input operation with specified parameters and input 
% transform 'affineInM'.
%-------------------------------------------------------------------------
% INPUTS
%
% affineInM  : 4x4 Input transform matrix
% operation  : Affine transformation('translation','scaling',or 'rotation').
% --- Optional---
% varagin{1} : offsetV - [x,y,z] offsets for translation.
%              scaleV  - [x,y,z] factors for scaling.
%              dirCosV - Directional cosines representing axis for rotation.
% varagin{2} : theta   - Angle (degrees) for rotation.
%-------------------------------------------------------------------------
% Refs:  (1) https://en.wikipedia.org/wiki/Affine_transformation#Image_transformation
%        (2) https://en.wikipedia.org/wiki/Transformation_matrix#Examples_in_3D_computer_graphics
%        (3) https://en.wikipedia.org/w/index.php?title=Transformation_matrix&section=14#Composing_and_inverting_transformations
%-------------------------------------------------------------------------
%AI 06/21/21


transformM = eye(4,4);

switch(lower(operation))
    
    case 'translation'
        
        offsetV = varargin{1};      % offsetV = [Vx, Vy, Vz]
        transformM(1:3,4) = offsetV;
        
    case 'scaling'
        
        scaleV = varargin{1};       % scaleV = [Cx, Cy, Cz]
        transformM(1,1) = scaleV(1);
        transformM(2,2) = scaleV(2);
        transformM(3,3) = scaleV(3);
        
    case 'rotation'
        
        dirCosinesV = varargin{1};
        theta = varargin{1};

        l = dirCosinesV(1);
        m = dirCosinesV(2);
        n = dirCosinesV(3);
        
        C = cosd(theta);
        S = sind(theta);
        
        transformM(1:3,1:3) = [ l^2*(1-C) + C     m*l*(1-C) - n*S   n*l*(1-C) + m*S,...
                       l*m*(1-C) + n*S    m^2*(1-C) + C    n*m*(1-C) - l*S,...
                       l*n*(1-C) - m*S   m*n*(1-C) + l*S   n^2*(1-C) + C ];
        
    otherwise
        
        error(['Invalid operation %s. Supported inputs inlcude ',...
            '''translation'', ''scaling'', ''rotation''.'],operation)
                   
                   
end

affineOutM = transformM * affineInM;


end
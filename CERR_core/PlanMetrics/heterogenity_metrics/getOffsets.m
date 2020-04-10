function offsetsM = getOffsets(dirctn)
% function offsetsM = getOffsets(dirctn)
%
%This function returns offsets for the passed directionality
%
% dirctn = 1 for 3D, or 2 for 2D offsets.
%
% APA, 04/04/2016


% All 13 directional offsets
offsetsM = [1 0 0;
    0 1 0;
    1 1 0;
    1 -1 0;     
    0 0 1;      
    1 0 1;
    1 1 1;
    1 -1 1;    
    0 1 1;
    0 -1 1;    
    -1 -1 1;
    -1 0 1;
    -1 1 1];


switch dirctn
    
    case 1
        
        return;
        
    case 2
        
        offsetsM(5:end,:) = [];
        
        return;
        
    otherwise
        error('The input direction is not implemented yet.')
end


         



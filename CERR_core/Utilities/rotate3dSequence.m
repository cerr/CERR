function  volOut3M = rotate3dSequence(vol3M,index,sign)
%Function to rotate 2D or 3D arrays by 90 degrees around a specified axis
%-------------------------------------------------------------------------- 
% vol3M : Input array
% index : Produces index*90 degree rotation of A, index = 1,2,...
% sign  : +1 or -1 Applied to index (signed index = +-1,+-2,...)
%--------------------------------------------------------------------------
% AI 11/10/22

switch(index)
    case 0 %no flip 
        volOut3M = vol3M;
    case 1 %flip X 90 degrees
        volOut3M = rot3d90(vol3M, 2, sign*1);
    case 2 %flip X 180 degrees
        volOut3M = rot3d90(vol3M, 2, sign*2);
    case 3 %flip X 270 degrees
        volOut3M = rot3d90(vol3M, 2, sign*3);
    case 4 %flip YZ
        if sign>0
            volOut3M = rot3d90(vol3M, 1, sign*1);
            volOut3M = rot3d90(volOut3M, 3, sign*1);
        else
            volOut3M = rot3d90(vol3M, 3, sign*1);
            volOut3M = rot3d90(volOut3M, 1, sign*1);
        end
    case 5 %flip YZ
        if sign>0
            volOut3M = rot3d90(vol3M, 1, sign*1);
            volOut3M = rot3d90(volOut3M, 3, sign*3);
        else
            volOut3M = rot3d90(vol3M, 3, sign*3);
            volOut3M = rot3d90(volOut3M, 1, sign*1);
        end
    case 6 %flip Y 90 degrees
        volOut3M = rot3d90(vol3M, 1, sign*1);
    case 7 %flip Y 180 degrees
        volOut3M = rot3d90(vol3M, 1, sign*2);
    case 8 %flip Y 270 degrees
        volOut3M = rot3d90(vol3M, 1, sign*3);
    case 9 %flip XZ
        if sign>0
            volOut3M = rot3d90(vol3M, 2, sign*1);
            volOut3M = rot3d90(volOut3M, 3, sign*3);
        else
            volOut3M = rot3d90(vol3M, 3, sign*3);
            volOut3M = rot3d90(volOut3M, 2, sign*1);
        end
    case 10 %flip XZ
        if sign>0
            volOut3M = rot3d90(vol3M, 2, sign*1);
            volOut3M = rot3d90(volOut3M, 3, sign*2);
        else
            volOut3M = rot3d90(vol3M, 3, sign*2);
            volOut3M = rot3d90(volOut3M, 2, sign*1);
        end
    case 11 %flip XZ
        if sign>0
            volOut3M = rot3d90(vol3M, 2, sign*1);
            volOut3M = rot3d90(volOut3M, 3, sign*1);
        else
            volOut3M = rot3d90(vol3M, 3, sign*1);
            volOut3M = rot3d90(volOut3M, 2, sign*1);
        end
    case 12 %flip XY
        if sign>0
            volOut3M = rot3d90(vol3M, 2, sign*1);
            volOut3M = rot3d90(volOut3M, 1, sign*2);
        else
            volOut3M = rot3d90(vol3M, 1, sign*2);
            volOut3M = rot3d90(volOut3M, 2, sign*1);
        end
    case 13 %flip XY
        if sign>0
            volOut3M = rot3d90(vol3M, 2, sign*2);
            volOut3M = rot3d90(volOut3M, 1, sign*2);
        else
            volOut3M = rot3d90(vol3M, 1, sign*2);
            volOut3M = rot3d90(volOut3M, 2, sign*2);
        end
    case 14 %flip XY
        if sign>0
            volOut3M = rot3d90(vol3M, 2, sign*3);
            volOut3M = rot3d90(volOut3M, 1, sign*2);
        else
            volOut3M = rot3d90(vol3M, 1, sign*2);
            volOut3M = rot3d90(volOut3M, 2, sign*3);
        end
    case 15 %flip YZ
        if sign>0
            volOut3M = rot3d90(vol3M, 1, sign*3);
            volOut3M = rot3d90(volOut3M, 3, sign*1);
        else
            volOut3M = rot3d90(vol3M, 3, sign*1);
            volOut3M = rot3d90(volOut3M, 1, sign*3);
        end
    case 16 %flip YZ
        if sign>0
            volOut3M = rot3d90(vol3M, 1, sign*3);
            volOut3M = rot3d90(volOut3M, 3, sign*2);
        else
            volOut3M = rot3d90(vol3M, 3, sign*2);
            volOut3M = rot3d90(volOut3M, 1, sign*3);
        end
    case 17 %flip YZ
        if sign>0
            volOut3M = rot3d90(vol3M, 1, sign*3);
            volOut3M = rot3d90(volOut3M, 3, sign*3);
        else
            volOut3M = rot3d90(vol3M, 3, sign*3);
            volOut3M = rot3d90(volOut3M, 1, sign*3);
        end
    case 18 %flip XZ
        if sign>0
            volOut3M = rot3d90(vol3M, 2, sign*2);
            volOut3M = rot3d90(volOut3M, 3, sign*1);
        else
            volOut3M = rot3d90(vol3M, 3, sign*1);
            volOut3M = rot3d90(volOut3M, 2, sign*2);
        end
    case 19 %flip XZ
        if sign>0
            volOut3M = rot3d90(vol3M, 2, sign*3);
            volOut3M = rot3d90(volOut3M, 3, sign*1);
        else
            volOut3M = rot3d90(vol3M, 3, sign*1);
            volOut3M = rot3d90(volOut3M, 2, sign*3);
        end
    case 20 %flip Z
        volOut3M = rot3d90(vol3M, 3, sign*1);
    case 21 %flip XZ
        if sign>0
            volOut3M = rot3d90(vol3M, 2, sign*2);
            volOut3M = rot3d90(volOut3M, 3, sign*3);
        else
            volOut3M = rot3d90(vol3M, 3, sign*3);
            volOut3M = rot3d90(volOut3M, 2, sign*2);
        end
    case 22 %flip XZ
        if sign>0
            volOut3M = rot3d90(vol3M, 2, sign*3);
            volOut3M = rot3d90(volOut3M, 3, sign*3);
        else
            volOut3M = rot3d90(vol3M, 3, sign*3);
            volOut3M = rot3d90(volOut3M, 2, sign*3);
        end
    case 23 %flip Z
        volOut3M = rot3d90(vol3M, 3, sign*3);


end
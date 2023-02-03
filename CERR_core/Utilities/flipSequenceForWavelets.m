function volOut3M = flipSequenceForWavelets(vol3M,index,sign)
%Function to flip 2D or 3D arrays by 180 degrees around a specified axis
%--------------------------------------------------------------------------
% vol3M : Input array
% index : index = 0,1,2...7
% sign  : +1 or -1 (-1 to reverse order of flips).
%--------------------------------------------------------------------------
% AI 02/03/23

switch(index)

    case 0 %No flip
        volOut3M = vol3M;
    case 1 %Flip rows
        volOut3M = flip(vol3M,2);
    case 2 %Flip cols
        volOut3M = flip(vol3M,1);
    case 3 %Flip rows, cols
        if sign>0
            volOut3M = flip(flip(vol3M,2),1);
        else
            volOut3M = flip(flip(vol3M,1),2);
        end
    case 4 %Flip slices
        volOut3M = flip(vol3M,3);
    case 5
        if sign>0
            volOut3M = flip(flip(vol3M,2),3);
        else
            volOut3M = flip(flip(vol3M,3),2);
        end
    case 6
        if sign>0
            volOut3M = flip(flip(vol3M,1),3);
        else
            volOut3M = flip(flip(vol3M,3),1);
        end
    case 7
        if sign>0
            volOut3M = flip(flip(flip(vol3M,2),1),3);
        else
            volOut3M = flip(flip(flip(vol3M,3),1),2);
        end
end


end
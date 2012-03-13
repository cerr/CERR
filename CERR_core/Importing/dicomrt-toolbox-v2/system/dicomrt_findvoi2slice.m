function [locate_voi]=dicomrt_findvoi2slice(VOI,voi2use,vectref,slice,axis,PatientPosition)
% dicomrt_findvoi2slice(VOI,voi2use,vectref,slice,axis,PatientPosition)
%
% Find the number of the VOI contour corresponding to the input slice
% number "slice"
%
% See also dicomrt_findslice
% 
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

[VOI_temp]=dicomrt_checkinput(VOI);
VOI=dicomrt_varfilter(VOI_temp);

% Check axis
if ischar(axis) ~=1
    error('dicomrt_findvoi2slice: Axis is not a character. Exit now!')
elseif axis=='x' | axis=='X'
    dir=1;
elseif axis=='y' | axis=='Y'
    dir=2;
elseif axis=='z' | axis=='Z'
    dir=3;
else
    error('dicomrt_findvoi2slice: Axis can only be X Y or Z. Exit now!')
end

voitype=dicomrt_checkvoitype(VOI_temp);

% Find VOI corresponding to slice 
if isequal(voitype,'2D') & dir==3
    for j=1:length(voi2use)
        voiZ=dicomrt_getvoiz(VOI_temp,voi2use(j));
        temp=dicomrt_findsliceVECT(vectref,slice,voiZ,PatientPosition);
        if isempty(temp)==1
            locate_voi(j)=nan;
        else
            locate_voi(j)=temp;
        end
        clear voiZ
    end
elseif isequal(voitype,'2D') & dir~=3
    locate_voi=nan;
elseif isequal(voitype,'3D') & dir==3
    for j=1:length(voi2use)
        voiZ=dicomrt_getvoiz(VOI_temp,voi2use(j));
        temp=dicomrt_findsliceVECT(vectref,slice,voiZ,PatientPosition);
        if isempty(temp)==1
            locate_voi(j)=nan;
        else
            locate_voi(j)=temp;
        end
        clear voiZ
    end
elseif isequal(voitype,'3D') & dir==1
    for j=1:length(voi2use)
        [voiX,index]=dicomrt_getvoix(VOI_temp,voi2use(j));
        temp=dicomrt_findsliceVECT(vectref,slice,voiX,PatientPosition);
        if isempty(temp)==1
            locate_voi(j)=nan;
        else
            locate_voi(j)=index(temp);
        end
        clear voiX
    end
elseif isequal(voitype,'3D') & dir==2
    for j=1:length(voi2use)
        [voiY,index]=dicomrt_getvoiy(VOI_temp,voi2use(j));
        temp=dicomrt_findsliceVECT(vectref,slice,voiY,PatientPosition);
        if isempty(temp)==1
            locate_voi(j)=nan;
        else
            locate_voi(j)=index(temp);
        end
        clear voiY
    end
end
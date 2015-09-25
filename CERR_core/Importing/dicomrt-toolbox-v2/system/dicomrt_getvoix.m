function [voiX,index] = dicomrt_getvoix(VOI,voi2use)
% dicomrt_getvoix(VOI,voi2use)
%
% Get X location for selected voi contour
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check number of argument and set-up some parameters and variables
error(nargchk(2,3,nargin))

[VOI_temp]=dicomrt_checkinput(VOI);
VOI=dicomrt_varfilter(VOI_temp);

voitype=dicomrt_checkvoitype(VOI_temp);

if isequal(voitype,'3D')==1
    for i=1:size(VOI{voi2use,2}{1},1)
        voiX(i)=VOI{voi2use,2}{1}{i}{1};
    end
else
    error('VOI must be 3D. Use dicomrt_build3dVOI.')
end

[voiX,index]=sort(voiX);

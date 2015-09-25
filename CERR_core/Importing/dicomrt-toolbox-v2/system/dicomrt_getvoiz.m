function [voiZ,index] = dicomrt_getvoiz(VOI,voi2use)
% dicomrt_getvoiz(VOI,voi2use)
%
% Get Z location selected voi
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check number of argument and set-up some parameters and variables
error(nargchk(2,3,nargin))

[VOI_temp]=dicomrt_checkinput(VOI);
VOI=dicomrt_varfilter(VOI_temp);

voitype=dicomrt_checkvoitype(VOI_temp);

if isequal(voitype,'2D')==1
    ncont=size(VOI{voi2use,2},1);
    if ncont~=0 && ~(ncont==1 && isempty(VOI{voi2use,2}{1}))
        for i=1:ncont
            if ~isempty(VOI{voi2use,2}{i})
                voiZ(i)=VOI{voi2use,2}{i}(1,3);
            end
        end
    else
        voiZ=0;
    end
else
    for i=1:size(VOI{voi2use,2}{3},1)
        voiZ(i)=VOI{voi2use,2}{3}{i}(1,3);
    end
end

[voiZ,index]=sort(voiZ);

function dicomrt_explore(study,xmesh,ymesh,zmesh,VOI,voi2plot)
% dicomrt_explore(study,xmesh,ymesh,zmesh,VOI,voi2plot)
%
% Interactive exploring tool for 3D matrices.
%
% study is the study to explore
% xmesh, ymesh and zmesh are the voxel coordinates of the 3D matrix
% VOI is an OPTIONAL cell array which contain the patients VOIs as read by dicomrt_loadVOI
% voi2plot is an OPTIONAL vector pointing to the number of VOIs to be displayed
%
% NOTE: This function uses a version of "Sliceomatic" specifically modified by 
% Emiliano Spezi to render 3D matrices in real world space (e.g. Patient Coordinate System).
% Sliceomatic was originally written by Eric Ludlam (The Mathworks) and can
% be downloaded from the Matlab exchange file repository.
%
% See also: dicomrt_loaddose, dicomrt_loadmcdose, dicomrt_loadvoi
% 
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check number of argument and set-up some parameters and variables
error(nargchk(1,6,nargin))

% Check case and set-up some parameters and variables
[matrix,type,label,PatientPosition]=dicomrt_checkinput(study);
matrix2display=dicomrt_varfilter(matrix);

if nargin == 6
    [VOI_temp]=dicomrt_checkinput(VOI);
    VOI=dicomrt_varfilter(VOI_temp);
    sliceomatic(matrix2display,1,xmesh,ymesh,zmesh);
    dicomrt_rendervoi(VOI_temp,voi2plot,1,1,1);
elseif nargin == 4
    sliceomatic(matrix2display,1,xmesh,ymesh,zmesh);
elseif nargin ==1
    sliceomatic(matrix2display);
else
    error('dicomrt_explore: incorrect number of input parameters. Exit now!');
end

set(gcf,'NumberTitle','off','name',['dicomrt_explore: ',inputname(1)]);


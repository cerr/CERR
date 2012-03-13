function [locate_point]=dicomrt_findpointVECT(vect,point,PatientPosition)
% dicomrt_findpointVECT(vect,point,PatientPosition)
%
% Locate a point in a vector
%
% vect is a vector
% point is the coordinate that needs to be located in vect
% 
% Example:
%
% [num]=dicomrt_findsliceVECT(dose_xmesh,3);
%
% where dose_xmesh=[0 1.5 2.5 3.5 4.5]
%
% returns in num "3" which correspond to the 3rd element vector dose_xmesh. 
%
% See also dicomrt_findslice
% 
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check number of argument and set-up some parameters and variables
error(nargchk(2,3,nargin))

if nargin==2
    PatientPosition=1;
end

if PatientPosition==1
    locate_point=dicomrt_findpointVECT_hfs(vect,point);
elseif PatientPosition==2
    locate_point=dicomrt_findpointVECT_hfs(vect,point);
elseif PatientPosition==3
    vect=flipdim(vect,1);
    locate_voi_max_1=length(vect)-dicomrt_findpointVECT_hfs(vect,point);
elseif PatientPosition==4
    vect=flipdim(vect,1);
    locate_voi_max_1=length(vect)-dicomrt_findpointVECT_hfs(vect,point);
end
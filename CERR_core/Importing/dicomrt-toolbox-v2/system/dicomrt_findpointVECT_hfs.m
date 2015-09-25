function [slice_number]=dicomrt_findpointVECT_hfs(vect,point)
% dicomrt_findpointVECT_hfs(vect,point);
%
% Locate a point in a vector for Head First Supine patient orientation
%
% vect is the vector
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

locate_slice=histc(point,vect);
slice_number=find(locate_slice);

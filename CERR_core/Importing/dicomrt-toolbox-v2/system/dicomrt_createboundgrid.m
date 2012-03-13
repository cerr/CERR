function [bound]=dicomrt_createboundgrid(mesh)
% dicomrt_createboundgrid(mesh);
%
% Create a boundary grid for the input mesh variable.
% 
% mesh is a vector containing the coordinates of the centers of the pixels
%
% As mesh prodived this toolbox represents the center of transmitted image pixels
% (DICOM specification), this function is useful for calculating the boundaries
% of the pixels.
% 
% Example:
%
% If A=[1 2 3 4], dicomrt_createboundgrid(A,1) returns: 0.5 1.5 2.5 3.5 4.5
%
% See also: dicomrt_loadct, dicomrt_loaddose, dicomrt_ctcreate, dicomrt_getPatientPosition
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

thick=abs(mesh(1)-mesh(2));

if issorted(mesh)~=0 % Ascending order (PatientPosition 1 & 2)
    bound=mesh-thick/2;
    bound(end+1)=bound(end)+thick;
else
    bound=mesh+thick/2; % Descending order (PatientPosition 3 & 4)
    bound(end+1)=bound(end)-thick;
end
    
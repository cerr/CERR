function [voitype]=dicomrt_checkvoitype(VOI)
% dicomrt_checkvoi(VOI)
%
% Check if the VOI has its own original format (set of 2D contours defined in the Z axis) 
% or if it has been modified to contain outlines defined also in the X and Y planes.
% 
% See also: dicomrt_checkinput, dicomrt_loadvoi
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

VOI_pointer=VOI{1,1};
VOI_array=VOI{2,1};

nvois=size(VOI_array,1);

for i=1:nvois
    n3d(i)=isempty(strfind(VOI_array{i,1},'3D'));
end

if find(n3d)
    voitype='2D';
else
    voitype='3D';
end


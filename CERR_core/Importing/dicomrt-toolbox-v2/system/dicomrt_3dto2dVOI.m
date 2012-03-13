function [VOI2d] = dicomrt_3dto2dVOI(VOI3d)
% dicomrt_3dto2dVOI(VOI3d)
%
% Convert 3d VOI to 2d VOIformat for backward compatibility.
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

VOI2d=VOI3d;

% downgrading 
for i=1:size(VOI3d,1)
    temp=VOI2d{i,2}{3};
    VOI2d{i,2}(1)=[];
    VOI2d{i,2}(1)=[];
    VOI2d{i,2}(1)=[];
    VOI2d{i,2}=temp;
end
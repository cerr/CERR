function [st] = dicomrt_getslicethickness(study)
% dicomrt_getslicethickness(study)
%
% Retrieve the slice thickness from a diagnostic dataset
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check input
[study,type_study,dummy,PatientPosition_study]=dicomrt_checkinput(study);

for k=1:size(study{2,1},3) % loop through the number of scans
    try
        st(k)=study{1}{k}.SliceThickness.*0.1;
    catch
        st=[];
    end
end
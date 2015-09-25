function dicomrt_setaxistick(mesh,lo,hi,dir,h)
% dicomrt_setaxistick(mesh,lo,hi,dir);
%
% Modify properties of current axes as function of PatientPosition.
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

if dir=='x'
    whichaxis='XData';
elseif dir=='y'
    whichaxis='YData';
elseif dir=='z'
    whichaxis='ZData';
else
    error('dicomrt_setaxislimits: wrong dir. Exit now!');
end

if issorted(mesh)~=0 % Ascending order (PatientPosition 1 & 2)
    set(h,whichaxis,mesh(lo:hi));
    %set(gca,whichaxis,mesh(lo:hi));
else
    if size(mesh,1)<size(mesh,2) % Descending order (PatientPosition 3 & 4)
        %set(gca,whichaxis,flipdim(mesh(lo:hi),2));
        set(h,whichaxis,flipdim(mesh(lo:hi),1));
    else
        %set(gca,whichaxis,flipdim(mesh(lo:hi),1));
        set(h,whichaxis,flipdim(mesh(lo:hi),1));
    end
end
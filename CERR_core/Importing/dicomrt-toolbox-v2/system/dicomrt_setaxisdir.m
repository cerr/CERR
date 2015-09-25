function dicomrt_setaxisdir(PatientPosition)
% dicomrt_setaxisdir(PatientPosition)
%
% Modify properties of current axes as function of PatientPosition.
% 
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

if PatientPosition==3
    set(gca,'YDir','normal');
elseif PatientPosition==4
    set(gca,'XDir','reverse');set(gca,'YDir','normal');
end

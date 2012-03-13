function [contourcolor,doseareas,transl]=dicomrt_setisolevels(norm,dose)
% dicomrt_setisolevels(norm,dose)
%
% Set solor for iso contour levels display.
% 
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Set standard levels
contourcolor = char('b','c','g','r','m');
doseareas=[0,50,80,95,105,inf];

% Set isolevels display
if norm==-1
    contourcolor = char('b','b','c','c','g','r','r','m','m');
    doseareas=[-inf,-10,-5,-3,0,3,5,10,inf];
elseif norm==0
    targetdose=dose{1,1}{1}.DoseReferenceSequence.Item_1.TargetPrescriptionDose;
    doseareas=doseareas./100*targetdose;    
end

% Set transparency levels
transl=[0.1,0.3,0.4,0.5,0.9];
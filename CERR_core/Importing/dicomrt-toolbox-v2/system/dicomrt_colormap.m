function CLim = dicomrt_colormap(BeginSlot,EndSlot,CDmin,CDmax,CmLength)
% dicomrt_colormap(BeginSlot,EndSlot,CDmin,CDmax,CmLength)
%
% This function calculates values for CLim that cause parts of the image
% to use a section of the colormap containing the appropriate colors.
%
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

%                Convert slot number and range
%                to percent of colormap
PBeginSlot    = (BeginSlot - 1) / (CmLength - 1);
PEndSlot      = (EndSlot - 1) / (CmLength - 1);
PCmRange      = PEndSlot - PBeginSlot;
%                Determine range and min and max 
%                of new CLim values
DataRange     = CDmax - CDmin;
ClimRange     = DataRange / PCmRange;
NewCmin       = CDmin - (PBeginSlot * ClimRange);
NewCmax       = CDmax + (1 - PEndSlot) * ClimRange;
CLim          = [NewCmin,NewCmax];

function [dvh] = dicomrt_quickdvhplot(VOI,cell_case_study,dose_xmesh,dose_ymesh,dose_zmesh,type)
% dicomrt_quickdvhplot(VOI,cell_case_study,dose_xmesh,dose_ymesh,dose_zmesh,type)
%
% Select VOI for DOSE-VOLUME-HISTOGRAM calculation and plot. Light Version
%
% NOTE: as opposed to dicomrt_dvhcal_single *mesh* arguments are vectors and not
% matrices. This allow to run this functions also in "low" memory pcs.
%
% VOIs is a cell array and contains all the Volumes of Interest
% cell_case_study is a simple cell array with the following structure:
%
%  ------------------------
%  | [ rtplan structure ] |
%  | ----------------------
%  | [ 3D dose matrix   ] |
%  ------------------------
%
% xmesh and ymesh are needed to precisely mask dose distribution 
% using VOIs contours
% zmesh is used to match the z position of the VOI's contour with
% the appropriate dose plane
%
% Options are:
%
% type    = 1   cumulative histogram
% type    ~ 1   frequency plot (default)
%
% This function calls dicomrt_dvhcal_single, plots the selected VOI
% and exits. It's light and quick. DVH calculation are done on-the-fly
% with the same algorithm used for dicomrt_dvhcal_all.
%
% To produce plot with multiple DVHs and labels use: 
% dicomrt_dvhcal_all followed by dicomrt_dvhplot
%
% See also dicomrt_loaddose, dicomrt_dvhcal, dicomrt_dvhplot
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% 'Choose between VOIs' Message
disp('Available VOIs are: ')
disp(VOI)
voiselect=input('Choose VOI for DVH calculation (0/Return - End program): ');

if voiselect > size(VOI,1)
   warning('dicomrt_quickdvhplot: This is not a valid option!');
elseif isempty(voiselect) | isequal(voiselect,0)
   return;
else
   dicomrt_dvhcal_single_lv(VOI,voiselect,cell_case_study,dose_xmesh,dose_ymesh,dose_zmesh,type);
end
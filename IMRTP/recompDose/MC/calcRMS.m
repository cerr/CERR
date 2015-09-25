function [rms roughness] = calcRMS(nhist, nbatch, beamIndex, threshold, dx, dy)
%JC Oct 04, 2005
%Calculate RMS for nbatch of simulations.
%Only account the 
%dx=dy=0.19532cm
%dx=dy=0.1875cm
%nhist = 1000000
%nbatch = 8
%threshold=0.9;
%
% Copyright 2010, Joseph O. Deasy, on behalf of the CERR development team.
% 
% This file is part of The Computational Environment for Radiotherapy Research (CERR).
% 
% CERR development has been led by:  Aditya Apte, Divya Khullar, James Alaly, and Joseph O. Deasy.
% 
% CERR has been financially supported by the US National Institutes of Health under multiple grants.
% 
% CERR is distributed under the terms of the Lesser GNU Public License. 
% 
%     This version of CERR is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
% CERR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
% without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with CERR.  If not, see <http://www.gnu.org/licenses/>.

maxDose=[]; 
maxError=[];
meanDose=[];
roughness=[];

% Get the mean dose for nbatch, for all voxels.
for i=1:nbatch,
    filename = ['dose3D_', num2str(beamIndex), '_',num2str(nhist), '_', num2str(i)];
    load(filename, 'dose3D');
    if (i==1)
        meanDose = dose3D;
    else
        meanDose = meanDose + dose3D;
    end
    clear dose3D;
end

meanDose = meanDose/nbatch;
indmax = find(meanDose >= threshold*max(meanDose(:)));

%Calculate rmsDose
rmsDose = [];
for i=1:nbatch
    filename = ['dose3D_', num2str(beamIndex), '_',num2str(nhist), '_', num2str(i)];
    load(filename, 'dose3D');
if (i==1)
        rmsDose = (dose3D-meanDose).* (dose3D-meanDose);
    else
        rmsDose = rmsDose + (dose3D-meanDose) .* (dose3D-meanDose);
    end
end

rmsDose = sqrt(rmsDose/nbatch);

disp('The number of voxels involved in the calculation is:')
disp(length(indmax));

%rms = mean(rmsDose(indmax))/max(meanDose(:));
%Should use the mean / the mean;
rms = mean(rmsDose(indmax))/mean(meanDose(indmax))
% Calculate roughness of the meanDose
[c, r, s] = size(meanDose);
roughness=[];
L=zeros(c,r,s);% i=1, x=[], y=[], z=[],

%meanDose = meanDose/max(meanDose(:));
% JC Jun 20 2006, Should devide by mean
meanDose = meanDose/mean(meanDose(indmax));

for slice=1:s,
    L(:,:,slice) = del2(meanDose(:,:,slice), dx, dy)*4;
end

roughness = sqrt(median(L(indmax))*median(L(indmax)))
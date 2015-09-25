function [rms] = calcRMSnew(nhist, batchStart, batchEnd, doseBenchMark)
%JC Oct 04, 2005
%DW Aug 01, 2006
%Calculate RMS for nbatch of simulations.
%JC Oct 17, 2007
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

threshold=0.5;

maxDose=[]; 
maxError=[];
noiselessDose=[];
roughness=[];

% Get the noiseless dose for all voxels.
 noiselessDose = doseBenchMark;

indmax = find(noiselessDose >= threshold*max(noiselessDose(:)));

%Calculate rmsDose
rmsDose = [];

for i = batchStart:batchEnd
    filename = ['dose3D_total_', num2str(nhist), '_batch', num2str(i)];
    load(filename, 'dose3D');
if (i==batchStart)
        rmsDose = (dose3D-noiselessDose).* (dose3D-noiselessDose);
    else
        rmsDose = rmsDose + (dose3D-noiselessDose) .* (dose3D-noiselessDose);
    end
end

rmsDose = sqrt(rmsDose/(batchEnd-batchStart+1));

disp('The number of voxels involved in the calculation is:')
disp(length(indmax));

% Should the mean of noiseless dose or the max noiseless dose be used?
% Previously, use mean.
% Now, use max.
% rms = mean(rmsDose(indmax))/mean(noiselessDose(indmax))
 rms = mean(rmsDose(indmax))/max(noiselessDose(indmax))


% Calculate roughness of the noiselessDose
%[c, r, s] = size(noiselessDose);
%roughness=[];
%L=zeros(c,r,s);% i=1, x=[], y=[], z=[],

%noiselessDose = noiselessDose/max(noiselessDose(:));
% JC Jun 20 2006, Should devide by mean
%noiselessDose = noiselessDose/mean(noiselessDose(indmax));

%for slice=1:s,
%    L(:,:,slice) = del2(noiselessDose(:,:,slice), dx, dy)*4;
%end

%roughness = sqrt(median(L(indmax))*median(L(indmax)))
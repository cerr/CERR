function colorM = visualRefColormap(maxDose,refDose,numRows,baseStr,topStr)
%Returns the 'visualReference' colormap based on a 'base' colormap baseStr and
%a 'top' colormap topStr.  The base colormap is stretched from 0 to refDose.  Between
%refDose and maxDose (if there are such doses), the colormap follows the colormap
%defined by topStr.  See CERRColormap to see valid colormap strings.
%
%JOD, 16 Jan 03.
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


%We want to rescale the colormap to an arbitrary number of bins.
%Given the 'visual reference dose', and the fact that we always want a colormap
%with a length of n, then the number of bins up to the visual reference dose are:
%zero dose should map to an index of one.
%D_vr should map to the highest index in the colormap, cM.
%Let m be the number of rows in cM.

%Get base and top unrescaled colormaps
baseM = CERRColorMap(baseStr);
topM  = CERRColorMap(topStr);

doseV = linspace(0,maxDose,numRows);

s = size(baseM,1);
t = size(topM,1);

indexBase = (doseV/refDose) * (s - 1);   %Scale dose from 0 to (s-1)

highIndex = [(doseV/refDose) > 1];

%truncate
indexBase(highIndex) = [];

%now interpolate into the colormap:
baseRescaledM = zeros(length(indexBase),3);
baseRescaledM(:,1) = interp1([0:s-1],baseM(:,1),indexBase)';
baseRescaledM(:,2) = interp1([0:s-1],baseM(:,2),indexBase)';
baseRescaledM(:,3) = interp1([0:s-1],baseM(:,3),indexBase)';

colorM = baseRescaledM;

if any(highIndex)

  topRows = numRows - length(indexBase);
  topRescaledM = zeros(topRows,3);
  indexTop = ((doseV - refDose)/(max(doseV(:)) - refDose)) * (t - 1);  %Scale doses to (t-1)
  indexTop(~highIndex) = [];

  %and the corresponding colormap is
  topRescaledM(:,1) = interp1([0:t-1],topM(:,1),indexTop)';
  topRescaledM(:,2) = interp1([0:t-1],topM(:,2),indexTop)';
  topRescaledM(:,3) = interp1([0:t-1],topM(:,3),indexTop)';

  colorM = [baseRescaledM; topRescaledM];

end

%fini





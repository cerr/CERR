function addDVHtoFig(hFig, struct, doseNum, hLine, xVals, yVals, type, abs, doseBins, volsV, doseName)
%Save a DVH to the figure.
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

ud = get(hFig, 'userdata');
plot.struct = struct;
plot.doseNum = doseNum;
plot.doseName = doseName;
plot.hLine = hLine;
[plot.xVals, aInd] = unique(xVals);
% plot.xVals = xVals;
plot.yVals = yVals(aInd);
plot.doseBins = doseBins;
plot.volsV = volsV;
plot.type = type;
plot.abs = abs;
if isfield(ud, 'plots')
    ud.plots(end+1) = plot;
else
    ud.plots = plot;
end
set(hFig, 'userdata', ud);
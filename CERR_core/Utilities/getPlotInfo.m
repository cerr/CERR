function plotParam = getPlotInfo();
%"getPlotInfo"
%   Returns a parameter to be appended to contour if this version of Matlab is
%   7.0.  The parameter is specified in the optS file.  If this is not
%   Matlab 7, plotParam is null and no parameter should be appened to contour.
%
%JRA 10 Sep 04
%
%Usage:
%   plotParam = getPlotInfo;
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

global stateS;

if isfield(stateS, 'MLVersion')
    versionNum = stateS.MLVersion;
else
    verInfo = ver('MATLAB');    
    versionNum = str2num(verInfo.Version(1));
    stateS.MLVersion = versionNum;    
end

plotParam = [];
if versionNum >= 7
    tmpOptS = CERROptions;
	if isfield(tmpOptS, 'plotObjFormat') && ~isempty(tmpOptS.plotObjFormat)
        plotParam = tmpOptS.plotObjFormat;
	end
end
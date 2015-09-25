%Here is an example script which produces the (very useful) cross listing file:
%
%JOD, Jan 06.
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


global callsM calledByM fileNameC

[version, junk] = CERRCurrentVersion;
pathStr = getCERRPath;
pathStr = pathStr(1:end-1); %strip trailing back-slash
str = datestr(now,'dd-mmyyyy');
getDirFunInfo(fullfile(pathStr, 'CrossListing',['CERR Cross listing, v', version, ' ', str, '.txt']), 'y', ['CERR Cross listing, v' version ' ' date], pathStr)

function matVer = getMLVersion
%"MLVersion"
%   Returns the numeric version of Matlab currently running.  Uses the first
%   3 digits of the Version field returned from ver('matlab').
%
%JRA 11/15/04
%
%Usage:
%   version = MLVersion
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



verOutput = ver('MATLAB');
if isempty(verOutput)
    verOutput(1).Version = '';
end
verString = verOutput.Version;
matVer = str2num(verString);

% dotInd = strfind(verString, '.');
% startInd = [1 dotInd+1];
% endInd = [dotInd - 1 length(verString)];
% for i = 1:length(startInd)
%     versionCell{i} = str2num(verString(startInd(i):endInd(i)));
% end
% 
% if length(versionCell) == 2
%     matVer = str2num([num2str(versionCell{1}),num2str(versionCell{2})]);
% elseif length(versionCell) == 3
%     matVer = str2num([num2str(versionCell{1}),num2str(versionCell{2}),'.',num2str(versionCell{3})]);
% end


% verOutput = ver('MATLAB');
% verString = verOutput.Version;
% 
% matVer = str2num(verString);

% dotInd = strfind(verString, '.');
% startInd = [1 dotInd+1];
% endInd = [dotInd - 1 length(verString)];
% 
% for i = 1:length(startInd)
%     versionCell{i} = str2num(verString(startInd(i):endInd(i)));
% end
% 
% if length(versionCell) > 1
%     version = versionCell{1} + versionCell{2}*1/(10^length(versionCell{2}));
% else
%     version = versionCell{1};
% end

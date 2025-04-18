function str = getCERRfiles(directory)
%function str = getCERRfiles(directory)
%This function returns all the CERR files in the passed directory
%
%APA 3/28/2008
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

allDirS = dir(directory);
str = '';
for dirNum = 1:length(allDirS)
    if ~allDirS(dirNum).isdir && (length(allDirS(dirNum).name)>3 && ...
            strcmpi(allDirS(dirNum).name(end-3:end),'.mat')) || ...
            (length(allDirS(dirNum).name)>7 && ...
            strcmpi(allDirS(dirNum).name(end-7:end-4),'.mat') && ...
            (strcmpi(allDirS(dirNum).name(end-3:end),'.bz2') || ...
            strcmpi(allDirS(dirNum).name(end-3:end),'.zip')))
        str{end+1} = fullfile(directory,allDirS(dirNum).name);
    elseif ~strcmp(allDirS(dirNum).name,'.') && ~strcmp(allDirS(dirNum).name,'..')
        str = [str getCERRfiles(fullfile(directory,allDirS(dirNum).name))];
    end
end
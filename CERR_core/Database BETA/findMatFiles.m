function matFileIndex = findMatFiles(rootDir)
%"findMatFiles"
%   Build the index of current mat files in rootDir and all subfolders.
%   Index is in the form of a struct with fieldnames fileName, filePath 
%   and fileModDate.
%
%JRA 11/28/03
%
% Usage: matFileIndex = findMatFiles(rootDir)
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


matFileIndex    = [];
fileName        = [];
filePath        = [];
fileModDate     = [];

matFiles = traverseDirectoryStructure(rootDir, 'pre', 'listMatFiles');
listOutput = [matFiles.data];

for i=1:length(listOutput)
    if ~isempty(listOutput{i});
        fileName       = [fileName {listOutput{i}.name}];
        filePath       = [filePath repmat({matFiles(i).dir}, size({listOutput{i}.name}))];
        fileModDate    = [fileModDate {listOutput{i}.date}];
    end
end
if isempty(fileName) | isempty(filePath) | isempty(fileModDate)
    matFileIndex = struct('name', {}, 'path', {}, 'lastMod', {});    
else
    matFileIndex = struct('name', fileName, 'path', filePath, 'lastMod', fileModDate);    
end
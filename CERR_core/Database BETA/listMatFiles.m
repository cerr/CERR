function matFiles = listMatFiles(varargin)
%"listMatFiles"
%   Return the .mat files in the currrent directory, or if a path is passed
%   in, the .mat files in the passed directory.  This data is returned in a
%   structure with fields .name .path and .modDate
%
%   JRA 11/7/03
%
% Usage: output = listMatFiles(varargin)
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


if nargin == 0
    directory = pwd;
else
    directory = varargin{1};
end

dirContents = dir(fullfile(directory, '*.mat'));
bz2Files = dir(fullfile(directory, '*.mat.bz2'));

if ~isempty(dirContents) & ~isempty(bz2Files)
    dirContents(end+1:end+length(bz2Files)) = bz2Files;
elseif ~isempty(dirContents) & isempty(bz2Files)
    dirContents = dirContents;
elseif isempty(dirContents) & ~isempty(bz2Files)    
    dirContents = bz2Files
else 
    dirContents = [];
end

if ~isempty(dirContents)
    matFiles = rmfield(dirContents, 'bytes');
else
    matFiles = struct('name', {}, 'date', {}, 'isdir', {});
end

% if ~isempty(dirContents)
%     matName = {dirContents.name};
%     matDate = {dirContents.date};
%     matFiles.name = matName;
%     matFiles.path = repmat({directory}, [1 length(matName)]);
%     matFiles.modDate = matDate;
% else
%     matFiles = [];
% end
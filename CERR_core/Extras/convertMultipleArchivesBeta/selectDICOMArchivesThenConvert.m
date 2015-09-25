function output = selectDICOMArchivesThenConvert(baseDir, dirRoot, storeHere, optionsFile)
%  Desgined to mass import a directory full of DICOM plans
%  Currently broken by memory handling issues
% 
%  function output = selectDICOMArchivesThenConvert(baseDir, dirRoot, storeHere, optionsFile)
%
%  Author:  Andrew Hope (AJH)
% 
%  Prompt dynamically grab the directories for source and target
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


if ~exist('baseDir')
    baseDir = [uigetdir('', 'Where are your data files generally?') filesep];
    if ischar(baseDir)==0
        error('No base directory selected, or directory does not exist.');
    end
end

if ~exist('dirRoot')
    
    dirRoot = uigetdir(baseDir, 'Source sub-directories are in what directory?');
    if ischar(dirRoot)==0 
        error('No source directory selected or directory does not exist.');
    end
    dirRoot = [dirRoot filesep];
end

if ~exist('storeHere')
    storeHere = [uigetdir(baseDir,'Directory to store result files?') filesep];
    if ischar(dirRoot)==0
        error('No source directory selected or directory does not exist.');
    end
end
% Figure out which option file you want to use.

cd(baseDir);
if ~exist('optionsFile')
    
    optionsFile = uigetfile('*.m','Select CERR Option file?');
end
% Make the list of directories to convert to CERR files.  All directories in
% the source file directory are assumed to be data directories.

files = dir(dirRoot);

n = 1;

for i=1 : length(files)
    
    % Please note the ugly assumption below that there will be no 2 character
    % directory names to avoid "." and ".." from being included.
    
    if files(i).isdir == 1
        
        % The below is an fugly kludge to exclude . or .. directories 
        % from the convert process and hopefully prevent crunchyboom.
        if ~( strcmp(files(i).name,'.') | strcmp(files(i).name,'..'))
            dirListC{n} = files(i).name;
            n = n+1;
        end       
    end
end

convertDICOMArchives(dirRoot, dirListC, storeHere, optionsFile);



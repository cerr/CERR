% Testfile to mass import a directory full of plans
% Currently, it assumes that all sub-directories of the selected directory
% should be converted.  If there is no aapm0000 file, it seems to break
% horribly, which is intended, I suppose.
%
% Author:  Andrew Hope
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


%  Prompt dynamically grab the directories for source and target
%  Known issues:  Currently doesn't force bzip2 because default CERR option
%  file does not have .zipfile = 'yes'.  May just force it manually.

baseDir = [uigetdir('', 'Where are your data files generally?') filesep];

if ischar(baseDir)==0
    error('No base directory selected, or directory does not exist.');
end

dirRoot = uigetdir(baseDir, 'Source sub-directories are in what directory?');
if ischar(dirRoot)==0 
    error('No source directory selected or directory does not exist.');
end

dirRoot = [dirRoot filesep];

storeHere = [uigetdir(baseDir,'Directory to store result files?') filesep];
if ischar(dirRoot)==0
    error('No source directory selected or directory does not exist.');
end

% Figure out which option file you want to use.

cd(baseDir);

optionsFile = uigetfile('*.m','Select CERR Option file?');

% Make the list of directories to convert to CERR files.  All directories in
% the source file directory are assumed to be data directories.

files = dir(dirRoot);

n = 1;

for i=1 : length(files)

    % Please note the ugly assumption below that there will be no 2 character
    % directory names to avoid "." and ".." from being included.
    
    if files(i).isdir == 1 & length(files(i).name)>2
       
        % The below is an fugly kludge to make sure there is an aapm0000 to
        % import in the sub-directory, otherwise, it's going to be excluded
        % from the convert process and hopefully prevent crunchyboom.
        
        fullfile(dirRoot, files(i).name,'aapm0000');
        test = fopen(fullfile(dirRoot, files(i).name,'aapm0000'));
        if test ~= -1
            dirListC{n} = files(i).name;
            n = n+1;
        end       
    end
end

convertArchives(dirRoot, dirListC, storeHere, optionsFile);



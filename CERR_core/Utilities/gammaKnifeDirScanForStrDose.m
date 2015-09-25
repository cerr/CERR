% Script to get names of all Gamma Knife plan that do not have dose and
% structures
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

dirName = uigetdir(pwd,'Select Directory for Gamma Knife Plan scanning');

if dirName == 0
    disp('Gamma Knife Directory scanning aborted')
    return
end

allDir = dir(dirName);

allDir(1:2) = [];

[FileName,PathName] = uiputfile({'*.txt';'*.*'},'Save Gamma Knife Log' ,'GK_Log.txt');

if FileName == 0
    disp('Gamma Knife Directory scanning aborted')
    return
end

fid = fopen(fullfile(PathName,FileName),'w');

for i = 1:length(allDir)

    if allDir(i).isdir
        planDir = allDir(i).name;

        subDirs = dir(fullfile(dirName,planDir));

        subDirs(1:2) = [];

        for j = 1:length(subDirs)

            if subDirs(j).isdir

                dirToCheck = fullfile(dirName,planDir,subDirs(j).name);
                try
                    doseFilename = getLeksellFilesNames(fullfile(dirToCheck, 'SRdata'), 'DoseGroup');
                    skullFilename = getLeksellFilesNames(fullfile(dirToCheck, 'SRdata'), 'Skull');
                    superFilename = getLeksellFilesNames(fullfile(dirToCheck, 'SRdata'), 'Super');
                    targetframeFilename = getLeksellFilesNames(fullfile(dirToCheck, 'SRdata'), 'TargetFrame');
                    noDose = 0;
                catch
                    noDose = 1;
                end

                try
                    noShot = 0;
                    shotFilename = getLeksellFilesNames(fullfile(dirToCheck, 'Shots'), 'Shot');
                catch
                    noShot = 1;
                end

                try
                    noStr = 0;
                    volFilename  = getLeksellFilesNames(fullfile(dirToCheck, 'Volumes'), 'Volume');
                catch
                    noStr = 1;
                end

                try
                    noStudy = 0;
                    studyFilename = getLeksellFilesNames(fullfile(dirToCheck, 'Studys'), 'Study');
                catch
                    noStudy = 1;
                end

                if noDose | noStr | noShot
                    fprintf(fid,'ReImport Gamma Knife Plan \t %s.\r\n', fullfile(planDir,subDirs(j).name));
                end
            end
        end
    end
end

fclose(fid);

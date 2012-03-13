function convertArchives(dirRoot, dirListC, storeHere, optionsFile)
%Convert and store series of RTOG directories.
%
%JOD, 6 Feb 03.
%AJH, 23 Jan 04.
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

storeDir = 'C:\download\data\3dlung\CERROutput\';

output = fopen([storeDir 'importerrors.txt'], 'a');

% Header block


for i = 1 : length(dirListC)
    
    dirSt = dirListC{i};
    
    archiveDir = [dirRoot, dirSt, '\'];
    
    saveFile = [storeHere, dirSt, '.mat'];
    
    try
        planC = CERRImport(optionsFile, archiveDir, saveFile);
    catch
        fprintf(['Error importing ' dirListC{i} char(10) lasterr char(10)]);
        fprintf(output, ['Error importing ' dirListC{i} char(10) lasterr char(10)]);
    end
    
end

fclose(output);



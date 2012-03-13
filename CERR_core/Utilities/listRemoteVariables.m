function [remoteFiles, planC] = listRemoteVariables(planC, saveFlag)
%"listRemoteVariables"
%   Returns a structure array of variables in planC that are stored 
%   remotely, for the purpose of wrapping these files in the archive
%   when it is saved, as well as updating the remote files.
%
%   If saveFlag is set to 1 the contents of the data field for each 
%   remotely stored variable is written to that variable's file.  
%   The variable is then marked as unloaded and returned as part of
%   the modified planC.  By default this is off.
%
%JRA 10/21/04
%
%Usage:
%   [remoteFiles, planC] = listRemoteVariables(planC, saveFlag)
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

if ~exist('saveFlag')
    saveFlag = 0;
end

indexS = planC{end};
cellNames = fields(indexS);
for i=1:length(cellNames)
    cellVals(i) = getfield(indexS, cellNames{i});
end

%Call isWanted on each cell in planC.  Manually generate the index alias.
remoteFiles = [];
for i=1:length(cellVals)
    [planC{cellVals(i)}, remoteFiles] = isWanted(planC{cellVals(i)}, remoteFiles, saveFlag);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [structure, remoteFiles] = isWanted(structure, remoteFiles, saveFlag)
%Recursive function to find and save remote variables.  A field is remote if 
%it fails the isLocal function test.  If a field is a simple numeric, it
%cannot contain a remote variable and isWanted returns.

%If remote file, add it to list and return;
if ~isLocal(structure)
    if saveFlag
        if structure.isLoaded    
            structure = saveRemoteVariable(structure);
        end
    end
    remoteFiles = [remoteFiles structure];    
    return;
end

%Delve deeper into either cell arrays or struct arrays.
dataType = class(structure); 
switch dataType
    case 'cell'
        for i=1:length(structure(:))
            [structure{i}, remoteFiles] = isWanted(structure{i}, remoteFiles, saveFlag);
        end
    
    case 'struct'      
        for i=1:length(structure(:))
            fieldNames = fields(structure);
            for j=1:length(fieldNames)                           
                [fVal, remoteFiles] = isWanted(getfield(structure, {i}, fieldNames{j}), remoteFiles, saveFlag);                
                structure = setfield(structure, {i}, fieldNames{j}, fVal);
            end
        end      
        if length(structure(:)) == 0 | length(fields(structure)) == 0
            return;
        end       
end
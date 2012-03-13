function [remoteDoses, planC] = listRemoteDoseArrays(planC, saveFlag)
%"listRemoteDoseArrays"
%   Returns a structure array of dose array variables that are stored 
%   remotely, for the purpose of wrapping the remote files in the archive
%   when it is saved, as well as updating the remote files.
%
%   If saveFlag is set to 1 the contents of the data field for each 
%   remotely stored variable is written to that variable's file.  
%   The variable is then marked as unloaded and returned as part of
%   the modified planC.  By default this is off.
%
%   If no planC is passed, listRemoteDoseArrays operates on the global
%   planC.
%
%JRA 04/26/05
%
%Usage:
%   [remoteDoses, planC] = listRemoteDoseArrays(planC, saveFlag)
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

if ~exist('planC')
    global planC
end
indexS = planC{end};

remoteDoses = [];
nDoses = length(planC{indexS.dose});

%Iterate over doses, checking for remote dose arrays.
for doseNum=1:nDoses
    
    %Get the dose array for future checking.
    structure = planC{indexS.dose}(doseNum).doseArray;        
    
    if ~isLocal(structure)
                
        %Found a remote array, add it to our list.
        remoteDoses = [remoteDoses structure];  
        
        %If the saveFlag is specified, write the data field to the file.
        if saveFlag
            if structure.isLoaded    
                structure = saveRemoteVariable(structure);
            end
        end
    end
end 
return;
function planC = setDoseArray(doseIndex, doseArray, planC)
%"setDoseArray"
%   Sets the doseArray stored in a planC in slot doseIndex to the passed 
%   doseArray.  This is the same as saying:
%
%   planC{indexS.dose}(doseIndex).doseArray = doseArray;
%
%   except that if the dose is compressed or remote, setDoseArray maintains
%   the compress-ness and remote-ness of the data.
%
%   If doseIndex is not valid, or if no valid planC can be found an error is
%   returned.
%
%   JRA 4/25/05
%
%Usage:
%   planC = setDoseArray(doseIndex, doseArray, planC)
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

isRemote = 0;

%An index was passed, extract the doseStruct.
if ~exist('planC')
    global planC
end

if ~iscell(planC)
    error('Cannot set dose. PlanC is not a valid cell array.');
end
indexS = planC{end};

if doseIndex > length(planC{indexS.dose}) | doseIndex < 1
    error('Cannot set dose.  Requested doseIndex does not exist.')
end

oldDoseArray = planC{indexS.dose}(doseIndex).doseArray;   
fileName = [];
if ~isLocal(oldDoseArray)
    fileName = ['doseArray_',planC{indexS.dose}(doseIndex).doseUID,'.mat'];
    planC{indexS.dose}(doseIndex).doseArray.filename = fileName;
end

planC{indexS.dose}(doseIndex).doseArray = replaceData(oldDoseArray, doseArray, fileName);


function data = replaceData(oldData, newData, fileName)
%"replaceData"
%   Recursive function to replace data.

if ~isCompressed(oldData) & isLocal(oldData);
    data = newData;
    return;
elseif isCompressed(oldData)
    childData = decompress(oldData);
    data = compress(replaceData(childData, newData));
    return;
elseif ~isLocal(oldData)
    childData = getRemoteVariable(oldData);
    [bool, storageType, remotePath] = isLocal(oldData);
    data = setRemoteVariable(replaceData(childData, newData), storageType, remotePath, fileName);
    return;    
end
function planC = validatePlan(planD)
% validatePlan
% Validates the planC after its loaded. This is a necessary step to check
% for old plan files for UID's and also to check for inconsistencies with
% planC. If the plan loaded is for microRT please set "chkMicroRT" field in
% CERROption.m file before using CERR. Default for this field is "0"(Not
% Set)
%
% Usage
%   planC = validatePlan(planC);
%
%   See also UPDATEPLANIVH, GUESSPLANUID
%
% Created DK 09-01-2006
%
%check to see if the plan pass is for microRT project
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

planC = initializeCERR;
indexS = planD{end};
fields = fieldnames(indexS);
indexSNew = planC{end};

for i = 1:length(fields)
    field = fields{i};
    if ~strcmpi(field,'indexS')
        try
            planC{indexSNew.(field)} = planD{indexS.(field)};
        catch
            warning(['Unknown field "' field '"in CERR plan. Rejecting this field']);
            continue
        end
    end
end
planC{end}=indexSNew;
clear planD

% Check for field scanUID in scan field
if ~isfield(planC{indexS.scan},'scanUID')| ~isfield(planC{indexS.structureArray},'structureSetUID')|~isfield(planC{indexS.dose},'doseUID')
    hwarn = warndlg('This is an old CERR archive. Creating UID linkage ....');
    waitfor(hwarn);
    planC = guessPlanUID(planC);
end
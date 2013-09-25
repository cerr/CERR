function [planC, isUIDCreated] = updatePlanFields(planC)
%function [planC, isUIDCreated] = updatePlanFields(planC)
%
%This function updates planC elements according to initializeCERR and initializeScanInfo.
%
%APA, 06/19/2007
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

indexS      = planC{end};
dummyPlanC  = initializeCERR;
dummyIndexS = dummyPlanC{end};
oldFieldNames = fieldnames(indexS);
fieldNamesC = fieldnames(dummyIndexS);

% Get number of elements in planC cellArray.
numFields = length(oldFieldNames) - 1;
indexS = rmfield(indexS,'indexS');

% Get flag for UID fields
isUIDCreated = 1;
if ~isfield(planC{indexS.scan},'scanUID') || ~isfield(planC{indexS.structureArray},'structureSetUID') || ~isfield(planC{indexS.dose},'doseUID') || (isfield(indexS,'GSPS') && ~isfield(planC{indexS.GSPS}, 'annotUID'))
    isUIDCreated = 0;
end

% Update planC elements according to initializeCERR.m
for i = 1:length(fieldNamesC)
    if isfield(indexS,fieldNamesC{i}) && isstruct(planC{indexS.(fieldNamesC{i})}) && length(planC{indexS.(fieldNamesC{i})}) > 0
        currentFieldsC = fieldnames(dummyPlanC{dummyIndexS.(fieldNamesC{i})});
        for j = 1:length(currentFieldsC)
            if ~isfield(planC{indexS.(fieldNamesC{i})},currentFieldsC{j})
                for k = 1:length(planC{indexS.(fieldNamesC{i})})
                    planC{indexS.(fieldNamesC{i})}(k).(currentFieldsC{j}) = '';
                end
            end
        end
    else  %initialize using initializeCERR.m
        if ~isfield(indexS,fieldNamesC{i})
            numFields = numFields + 1;
            indexS.(fieldNamesC{i}) = numFields;
            planC{numFields} = initializeCERR(fieldNamesC{i});
        else
            planC{indexS.(fieldNamesC{i})} = initializeCERR(fieldNamesC{i});
        end
    end
end
planC{end} = indexS;

% Update scanInfo fields according to initializeScanInfo.m
dummyScanInfo   = initializeScanInfo;
fieldNamesC     = fieldnames(dummyScanInfo);
for i=1:length(fieldNamesC)
    if ~isfield(planC{indexS.scan}(1).scanInfo(1),fieldNamesC{i})
        for scanNum = 1:length(planC{indexS.scan})
            for scanInfoNum = 1:length(planC{indexS.scan}(scanNum).scanInfo)
                planC{indexS.scan}(scanNum).scanInfo(scanInfoNum).(fieldNamesC{i}) = '';
            end
        end
    end
end

% Create UID Linkages based on isUIDCreated flag.
if ~isUIDCreated
    warning('This is an old CERR archive. Creating UID linkage ....')
    planC = guessPlanUID(planC,1);
end

% Return whether UID linkaged had to be created. hence the ~
isUIDCreated = ~isUIDCreated;

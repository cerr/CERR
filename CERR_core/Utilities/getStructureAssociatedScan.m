function [assocScansV, relStructNumV] = getStructureAssociatedScan(structsV, planC)
%"getStructureAssociatedScan"
%   Returns a vector with the corresponding associated scan index for each
%   structure number passed in structsV.The structure number passed are
%   checked for associated scan set based on the associated scan UID with
%   that structure number.
%
%   Also returns relStructureNumV, a list of "relative" structure indices for
%   the passed structsV.  This is the number of the structure in the list
%   of all structures with the same associatedScan.
%
%   If planC is not specified, the global planC is used.
%
%DK 12/07/06
%
%Usage:
%   [assocScansV, relStructNum] = getStructureAssociatedScan(structsV, planC)
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


%Return if no structures were passed in.
if isempty(structsV)
    assocScansV = [];
    relStructNumV = [];
    return;
end

if ~exist('planC','var')
    global planC
end
indexS = planC{end};

% Preallocate memory to speed up the function
allAssocScanUID = cell(1,length(planC{indexS.structures}));
scanUID = cell(1,length(planC{indexS.scan}));

% % Get all associated scan UID from structures
[allAssocScanUID{1:length(planC{indexS.structures})}] = deal(planC{indexS.structures}.assocScanUID);

% Get the scan UID from the scan field under planC
[scanUID{1:length(planC{indexS.scan})}] = deal(planC{indexS.scan}.scanUID);

% Get associated scan UID's
assocScanUID = allAssocScanUID(structsV);

% Match all the UID to check which scan the structure belongs too.
%[jnk,assocScansV] = ismember(assocScanUID,scanUID);
for strNum = 1:length(assocScanUID)
    assocScansV(strNum) = find(strcmp(assocScanUID{strNum},scanUID));
end

%Calculate relativeStructNum for all structures.
allRelStructNumV = ones(1,length(allAssocScanUID));
for i=1:length(planC{indexS.scan})    
    %isAssocToScan = ismember(allAssocScanUID,scanUID{i});
    %allRelStructNumV(find(isAssocToScan)) = 1:length(find(isAssocToScan));
    isAssocToScan = strcmp(allAssocScanUID,scanUID{i});
    allRelStructNumV(isAssocToScan) = 1:sum(isAssocToScan);
end

%Only return relStructNum for the requested structs.
relStructNumV = allRelStructNumV(structsV);

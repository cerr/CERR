function assocTextureV = getScanAssociatedTexture(scansV, planC)
%"getScanAssociatedTexture"
%   Returns a vector with the corresponding associated texture index for each
%   scan number passed in scansV. The scan number passed are
%   checked for associated texture uid.
%
%
%APA, 10/02/2015
%
%Usage:
%   assocTextureV = getScanAssociatedTexture(scansV, planC)
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
if isempty(scansV)
    assocTextureV = [];
    return;
end

if ~exist('planC','var')
    global planC
end
indexS = planC{end};

% Preallocate memory to speed up the function
allAssocTextUID = cell(1,length(planC{indexS.scan}));
textUID = cell(1,length(planC{indexS.texture}));

% % Get all associated texture UID from scans
[allAssocTextUID{1:length(planC{indexS.scan})}] = deal(planC{indexS.scan}.assocTextureUID);

% Get the texture UID from the texture field under planC
[textUID{1:length(planC{indexS.texture})}] = deal(planC{indexS.texture}.textureUID);

% Get associated scan UID's
assocTextureUID = allAssocTextUID(scansV);

% Match all the UID to check which scan the structure belongs too.
%[jnk,assocScansV] = ismember(assocScanUID,scanUID);
for scanNum = 1:length(assocTextureUID)
    assocTextureV(scanNum) = find(strcmp(assocTextureUID{scanNum},textUID));
end

% %Calculate relativeStructNum for all structures.
% allRelStructNumV = ones(1,length(allAssocScanUID));
% for i=1:length(planC{indexS.scan})    
%     %isAssocToScan = ismember(allAssocScanUID,scanUID{i});
%     %allRelStructNumV(find(isAssocToScan)) = 1:length(find(isAssocToScan));
%     isAssocToScan = strcmp(allAssocScanUID,scanUID{i});
%     allRelStructNumV(isAssocToScan) = 1:sum(isAssocToScan);
% end
% 
% %Only return relStructNum for the requested structs.
% relStructNumV = allRelStructNumV(structsV);

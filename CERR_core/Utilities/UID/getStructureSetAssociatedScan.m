function structureSet = getStructureSetAssociatedScan(scanSet, planC)
% DK
% LM: APA, 10/22/08: Fixed to output correct associated structure index
%
% copyright (c) 2001-2008, Washington University in St. Louis.
%
% Permission is granted to use or modify only for non-commercial, 
% non-treatment-decision applications, and further only if this header is 
% not removed from any file. No warranty is expressed or implied for any 
% use whatever: use at your own risk.  Users can request use of CERR for 
% institutional review board-approved protocols.  Commercial users can 
% request a license.  Contact Joe Deasy for more information 
% (radonc.wustl.edu@jdeasy, reversed).

if ~exist('planC','var')
    global planC
end
indexS = planC{end};

structureSet = [];
structureSet = sparse(structureSet);


[assocScanUID{1:length(planC{indexS.structureArray})}] = deal(planC{indexS.structureArray}.assocScanUID);

if isempty(assocScanUID)
    structureSet = [];
    return
end

for i = 1:length(scanSet)

    scanUID = planC{indexS.scan}(scanSet(i)).scanUID;
    try
        structureSet(i) = find(strcmpi(scanUID,assocScanUID));
    end
end
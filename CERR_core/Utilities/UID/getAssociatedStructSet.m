function structSet = getAssociatedStructSet(uid,planC)
% getAssociatedStructSet
% Returns the associated structure set index. 
% copyright (c) 2001-2008, Washington University in St. Louis.
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


if length(planC{indexS.structureArray})< 1
    structSet = [];
    return
end

[allStructSetUID{1:length(planC{indexS.structureArray})}] = deal(planC{indexS.structureArray}.structureSetUID);

if length(uid)== 0
    structSet = [];
    return
else    
    [jnk,structSet] = ismember(uid,allStructSetUID);
end

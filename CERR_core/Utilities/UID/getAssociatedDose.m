function indxV = getAssociatedDose(uid)
%"getAssociatedDose"
%   Returns a dose index for corresponding dose uid passed.
%
%	DK 12/07/2006
% copyright (c) 2001-2008, Washington University in St. Louis.
% Permission is granted to use or modify only for non-commercial, 
% non-treatment-decision applications, and further only if this header is 
% not removed from any file. No warranty is expressed or implied for any 
% use whatever: use at your own risk.  Users can request use of CERR for 
% institutional review board-approved protocols.  Commercial users can 
% request a license.  Contact Joe Deasy for more information 
% (radonc.wustl.edu@jdeasy, reversed).
%
%Usage:
%   indxV = getAssociatedDose(uid)

global planC
indexS = planC{end};

% preallocate memory
if length(planC{indexS.dose})< 1
    indxV = [];
    return
end

[doseUID{1:length(planC{indexS.dose})}] = deal(planC{indexS.dose}.doseUID);

if length(uid)==0
    indxV = [];
else
    [jnk,indxV] = ismember(uid,doseUID);
    if indxV == 0;
        indxV = [];
    end
end

function indxV = getAssociatedStr(uid)
%"getAssociatedStr"
%   Returns a structure index for corresponding structure uid passed. uid can be a
%   cell array of strUID's in that case output will be an array of structure indices
%
%	DK 12/07/2006
%
%Usage:
%   indxV = getAssociatedStr(uid)

% copyright (c) 2001-2008, Washington University in St. Louis.
% Permission is granted to use or modify only for non-commercial, 
% non-treatment-decision applications, and further only if this header is 
% not removed from any file. No warranty is expressed or implied for any 
% use whatever: use at your own risk.  Users can request use of CERR for 
% institutional review board-approved protocols.  Commercial users can 
% request a license.  Contact Joe Deasy for more information 
% (radonc.wustl.edu@jdeasy, reversed).


global planC
indexS = planC{end};

if length(planC{indexS.structures})< 1
    indxV = [];
    return
end

[strUID{1:length(planC{indexS.structures})}] = deal(planC{indexS.structures}.strUID);

if length(uid)==0
    indxV = [];
else
    [jnk,indxV] = ismember(uid,strUID);
    if indxV == 0;
        indxV = [];
    end    
end


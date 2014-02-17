function indxV = getAssociatedScan(varargin)
%"getAssociatedScan"
%   Returns a scan index for corresponding scan uid passed.
%
%	DK 12/07/2006
% copyright (c) 2001-2006, Washington University in St. Louis.
% Permission is granted to use or modify only for non-commercial, 
% non-treatment-decision applications, and further only if this header is 
% not removed from any file. No warranty is expressed or implied for any 
% use whatever: use at your own risk.  Users can request use of CERR for 
% institutional review board-approved protocols.  Commercial users can 
% request a license.  Contact Joe Deasy for more information 
% (radonc.wustl.edu@jdeasy, reversed).
%
%Usage:
%   indxV = getAssociatedScan(uid)

if nargin < 2
    global planC    
else
    planC = varargin{2};
end

indexS = planC{end};

uid = varargin{1};
    
if length(planC{indexS.scan})< 1
    indxV = [];
    return
end

[scanUID{1:length(planC{indexS.scan})}] = deal(planC{indexS.scan}.scanUID);

if length(uid)==0
    indxV = [];
else
    [jnk,indxV] = ismember(uid,scanUID);
    if indxV == 0
        indxV = [];
    end
end

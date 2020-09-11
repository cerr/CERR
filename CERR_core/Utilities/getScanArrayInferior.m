function [scanArrayInferior, isCompress, isRemote] = getScanArrayInferior(scanIndex, planC)
%"getScanArray"
%   Returns the scanArray stored in a planC, in slot scanIndex.  The last
%   returned scanArray is cached in a persistent variable to avoid delays
%   in loading remotely stored or compressed scans.
%
%   If a scan array is compressed it is decompressed before being returned.
%
%   If planC is not passed in, the global planC is used.
%
%   If scanIndex is not valid, or if no valid planC can be found an error is
%   returned.
%
%   isCompress and isRemote are booleans to let the calling function know
%   if the scanArray was compressed and/or remote.
%
%   JRA 10/14/04
%
%Usage:
%   function scanArray = getScanArray(scanIndex, planC)
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

persistent lastScanStruct;
persistent lastScanArray;
persistent isLastScanCompressed;
persistent isLastScanRemote;

%Check if a scanStruct, not a scanIndex was passed.
if isstruct(scanIndex) && isfield(scanIndex, 'scanArray')
    
    scanStruct = scanIndex(1);
    
else
    %An index was passed, extract the scanStruct.
	if ~exist('planC','var')
        global planC
	end
	
	if ~iscell(planC)
        error('Cannot get scan. PlanC is not a valid cell array.');
	end
	
	indexS = planC{end};
	
	if scanIndex > length(planC{indexS.scan}) || scanIndex < 1
        error('Cannot get scan.  Requested scanIndex scan not exist.')
	end

    scanStruct = planC{indexS.scan}(scanIndex);    
    
end

scanArrayInferior = scanStruct.scanArrayInferior;

%If remote or compressed, and struct is same as last time, return cached array.
if (isCompressed(scanArrayInferior) || ...
        ~isLocal(scanArrayInferior)) && isequal(scanStruct, lastScanStruct)
    scanArrayInferior = lastScanArray;    
    isCompress = isLastScanCompressed;
    isRemote = isLastScanRemote;
    return;
%If remote or compressed and NOT the same as last time, clear cache.    
elseif (isCompressed(scanArrayInferior) || ...
        ~isLocal(scanArrayInferior)) && ~isequal(scanStruct, lastScanStruct)
	lastScanArray           = [];
	lastScanStruct          = [];
	isLastScanCompressed    = [];
	isLastScanRemote        = [];
end

%To be output for calling function's use.
isCompress  = 0;
isRemote    = 0;

%Decompress and follow all file pointers until get to an array.
while isCompressed(scanArrayInferior) || ~isLocal(scanArrayInferior)
    if isCompressed(scanArrayInferior)
        scanArrayInferior   = decompress(scanArrayInferior);
        isCompress  = 1;
    elseif ~isLocal(scanArrayInferior)
        scanArrayInferior   = getRemoteVariable(scanArrayInferior);
        isRemote    = 1;
    end           
end

lastScanArray           = scanArrayInferior;
lastScanStruct          = scanStruct;
isLastScanCompressed    = isCompress;
isLastScanRemote        = isRemote;

%temp
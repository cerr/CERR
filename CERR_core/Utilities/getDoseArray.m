function [doseArray, isCompress, isRemote] = getDoseArray(doseIndex, planC)
%"getDoseArray"
%   Returns the doseArray stored in a planC, in slot doseIndex.  The last
%   returned doseArray is cached in a persistent variable to avoid delays
%   in loading remotely stored or compressed doses.
%
%   If a dose array is compressed it is decompressed before being returned.
%
%   If planC is not passed in, the global planC is used.
%
%   If doseIndex is not valid, or if no valid planC can be found an error is
%   returned.
%
%   isCompress and isRemote are booleans to let the calling function know
%   if the doseArray was compressed and/or remote.
%
%   JRA 10/14/04
%
%Usage:
%   function doseArray = getDoseArray(doseIndex, planC)
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


persistent lastDoseStruct;
persistent lastDoseArray;
persistent isLastDoseCompressed;
persistent isLastDoseRemote;

%Check if a doseStruct, not a doseIndex was passed.
if isstruct(doseIndex) && isfield(doseIndex, 'doseArray')
    
    doseStruct = doseIndex(1);
    
else
    %An index was passed, extract the doseStruct.
	if ~exist('planC', 'var') %wy
        global planC
	end
	
	if ~iscell(planC)
        error('Cannot get dose. PlanC is not a valid cell array.');
	end
	
	indexS = planC{end};
	
	if doseIndex > length(planC{indexS.dose}) | doseIndex < 1
        error('Cannot get dose.  Requested doseIndex does not exist.')
	end

    doseStruct = planC{indexS.dose}(doseIndex);    
    
end

doseArray = doseStruct.doseArray;

%If remote or compressed, and struct is same as last time, return cached array.
if (isCompressed(doseArray) || ~isLocal(doseArray)) && isequal(doseStruct, lastDoseStruct);
    doseArray = lastDoseArray;    
    isCompress = isLastDoseCompressed;
    isRemote = isLastDoseRemote;
    return;
%If remote or compressed and NOT the same as last time, clear cache.    
elseif (isCompressed(doseArray) || ~isLocal(doseArray)) && ~isequal(doseStruct, lastDoseStruct);
	lastDoseArray           = [];
	lastDoseStruct          = [];
	isLastDoseCompressed    = [];
	isLastDoseRemote        = [];
end

%To be output for calling function's use.
isCompress  = 0;
isRemote    = 0;

%Decompress and follow all file pointers until get to an array.
while isCompressed(doseArray) || ~isLocal(doseArray);
    if isCompressed(doseArray)
        doseArray   = decompress(doseArray);
        isCompress  = 1;
    elseif ~isLocal(doseArray);
        doseArray   = getRemoteVariable(doseArray);
        isRemote    = 1;
    end           
end

lastDoseArray           = doseArray;
lastDoseStruct          = doseStruct;
isLastDoseCompressed    = isCompress;
isLastDoseRemote        = isRemote;

%temp
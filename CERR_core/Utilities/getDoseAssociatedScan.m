function assocScansV = getDoseAssociatedScan(dosesV, planC)
% "getDoseAssociatedScan"
%   Returns a vector with the corresponding associated scan for each 
%   dose number passed in structsV.
%
%   If planC is not specified, the global planC is used.
%
% DK 07/19/2006
%
%Usage:
%   [assocScansV, relStructNum] = getDoseAssociatedScan(dosesV, planC)
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


if ~exist('planC')
    global planC
end
indexS = planC{end};

assocScansV = [];

for i = 1:length(dosesV)
    assocScanTmp = getAssociatedScan(planC{indexS.dose}(dosesV(i)).assocScanUID, planC);
    if ~isempty(assocScanTmp)
        assocScansV(i) = assocScanTmp;
    end
end


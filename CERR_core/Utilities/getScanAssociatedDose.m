function doseNum = getScanAssociatedDose(scanNum,opt,planC)
% "getScanAssociatedDose"
% get the dose number corresponding to a scan number
% DK 07/20/06
% LM: APA, 01/29/08: Fixed to output correct associated dose index
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


if ~exist('planC','var')
    global planC
end
indexS = planC{end};

scanUID  = planC{indexS.scan}(scanNum).scanUID;

doseNum = [];
for i=1:length(planC{indexS.dose})
    if strcmpi(planC{indexS.dose}(i).assocScanUID,scanUID)
        doseNum = [doseNum i];
    end
end

if exist('opt','var') && strcmpi(opt,'all')
    return;
elseif ~isempty(doseNum)
    doseNum = doseNum(1);
end

return;

function planC = saveDVHMatrix(DVHNum, doseBinsV, volsHistV, planC)
%"saveDVHMatrix"
%   Store the doseBinsV and volsHistV with the binWidth shift removed.
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
%
%Usage:
%   function planC = saveDVHMatrix(DVHNum, doseBinsV, volsHistV, planC)
if isempty(doseBinsV)|isempty(volsHistV)
    error('Cannot save DVH for empty structures');
end
indexS = planC{end};

if length(doseBinsV) == 1
    doseBinsV(2) = 2*doseBinsV(1);
    volsHistV(2) = 0;
end

%Calculate width of bins, use to find middle of each bin.
binWidthsV = diff(doseBinsV);
lastBinWidth = binWidthsV(end);
binWidthsV(end+1) = lastBinWidth;

%Extract dose bin values, adding half to binwidth to get lower edge.
planC{indexS.DVH}(DVHNum).DVHMatrix(:,1) = doseBinsV - binWidthsV/2;
planC{indexS.DVH}(DVHNum).DVHMatrix(:,2) = volsHistV;
return;
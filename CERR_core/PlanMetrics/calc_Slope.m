function dVoldDose = calc_Slope(doseBinsV, volsHistV, doseValue, absFlag)
% Calculate the slope dVol/dDose at doseValue for a given DVH.
% absFlag = 0 for normalized DVH, whereas absFlag = 1 for absolute DVH.
%
% APA,03/20/2007
%
% Usage: calc_Slope(doseBinsV, volsHistV, doseValue, absFlag)
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


if ~exist('absFlag')
    absFlag = 0;
end
cumVolsV = cumsum(volsHistV);
if ~absFlag    
    cumVols2V  = cumVolsV(end) - cumVolsV;  %cumVolsV is the cumulative volume lt that corresponding dose
    cumVols2V  = cumVols2V/cumVolsV(end);
else
    cumVols2V  = cumVolsV(end) - cumVolsV;;
end

indToLeft   = max(find(doseBinsV < doseValue));
indToRight  = min(find(doseBinsV > doseValue));

%Take care of corner indices
if isempty(indToLeft)
    indToLeft   = indToRight;
    indToRight  = indToRight + 1;
end
if isempty(indToRight)
    indToRight  = indToLeft;    
    indToLeft   = indToRight - 1;
end

indToFit = [indToLeft:-1:max(1,indToLeft-5) indToRight:1:min(length(doseBinsV),indToRight+5)];
linearFit = polyfit(doseBinsV(indToFit),cumVols2V(indToFit),1);
dVoldDose = linearFit(1);

%dVoldDose   = (cumVols2V(indToRight) - cumVols2V(indToLeft)) / (doseBinsV(indToRight) - doseBinsV(indToLeft));

return;
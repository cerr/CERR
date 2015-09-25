function [doseBinsV, volsHistV] = doseHist(doseV, volsV, binWidth)
%"doseHist"
%   Put the dose values into individual histogram bins.  doseV is a list of
%   dose values and volsV is a list of corresponding volumes for each value
%   in doseV.  
%
%   binWidth is the desired width of a single bin in doseBinsV.
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
%   [doseBinsV, volsHistV] = doseHist(doseV, volsV, binWidth)

if (min(doseV)>=0)
    maxD = max(doseV);
    
    indV = ceil(eps + (doseV/binWidth));
    
    maxBin = ceil(eps + (maxD/binWidth));
    
    doseBinsV = ([1 : maxBin] - 1 ) * binWidth + binWidth/2;

    volsHistV = zeros(1,maxBin);

    [volsHistV] = accumulate(volsHistV, volsV, indV);

else

    maxD = max(doseV);
    minD = min(doseV);

    indV = doseV/binWidth;
%     indV(indV<0) = floor(indV(indV<0));
%     indV(indV>0) = floor(indV(indV>0));
    indV = ceil(indV);
    
    indV = indV - min(indV) + 1;
    
    maxBin = ceil((maxD/binWidth));
    minBin = ceil((minD/binWidth));

    doseBinsV = ([minBin : maxBin]-1) * binWidth + binWidth/2;

    volsHistV = zeros(1,maxBin-minBin+1);

    [volsHistV] = accumulate(volsHistV, volsV, indV);
    
end    
    











    
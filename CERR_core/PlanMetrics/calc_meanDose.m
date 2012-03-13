function ans = calc_meanDose(doseBinsLowerPtsV, volsHistV, volumeType)
%Calculate the mean dose for a given DVH
%  The last parameter 'volumeType' is a wash in this function again
%  
%  MODIFICATION ALERT:  THIS FUNCTION IS UTILIZED BY THE DREXLER CODEBASE
%
%  LM: 6 Oct 06, JOD, corrected slight error in not taking middle of dose
%  bin.  Added warning if relative volume not close to one (0.5%
%  tolerance).
%
% Usage: calc_meanDose(doseBinsLowerPtsV, volsHistV)
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


    doseBinsMidPtsV = (doseBinsLowerPtsV(1:end-1)+doseBinsLowerPtsV(2:end))/2;
    ans = (sum(doseBinsMidPtsV.*volsHistV(1:end-1))+doseBinsLowerPtsV(end)*volsHistV(end))/sum(volsHistV);
return;
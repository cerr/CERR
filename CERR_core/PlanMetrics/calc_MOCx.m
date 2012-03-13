function ans = calc_MOCx(doseBinsV, volsHistV, percent)
% Returns the mean dose of the lower tail (the coldest x% of the structure)
% given the DVH data and the parameter percent.
%  
%  MODIFICATION ALERT:  THIS FUNCTION IS UTILIZED BY THE DREXLER CODEBASE
%
%  Created: VHC 4/11/06, based off of calc_Dx code, 
%  IME modified 04/17/06
%  VHC modified 11/20/06, changed from calc_MOHx to calc_MOCx
%
%  Usage: calc_MOCx(doseBinsV, volsHistV, percent)
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


    cumVolsV = cumsum(volsHistV);
	cumVols2V = cumVolsV(end) - cumVolsV;
    
    inds = find([cumVols2V/cumVolsV(end) >= (100-percent)/100 ]); %all dose(index)s above (100-percent)% volume on DVH.
    
    %find mean of doses represented by inds.
    
	%ind = min(inds); %to get min dose
	if isempty(inds)
        ans = 0;
    else
        ans = sum(doseBinsV(inds) .* volsHistV(inds)) / sum(volsHistV(inds));
    	%ans = doseBinsV(ind); %to get min dose
	end
return;
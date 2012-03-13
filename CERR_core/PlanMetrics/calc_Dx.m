function ans = calc_Dx(doseBinsV, volsHistV, percent)
% Returns the lowest dose in x% of structure'
% given the DVH data and the parameter percent.
%  
%  MODIFICATION ALERT:  THIS FUNCTION IS UTILIZED BY THE DREXLER CODEBASE
%
%  Last modified: AJH 11/05
%
%  Usage: calc_Dx(doseBinsV, volsHistV, percent)
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
	ind = min(find([ cumVols2V/cumVolsV(end) < percent/100 ]));
	if isempty(ind)
        ans = 0;
	else
    	ans = doseBinsV(ind);
	end
return;
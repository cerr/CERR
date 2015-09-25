function beamlet = createIMBeamlet(doseV, indV, beamNum, fullLength)
%"createIMBeamlet"
%   Take a vector of dose values and a vector of indices into the scan
%   array and build an IM.beamlets element.  
%
%JRA 9/20/04
%
%Usage:
%   function beamlet = createIMBeamlet(doseV, indV, beamNum, fullLength)
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

%Initialize the beamlet.
% IM = initIMRTProblem;
% beamlet = IM.beamlets;
beamlet = initBeamlet;
beamlet(1).format  = 'uint8';
beamlet(1).beamNum = beamNum;
beamlet(1).fullLength = fullLength;

if isempty(indV) | isempty(doseV)    
%     disp(['Warning: a pencil beam in beam ' num2str(beamNum) ' does not contribute any dose to this structure.'])
    return;
end

if length(indV) ~= length(doseV)
    error('createIMBeamlet: Length of indV must match length of doseV.')
    return;
end

ind2V = find(doseV);

if isempty(ind2V)
    valsV = [];   
    maxVal = 0;
    smallVals = logical([]);
else
	valsV = doseV(ind2V);
	
	maxVal = max(valsV(:));
	
	%Bool vector to note low values, helps avoid uint8 roundoff error.
	smallVals = valsV < (maxVal/(2^8 - 1));
	
	%Store non small values as normal uint8s.
	valsV(~smallVals) = (valsV(~smallVals)/maxVal) * (2^8 - 1);  
	
	%Store small values as uint8s with another factor of 256.        
	valsV(smallVals) = valsV(smallVals)/(maxVal)*(2^8 - 1)*(2^8 - 1);    
end

%Save vector to ID low values when builidng inflM later.
%Uses a logical packer to decrease size by about 8.

beamlet(1).lowDosePoints = packLogicals(smallVals);        
beamlet(1).influence = uint8(valsV);
beamlet(1).indexV = uint32(indV(ind2V));
beamlet(1).maxInfluenceVal = maxVal;
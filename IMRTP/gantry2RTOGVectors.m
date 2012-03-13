function [RTOGVectorsM] = gantry2RTOGVectors(gantryVectorsM, gantryAngle, couchAngle)
%function [RTOGVectorsM] = gantry2RTOGVectors(gantryVectorsM, gantryAngle, couchAngle)
%Convert from gantry unit vectors to RTOG unit vectors (IEC 1217 coord system).
% gantryVectorsM has columns: i, j, and k components.
% gantryAngle is the phig gantry angle defined by IEC 1217.
% The current assumption is that the couch angle is zero.
% JOD, Oct 03.
% LM: JC Jan 26 2007
        % Include non-zero couchAngle
        % The desination coordinates should be the patient support
        % system. 
        % The previous assumption is that the "fixed system" is the same as
        % the "Patient support system".
        % test
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
        
cosphi = cosdeg(gantryAngle);

sinphi = sindeg(gantryAngle);

RTOGVectorsM = zeros(size(gantryVectorsM));

RTOGVectorsM(:,1) = sinphi * gantryVectorsM(:,3) + cosphi * gantryVectorsM(:,1);

RTOGVectorsM(:,2) = cosphi * gantryVectorsM(:,3) - sinphi * gantryVectorsM(:,1);

RTOGVectorsM(:,3) = - gantryVectorsM(:,2);

% JC Jan 26 2007
% Include non-zero couchAngle
% transform the coordinates for couchAngle.
if (couchAngle ~= 0 & couchAngle ~= 360)
    disp('transform coordinates for couchAngle');
    patientVectorsM = zeros(size(RTOGVectorsM));
    patientVectorsM(:,1) =  cosdeg(couchAngle) * RTOGVectorsM(:,1) - sindeg(couchAngle) * RTOGVectorsM(:,3);
    patientVectorsM(:,2) = RTOGVectorsM(:,2);
    patientVectorsM(:,3) = sindeg(couchAngle) * RTOGVectorsM(:,1) + cosdeg(couchAngle) * RTOGVectorsM(:,3);
    RTOGVectorsM = patientVectorsM;
end
return;

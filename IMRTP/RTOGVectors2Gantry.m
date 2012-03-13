function [gantryVectorsM] = RTOGVectors2Gantry(RTOGVectorsM, gantryAngle)
%function [gantryVectorsM] = RTOGVectors2Gantry(RTOGVectorsM, gantryAngle)
%Convert from RTOG unit vectors to gantry unit vectors (IEC 1217 coord system).
% RTOGVectorsM has columns: i, j, and k components.
% gantryVectorsM are the vectors in the gantry frame, defined by IEC 1217.
% gantryAngle is the phig gantry angle defined by IEC 1217.
% The current assumption is that the couch angle is zero.
% JOD, Oct 03.
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

gantryVectorsM = zeros(size(RTOGVectorsM));

gantryVectorsM(:,1) = cosphi * RTOGVectorsM(:,1) - sinphi * RTOGVectorsM(:,2);

gantryVectorsM(:,2) = - RTOGVectorsM(:,3);

gantryVectorsM(:,3) = sinphi * RTOGVectorsM(:,1) + cosphi * RTOGVectorsM(:,2);



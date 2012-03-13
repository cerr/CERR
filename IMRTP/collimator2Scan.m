function scan3V = collimator2Scan(coll3V, gantryAngle, couchAngle, collimatorAngle, isocenter, isodistance)
%"collimator2Scan"
%   Convert from collimator coordinate system to scan coordinate system.  The
%   scan system is that of a typical CERR CT, where +Z points in the
%   direction of the patient's head, +X points in the direction of the
%   patient's left side, and +Y points out of the patient's chest.
%
%   coll3V is a matrix whose rows are each x,y,z vectors/points in the collimator
%   system, to be converted to scan3V.
%
%   gantryAngle is the angle of rotation about the Y axis of the ROOM, at
%   isocenter.
%
%   couchAngle is the angle that the table is rotated about the Z axis of
%   the ROOM, also at isocenter.
%
%   collimatorAngle is the angle that the beam limiting device is rotated
%   about the central axis of the beam.
%
%   scan3V is scan coordinates.
%   
%   See IEC 1217 for details.
%
%   ALL ANGLES ARE IN RADIANS.
%
%JRA 3/29/05
%
%Usage:
%  scan3V = collimator2Scan(coll3V, gantryAngle, couchAngle, collimatorAngle, isocenter, isodistance)
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

%Transformation matrix starts as the identity.
transM = eye(4);
transM = transM([1 2 3], :);

%Un-rotate collimatorCoordinates through the collimatorAngle and shift the
%origin from radiation source to isocenter to get gantry coordinates.
collRot  = [cos(collimatorAngle)     sin(collimatorAngle)     0;...
            -sin(collimatorAngle)    cos(collimatorAngle)     0;...
            0                   0                             1];

transM = inv(collRot) * transM;

%Now move the source in gantry coordinates to the radiation source.
transM(3,4) = transM(3,4) + isodistance;

%Now un-rotate gantry coordinates by the gantry angle, about Y to get room coordinates.
gantryRot = [cos(gantryAngle)   0   -sin(gantryAngle);...
             0                  1                   0;...
             sin(gantryAngle)   0   cos(gantryAngle)];
     
transM = inv(gantryRot) * transM;

%Now un-rotate the room coordinates through the couchAngle, about Z to
%get table coordinates.
couchRot = [cos(couchAngle)     sin(couchAngle)     0;...
            -sin(couchAngle)    cos(couchAngle)     0;...
            0                   0                   1];
    
transM = couchRot * transM;

%Flip y and z to go from table coordinates to isocenter origin scan coordinates.
transM = transM([1 3 2],:);

%Negate Z
transM(3,:) = -transM(3,:);

%Shift origin of scan coordiante system from isocenter for real scan coordinates.
%Shift origin of scan coordiante system (0,0,0) to isocenter.
transM(1,4) = transM(1,4) + isocenter(1);
transM(2,4) = transM(2,4) + isocenter(2);
transM(3,4) = transM(3,4) + isocenter(3);

scan3V = applyTransM(transM, coll3V);
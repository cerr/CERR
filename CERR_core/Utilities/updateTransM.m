function transM = updateTransRot(operation, val, transM, rotPoint)
%"updateTransM"
%
%   Updates the transformation matrix to include a new rotation or
%   translation.  Operation can be 'xt', 'yt', or 'zt' for translation 
%   in x,y,z or 'xr', 'yr', 'zr' for rotation about x, y, or z-axes.
%
%   Val is the amount of the translation or rotation (in cm/radians).
%
%   If transM is not passed in, it is assumed to be the identity matrix.
%   rotPoint is an optional point to perform the rotation around, and
%   should only be specified when using 'xr' 'yr', and 'zr'.  It is [0 0 0]
%   by default.
%
%JRA 11/24/04
%
%Usage:
%   function transM = updateTransRot(operation, val, transM, rotPoint)
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

if ~exist('transM')
    transM = eye(4);
end

nonZeroCenter = 0;
if exist('rotPoint')
    nonZeroCenter = 1;    
    forwardTrans = eye(4);
    forwardTrans(1:3, 4) = reshape(-rotPoint, [3 1]);
    reverseTrans = eye(4);
    reverseTrans(1:3, 4) = reshape(rotPoint, [3 1]);
end    

newTrans = eye(4);
switch lower(operation)
    case 'xt'        
        newTrans(1,4) = val;        
    case 'yt'
        newTrans(2,4) = val;
    case 'zt'
        newTrans(3,4) = val;
    case 'xr'
        newTrans(2:3,2:3) = [cos(val) -sin(val); sin(val) cos(val)];
    case 'yr'
        newTrans(1,1) = cos(val);
        newTrans(1,3) = sin(val);
        newTrans(3,1) = -sin(val);
        newTrans(3,3) = cos(val);
    case 'zr'
        newTrans(1:2,1:2) = [cos(val) -sin(val); sin(val) cos(val)];
end

if nonZeroCenter
    %Make the rotPoint be [0 0 0], perform the rotation, and move it back.
    transM = forwardTrans * transM;
    transM = newTrans * transM;
    transM = reverseTrans * transM;   
else
    transM = newTrans * transM ;
end
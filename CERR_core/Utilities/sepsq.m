function sq = sepsq(pointsV1, pointsV2)
%"sepsq"
%   Returns the square of the distance between all points in pointsV1 and
%   all points in pointsV2.  Valid for any number of dimensions.  Points
%   must be specified with the dimensions along the rows and the points
%   along columns, IE for a set of 4 points in 3space:
%
%               1 6 4 2
%   pointsV1 =  1 1 4 7
%               1 2 5 7
%
%   This function attempts to use mex_sepsq for speed, failing that it uses
%   Matlab code.
%
%JRA 9/9/04
%
%Usage:
%   function sq = sepsq(pointsV1, pointsV2);
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

try 
    sq = single(mex_sepsq(pointsV1, pointsV2));
catch
    lasterr('Unable to use mex_sepsq.  Using sepsq code instead.', '');    
    siz1 = size(pointsV1);
    siz2 = size(pointsV2);
    
    sq = repmat(single(0), [siz1(2) siz2(2)]);
    
    for i=1:siz1(2)
        tmp = repmat(pointsV1(:,i), [1 siz2(2)]);
        sq(i,:) = sum((pointsV2 - tmp).^2,1);
    end
end
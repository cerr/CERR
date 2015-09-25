function [iV,jV,kV]=find3d(mask3M)
%"find3d"
%   This is the 3D equivalent of the builtin command, find.
%   It returns the i,j,k indices of non-zero entries.
%
%JOD, 16 Nov 98
%JOD, 26 Feb 03, bugfix.
%JRA, 26 Feb 04, new algorithm, also implements the new fastind2sub.
%
%Usage:
%   [iV,jV,kV]=find3d(mask3M);
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

indV = find(mask3M(:));
[iV,jV,kV] = fastind2sub(size(mask3M), indV);
iV = iV';
jV = jV';
kV = kV';
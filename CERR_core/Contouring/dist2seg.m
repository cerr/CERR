function [d, flag] = dist2seg(r0V, r1V, r2V)
%Return the shortest distance from the point
%given by the two-d vector r0V to the line segment whose
%endpoints are given by the two-d vectors r1V and r2V.
%If the shortest distance is to the first endpoint, flag = -1;
%if to the second endpoint, flag = 1;
%if to the perpindicular, flag = 0.
%
%J.O.Deasy, 20 Mar 02

%1.  Compute the cosine between the line and the vector
%    from r2V to r0V.
%2.  compute the distance to the perpindicular.
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


r12V = r1V - r2V;
r02V = r0V - r2V;
r01V = r0V - r1V;

mag_r02V = dot(r02V, r02V)^0.5;
mag_r12V = dot(r12V, r12V)^0.5;
mag_r01V = dot(r01V, r01V)^0.5;

cosAlpha = dot(r12V, r02V) / (mag_r02V * mag_r12V);

mag_r2dV = mag_r02V * cosAlpha;    %distance from pt 2 to perpindicular line base

d = (mag_r02V^2 - mag_r2dV^2)^0.5; %this is perpindicular distance from pt0 to line through pts 1 and 2.

%Now: is it inside or outside the segment?
if mag_r2dV < 0
  d = mag_r02V; %point is nearest 2nd endpt, use that distance
  flag = 1;
elseif mag_r2dV > mag_r12V %point is nearest 1st endpt, use that distance
  flag = -1;
  d = mag_r01V;
else
  flag = 0; %nearest to perpindicular... retain d.
end









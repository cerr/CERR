function out = pad(a, numToPad, list)
%function out = pad(a,list)
%pad a with zeros according to the four values
%in the vector list:
%list(1) gives the number of rows to be preprended,
%list(2) gives the number of rows to be appended,
%list(3) gives the number of columns to be prepended,
%list(4) gives the number of columns to be appended.
%Negative numbers correspond to stripping of columns or rows.
%JOD.
%Latest modifications:
%   7 May 03, JOD, fixed bug if list(2) is negative.
%   20 Jun 03, JRA, added parameter numToPad to make it possible to pad with things other than 0.  Involved changing zeros to ones*numToPad.
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


if list(1) >= 0
    out = [ones(list(1),size(a,2))*numToPad; a];
else
    out = a(-list(1)+1:end,:);
end

if list(2) >= 0
    out = [out; ones(list(2),size(out,2))*numToPad];
else
    out = out(1:end + list(2),:);
end

if list(3) >= 0
    out = [ones(size(out,1),list(3))*numToPad, out];
else
    out = out(:,-list(3)+1:end);
end

if list(4) >= 0
     out = [out, ones(size(out,1),list(4))*numToPad];
else
     out = out(:, 1:end + list(4));
end












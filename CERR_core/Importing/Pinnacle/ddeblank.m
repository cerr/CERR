function sout = ddeblank(s)
%DDEBLANK Double deblank. Strip both leading and trailing blanks.
%
%   DDEBLANK(S) removes leading and trailing blanks and null characters from
%   the string S.  A null character is one that has a value of 0.
%
%   See also DEBLANK, DEWHITE, DDEWHITE.

%   Author:      Peter J. Acklam
%   Time-stamp:  2003-10-13 11:13:07 +0200
%   E-mail:      pjacklam@online.no
%   URL:         http://home.online.no/~pjacklam
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

error(nargchk(1, 1, nargin));
if ~ischar(s)
	warning('Input must be a string (char array).');
end

if isempty(s)
	sout = s;
	return;
end

[r, c] = find( (s ~= ' ' & s ~= 9 ) & (s ~= 0) );
if size(s, 1) == 1
	sout = s(min(c) : max(c));
else
	sout = s(:, min(c) : max(c));
end


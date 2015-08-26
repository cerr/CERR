function parts = strsplit_cerr(splitstr, str, option)
%STRSPLIT_CERR Split string into pieces.
%
%   STRSPLIT_CERR(SPLITSTR, STR, OPTION) splits the string STR at every occurrence
%   of SPLITSTR and returns the result as a cell array of strings.  By default,
%   SPLITSTR is not included in the output.
%
%   STRSPLIT_CERR(SPLITSTR, STR, OPTION) can be used to control how SPLITSTR is
%   included in the output.  If OPTION is 'include', SPLITSTR will be included
%   as a separate string.  If OPTION is 'append', SPLITSTR will be appended to
%   each output string, as if the input string was split at the position right
%   after the occurrence SPLITSTR.  If OPTION is 'omit', SPLITSTR will not be
%   included in the output.

%   Author:      Peter J. Acklam
%   Time-stamp:  2004-09-22 08:48:01 +0200
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

nargsin = nargin;
error(nargchk(2, 3, nargsin));
if nargsin < 3
	option = 'omit';
else
	option = lower(option);
end

splitlen = length(splitstr);
parts = {};

while 1

	k = strfind(str, splitstr);
	if isempty(k)
		parts{end+1} = str;
		break
	end

	switch option
		case 'include'
			parts(end+1:end+2) = {str(1:k(1)-1), splitstr};
		case 'append'
			parts{end+1} = str(1 : k(1)+splitlen-1);
		case 'omit'
			parts{end+1} = str(1 : k(1)-1);
		otherwise
			error(['Invalid option string -- ', option]);
	end


	str = str(k(1)+splitlen : end);

end


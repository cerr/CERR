function outStr = deblank2(inStr)
%function outStr = deblank2(inStr)
%Fast deblanking of leading and trailing blanks.
%
%copyright (c) 2001, J.O. Deasy and Washington University in St. Louis.
%Use is granted for non-commercial and non-clinical applications.
%No warranty is expressed or implied for any use whatever.
%
%LM: 7 Jan 2002, JOD.
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

if isempty(inStr)
  outStr = [];
  return
end

realV = real(inStr);
len = length(inStr);
delV = zeros(1,len);
testV = [realV == 32];

if all(testV)  %string of blanks
  outStr = [];
  return
end


i = 1;
while testV(i)
  delV(i) = 1;
  i = i + 1;
end

i = len;
while testV(i)
  delV(i) = 1;
  i = i - 1;
end

realV(logical(delV)) = [];
outStr = char(realV);


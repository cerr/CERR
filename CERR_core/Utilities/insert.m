function xstring = insert(in,target,n,len,pad)
%function xstring = insert(in,target[,[n][,[len][,pad]]])
%inserts the string 'in', padded to length 'len' into
%the string 'target' after the nth character.  'len'
%must be nonnegative.  If 'n' is negative,
%the position of insertion is with respect to the end
%of the string: -1 is before the last character, -2 is before the
%next to last character, etc.  If 'n' is greater than the length
%of the target string, padding is added before the 'in'
%string also.  The default value for 'n' is 0, which means
%insert before the beginning of the string.
%The default
%value for 'len' is the length of 'in'.  The default
%pad character is the blank.
%(With a minor modification, for negative n,
%from the REXX specification, by M. F. Cowlishaw.)
%
%LM: J. O. Deasy, April 2000.
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

switch nargin

  case 4
    pad = ' ';

  case 3
    pad = ' ';
    len = length(in);

  case 2
    pad = ' ';
    len = length(in);
    n = 0;

end

n = n(:);

for i = 1:length(n)

  %create padding vector
  padlen = repmat(pad,1,len);

  %Pad the insertion string
  padin = padlen;

  padin(1:length(in)) = in;

  %pad the target if necessary:
  if n > length(target)
    target = [target, repmat(pad,1,n-length(target))];
  end


  %Insert:
  switch 1
  case n > 0
    before = target(1:n);
    after = target(n+1:end);
  case n == 0
    before = [];
    after = target;
  case n < 0
    pos = length(target) + n;
    before = target(1:pos);
    after = target(pos+1:end);
  end

  xstring = [before, padin, after];

end





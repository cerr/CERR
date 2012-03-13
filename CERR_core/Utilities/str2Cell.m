function outC = str2Cell(in, opt)
%Break a string into a cell array.
%To convert number strings into numbers, opt should be set
%to 'convert'.
%JOD.
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


n = words(in);
if n == 0
  outC = {};
  return
end

convert = 0;
if nargin == 2
  if strcmpi(opt,'convert')
    convert = 1;
  end
end

outC = cell(1,n);
for i = 1 : n
  tmp = word(in,i);
  num = str2num(tmp);
  if convert == 1 & ~isempty(num)
    tmp = num;
  end
  outC{i} = tmp;
end







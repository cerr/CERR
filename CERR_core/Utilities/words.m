function num_words=words(stringS)
%Returns the number (num_words) of blank-delimited words in stringC
%A word character is defined as any ASCII character except a blank.
%Inspired by the REXX specification.
%
%Matlab V. 5.2, rel.10
%
%ex.:
%  a='this and that'
%  n=words(a)%
%
%LM:  J. O. Deasy, Feb. 99.
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



if isempty(stringS), num_words = 0; return, end

if strcmp(stringS,''), num_words = 0; return, end

num_words=0;
hit_word=0;

for i=1:length(stringS)
  next_char=stringS(i);
  if ~isspace(next_char)
    hit_word=1;
  end
  if  isspace(next_char) & hit_word==1
      hit_word=0;
      num_words=num_words+1;
  end
end

if ~isspace(stringS(length(stringS)))
   num_words=num_words+1;
end







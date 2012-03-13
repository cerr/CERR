function [wordS, start, stop] = word(stringS,n)
%function [wordS start stop] = word(stringS,n)
%Returns the n'th blank delimited word in string of words. n
%must be positive. If there are fewer than n words in the string,
%the null string is returned.  The beginning and ending indices are
%given by 'start' and 'stop'.
%Inspired by the REXX function 'word'.
%
%ex:
%   c=word('a and b',3)
%
%LM: 7 March 02, JOD.
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


%Get the number of blank-delimited words:
num_words=words(stringS);

len = length(stringS);

if num_words<n
   wordS='';
   start = '';
   stop  = '';
else
   index=1;
   indices_begin=[];
   indices_end=[];
   beginning=0;
   ending=1;
   wordNum = 0;
   while index<= len
      char=stringS(index);
      if ~isspace(char) & beginning==0
        indices_begin=[indices_begin,index];
        ending=0;
        beginning=1;
      end
      if isspace(char) & ending==0
        indices_end=[indices_end,index-1];
        beginning=0;
        ending=1;
        wordNum = wordNum + 1;
        if wordNum == n
          index = len + 1; %finish
        end
      end
      index=index+1;
   end
   %special case: if the last character was not a space,
   %then we need to count it as ending a word:
   pos = len;
   if ~isspace(stringS(pos))
     indices_end=[indices_end,pos];
   end
   wordS=stringS(indices_begin(n):indices_end(n));
   start = indices_begin(n);
   stop  = indices_end(n);
end






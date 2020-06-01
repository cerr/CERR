function optS = setOptsExe(opt_str,optS)
%function optS = setOptsExe(opt_str,optS)
%Parse a command that sets the field of a structure, and return the
%structure.
%LM:  J.O.Deasy, 3 Sept, 2002.
%
%copyright (c) 2001, J.O. Deasy and Washington University in St. Louis.
%Use is granted for non-commercial and non-clinical applications.
%No warranty is expressed or implied for any use whatever.
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


if nargin == 1
  optS = [];
end

opt_str = deblank2(opt_str);
if ~isempty(strfind(opt_str,'=')) && ~strcmp(opt_str(1),'%')
  if ~strcmp(word(opt_str,1),'function') %skip function line if present
   %Remove any comments:
   ind1 = strfind('%',opt_str);
   if ~isempty(ind1)
     if ind1 == 1
       return
     end
     opt_str = opt_str(1:ind1-1);
   end
   %remove trailing ';'
   ind1 = strfind(';',opt_str);
   if ~isempty(ind1)
     opt_str = opt_str(1:ind1-1);
   end
   %parse the command
   %num = words(opt_str);
   %Get the first wor
   firstW = word(opt_str,1);
   %Find the period:
   ind2 = strfind('.',firstW);
   leaf = firstW(ind2+1:length(firstW));
   %Get setting: everything past the '=' sign
   ind3 = strfind(opt_str,'=');
   value = opt_str(ind3+1:length(opt_str));
   value = deblank2(value);
   %Convert numerical assignments to numbers:
   
   %catch cell arrays
   if strcmp(value(1),'{')
     %build cell array of strings
     iV = strfind(value,'''');
     value2 = {};
     for i = 1 : length(iV)/2
       j = i * 2 - 1;
       str = value(iV(j)+1:iV(j+1)-1);
       value2 = {value2{:},str};
     end
     value = value2;
   else
     if ~isempty(str2num(value))
       value = str2num(value);
     else  %remove apostrophes
       iV = strfind(value,'''');
       if ~isempty(iV)
         value(iV) = [];
       end
     end
   end

   %Finally, make the assignment:
   optS = setfield(optS, leaf, value);
  end
end

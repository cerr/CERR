function str = repSpaceHyp(str)
%function str = repSpaceHyp(str)
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


indSpace = strfind(str,' ');
indDot = strfind(str,'.');
str(indDot) = 'p';
indOpenParan = strfind(str,'(');
indCloseParan = strfind(str,')');
indPlus = strfind(str,'+');
indMinus = strfind(str,'-');
indPercent = strfind(str,'%');
indComma = strfind(str,',');
indBackSlash = strfind(str,'\');
indFwdSlash = strfind(str,'/');
indEqualTo = strfind(str,'=');
indQuestion = strfind(str,'?');
indAnd = strfind(str,'&');
indColon = strfind(str,':');
indStar = strfind(str,'*');
indHash = strfind(str,'#');
indCaret = strfind(str,'^');
indToReplace = [indSpace indOpenParan indCloseParan indPlus indMinus ...
    indPercent indComma indBackSlash indFwdSlash indEqualTo indQuestion ...
    indAnd indColon indStar indHash indCaret];
str(indToReplace) = '_';
indGreaterThan = strfind(str,'>');
indLessThan = strfind(str,'<');
str(indGreaterThan) = 'G';
str(indLessThan) = 'L';
indNum = strfind(str,'1');
if indNum == 1
    str(indNum) = 'A';
end
indNum = strfind(str,'2');
if indNum == 1
    str(indNum) = 'B';
end
indNum = strfind(str,'3');
if indNum == 1
    str(indNum) = 'C';
end
indNum = strfind(str,'4');
if indNum == 1
    str(indNum) = 'D';
end
indNum = strfind(str,'5');
if indNum == 1
    str(indNum) = 'E';
end
indNum = strfind(str,'6');
if indNum == 1
    str(indNum) = 'F';
end
indNum = strfind(str,'7');
if indNum == 1
    str(indNum) = 'G';
end
indNum = strfind(str,'8');
if indNum == 1
    str(indNum) = 'H';
end
indNum = strfind(str,'9');
if indNum == 1
    str(indNum) = 'I';
end
indNum = strfind(str,'0');
if indNum == 1
    str(indNum) = 'Z';
end
while isequal(str(end),'_')
    str(end) = [];
end
while isequal(str(1),'_')
    str(1) = [];
end
return;

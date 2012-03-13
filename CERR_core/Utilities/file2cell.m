function  FileC = file2cell(FileNameS, opt)
%Put a file into a cellarray.  Each cell is a
%line converted to a character string.
%If opt is set to 'spreadsheet', each word on each line becomes a cell within a
%cell array for each line, which is in a cell array of all lines.
%If opt is not present, each line becomes a character cell in a cell array.
%copyright (c) 2001, J.O. Deasy and Washington University in St. Louis.
%Use is granted for non-commercial and non-clinical applications.
%No warranty is expressed or implied for any use whatever.
%
%LM:  14 Feb 02, JOD.
%   13 Mar 03, JOD.  Added 'spreadsheet' option.
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

spread = 0;
if nargin > 1
  if strcmpi(opt,'spreadsheet')
    spread = 1;
  end
end


try
  fid = fopen(FileNameS,'r');
  FileV = fread(fid);
  fclose(fid);
catch
  FileC = {}
  warning(['Attempt to open ' FileNameS ' failed!'])
  return
end

FileC={};

if ~isempty(FileV)

  if any([FileV == 13])
    Newline = 13; %Define value of newline character; start assuming PC value, but check for UNIX below.
    FileV(FileV == 10) = []; %remove UNIX 'corruption'
  else
    Newline = 10;  %raw UNIX
  end

  %Break into lines.  Find all the newline characters.
  [LocationV] = find(FileV == Newline);

  %Reprocess to a cellarray
  Start = 1;
  for i = 1:length(LocationV)
    Stop = LocationV(i);

    strV = char(FileV(Start:Stop-1))';
    if spread == 0
      FileC{i} = strV;
    elseif spread == 1
      FileC{i} = str2Cell(strV, 'convert');
    end

    Start = Stop + 1;
  end

end



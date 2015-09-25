function writeStructure(structNum, fileName)
%This function writes a structure out in RTOG format to a user-named file.
%First version, JOD, 3 Oct 03
%Modified, JOD, 12 Oct 04.
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

global planC

if nargin == 1
  [file, path] = uiputfile('*.*', 'Save RTOG structure file as');
  fileName = [path file];
end

outC = {};   %The output will go here before writing it out.


%Get the structure polygon segment data

indexS = planC{end};

structS = planC{indexS.structures}(structNum).contour;

%Format:  planC{4}(1).contour(5).segments(1).points

numScans = length(planC{indexS.scan}(1).scanInfo);
str = ['"NUMBER OF LEVELS " ' num2str(numScans)];
outC{1} = str;



for i = 1 : numScans

  %Write out "SCAN # " i
  str = ['"SCAN # "  ' num2str(i)];
  outC{end+1} = str;

  %get num segs on this scan
  numSegs = 0;
  for p = 1 : length(structS(i).segments)
    if length(structS(i).segments(p).points) ~= 0
      numSegs = numSegs + 1;
    end
  end

  if numSegs ~= 0
    %write out "NUMBER OF SEGMENTS "  numSegs
    str = ['"NUMBER OF SEGMENTS "  '  num2str(numSegs)];
    outC{end+1} = str;
    for j = 1 : numSegs

      ptsM = structS(i).segments(j).points;
      numPts = size(ptsM,1);
      %Get number of points in segment, numPts
      %write out "NUMBER OF POINTS  " numPts
      str = ['"NUMBER OF POINTS  "  ' num2str(numPts)];
      outC{end+1} = str;

      for k = 1 : numPts

        %Write x, y, z on each line
        str = [num2str(ptsM(k,1)) ', ' num2str(ptsM(k,2)) ', ' num2str(ptsM(k,3))];
        outC{end+1} = str;

      end


    end
  else
    %write out "NUMBER OF SEGMENTS " 0
    str = ['"NUMBER OF SEGMENTS " 0 '];
    outC{end+1} = str;

  end


end

%write out:
cells2file(outC,fileName)









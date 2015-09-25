function PIDM = getPID(structNum, doseSet, planC, orient, op)
%Creat a PID (projected information display).  Also referred to as a dose-projection plot.
%See
%JOD, 10 May 02.
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


global optS

indexS = planC{end};

[dosesV, volsV, xV, yV, zV] = getDVH(structNum, doseSet, planC, indexS, optS);

delta = planC{indexS.scan}.scanInfo(1).grid1Units;

switch lower(orient)

  case 'transverse'

    %Now bin for a transverse image:

    xMin = min(xV);
    yMin = min(yV);
    zMin = min(zV);

    xMax = max(xV);
    yMax = max(yV);
    zMax = max(zV);

    colIndV = round((xV - xMin)/delta + 0.50000001);
    rowIndV = round((yMax - yV)/delta + 0.50000001);

    rowSize = max(rowIndV);
    colSize = max(colIndV);

    PIDC = cell(rowSize,colSize);

    for i = 1 : length(colIndV)
      C = PIDC(rowIndV(i),colIndV(i));
      PIDC{rowIndV(i),colIndV(i)} = [C{:},dosesV(i)];
    end

end

switch lower(op)

  case 'min'

    PIDM = zeros(rowSize,colSize);
    for i = 1 : length(PIDM(:))
        V = PIDC{i};
        if ~isempty(V)
          m = min(V);
          PIDM(i) = m;
        end
    end

end





function doseM = readLeksellDoseGroupFile(filename)
%"readLeksellDoseGroupFile"
%   Reads a Leksell dose group file.  Unlike the other readLeksell<...>File
%   functions, the doseGroup file does not use decodeLeksellData, since it
%   appears to be a simple 31x31x31 matrix of single values.  These values
%   are normalized percentages of the maximum dose for each patient.  For
%   example, if the global max in the original dose matrix (the one being 
%   read with this code) is 500, then to find the Gy at each point in the
%   dose matrix, divide the matrix by 500 (giving a percentage
%   value at each point in the matrix) and multiply the matrix by the max
%   dose.  This conversion is done in the importLeksellPlan code because
%   the max dose is indeterminable at this point.
%
%JRA 6/13/05
%
%LM: KRK, 06/08/07, added comments about how to interpret the single
%                   floating point values read in by this function
%
%Usage:
%   doseM = readLeksellDoseGroupFile(filename)
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

fid = fopen(filename, 'r', 'b');

doseV = fread(fid, 'single');

fclose(fid);

doseM = reshape(doseV, [31 31 31]);

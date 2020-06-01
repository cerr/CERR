function [temp_planC] = loadPlanC_temp(fname,file)
%
%   Load and return a planC given a fullpath filename.  planC is returned as 
%   temp_planC in the case where another planC is already open. The filename can 
%   be a .mat or .mat.bz2 file. Bz2 files are extracted to a temporary .mat
%   file, loaded, and then the temporary .mat file is deleted.
%
%   18 Mar 06, KU
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


planC = [];
temp_planC  = [];


h = waitbar(100,'Loading selected study...');

bzFile = 0;

% Test for compressed file (*.gz), GNUZIP (freeware).  Code by A. Blanco.
if ~isempty(strfind(file,'.bz2'))
    bzFile = 1;
    disp(['Uncompressing file ', fname]);
    outstr = gnuCERRCompression(file, 'uncompress',tempdir);
    file = file(1:end-3);
end

disp(['Loading file ', fname]);
planC = load(file,'planC');

temp_planC = planC.planC;   %Conversion from struct created by load

%Remove unzipped file after loading.
if bzFile
    delete(file);
end

close(h)

if ~exist('planC');
    error('.mat or .mat.bz2 file does not contain a planC variable.');
    return;
end

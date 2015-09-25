function QIBFilesHelp
%"QIBFilesHelp"
%   Displays an information dialog explaining how to get and install the
%   QIB data files.
%
%JRA 10/15/04
%
%Usage:
%   function QIBFilesHelp
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

hC = {'The QIB algorithm in CERR''s IMRT Calculation secton requires four',...
      'large files that are not distributed in the default package.  This',...
      'is done to keep downloads small for users who do not require these',...
      'files.  To get the QIB matrices, go to:',...
      '',...
      'http://radium.wustl.edu/CERR/QIB.php',...
      '',...
      'and download the zip file located there. Extract the files contained',...
      'in the archive to the ..\IMRTP\QIBData directory.'};

h = helpdlg(hC,'How to get QIB Files...');

try
    global stateS
    stateS.handle.QIBFilesHelp = h;
end

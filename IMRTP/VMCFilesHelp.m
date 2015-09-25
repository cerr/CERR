function VMCFilesHelp
%"VMCFilesHelp"
%   Displays an information dialog explaining how to get and install the
%   VMC executables.
%
%JRA 10/15/04
%
%Usage:
%   function VMCFilesHelp
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

hC = {'The VMC++ algorithm in CERR''s IMRT Calculation secton requires an',...
      'executable that is not distributed in the default package.  This',...
      'executable should be acquired from Iwan Kawrakow <iwan@irs.phy.nrc.ca>',...
      'of the Institute for National Measurement Standards in Canada.',...
      '',...
      'Extract the VMC package to the ..\IMRTP\vmc++ directory',...
      'to use it with CERR.'};

h = helpdlg(hC,'How to get VMC Files...');

try
    global stateS
    stateS.handle.VMCFilesHelp = h;
end

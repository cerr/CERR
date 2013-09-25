function hMenu = putHelpMenu(hParent)
%Function to set CERR Help menu.
%JRA
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
global stateS

%Necessary for compiled version:
if ~exist('planC')
    planC = [];
end

%position of menu
IMRTPdir = fileparts(which('IMRTP'));
if ~isempty(IMRTPdir)
    pos = 8;  %position of menu
else
    pos = 7;  %position of menu
end

BMfileFlag = exist('Benchmark','dir');
if BMfileFlag
    pos = pos + 1;
end

try
    ishandle(stateS.handle.CERRHelpMenu);
    hMenu = stateS.handle.CERRHelpMenu;
    pos = get(stateS.handle.CERRHelpMenu,'Position');
    delete(hMenu);  %get rid of old menu
end

hMenu = uimenu(hParent, 'label', '&Help');

if pos ~=0
    set(hMenu,'Position',pos)
end

stateS.handle.CERRHelpMenu = hMenu;
if ~isempty(IMRTPdir)
    uimenu(hMenu,'label','Help getting QIB files','callback',['QIBFilesHelp']);
    uimenu(hMenu,'label','Help getting VMC++ files','callback',['VMCFilesHelp']);
end
uimenu(hMenu,'label','dicomrt-toolbox','callback','sliceCallBack(''ABOUTDICOMRT'');','Separator','on');
uimenu(hMenu,'label','CERR Command Line Help','callback','runCERRCommand(''help'')', 'Separator', 'on');
uimenu(hMenu,'label','CERR KeyBoard ShortCut Help','callback','runCERRCommand(''keyboard'')', 'Separator', 'off');
uimenu(hMenu,'label','About CERR','callback',['sliceCallBack(''aboutCERR'');'], 'Separator', 'on');
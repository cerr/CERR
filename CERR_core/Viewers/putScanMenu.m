function hScanMenu = putScanMenu(hParent, planC, indexS)
%"putScanMenu"
%   Function to set scan selection menu on the axial viewer.
%   Code reused from putDoseMenu.
%
%   JRA 11/17/04
%
%Usage:
%   function hMenu = putScanMenu(hParent, planC, indexS)
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
    pos = 6;  %position of menu
else
    pos = 5;  %position of menu
end

if isfield(stateS, 'handle') && isfield(stateS.handle, 'CERRScanMenu') && ishandle(stateS.handle.CERRScanMenu);
    hScanMenu = stateS.handle.CERRScanMenu;
else
    hScanMenu = uimenu(stateS.handle.CERRSliceViewer, 'label', '&Scan', 'callback', 'putScanMenu;', 'Interruptible', 'off');
    stateS.handle.CERRScanMenu = hScanMenu;
    uimenu(hScanMenu, 'label', 'Scan Management', 'callback','scanManagementGui','interruptible','on');
    
    % Haralick Texture Calculation
    uimenu(hScanMenu, 'label', 'Texture Browser (beta)', 'callback','textureGui','interruptible','on');

    %Starts image fusion controls.
    uimenu(hScanMenu, 'label', 'Image Fusion', 'callback','controlFrame(''fusion'', ''init'');','interruptible','on');
    uimenu(hScanMenu, 'label', 'Append scan', 'callback','scanSummationMenu','interruptible','on', 'tag', 'scanSummation');
    
    %Annotation selection
    uimenu(hScanMenu, 'label', 'Significant Images', 'callback','controlFrame(''ANNOTATION'', ''init'');','interruptible','on');
    
end

if isempty(planC)
    set(hScanMenu, 'visible', 'off');
    return;
else
    set(hScanMenu, 'visible', 'on');
end
indexS = planC{end};

%Find and remove old dose listings.
kids = get(hScanMenu, 'children');
numOldMenus = length(kids);
delete(kids(1:numOldMenus-5));

% Add scan items to menu
topMenuFlag = 1;
addScansToMenu(hScanMenu,topMenuFlag)

%Get list of dose distributions
%numScans = length(planC{indexS.scan});

%Add current scan elements to menu.
% for i = 1 : numScans
%     str = [num2str(i) '.  ' planC{indexS.scan}(i).scanType];
%     str2 = num2str(i);
%     checked = 'off';
%     try
%         if i==stateS.scanSet
%             checked = 'on';
%         else
%             checked = 'off';
%         end
%     end
%     if (i==1)
%         uimenu(hScanMenu, 'label', str, 'callback',['sliceCallBack(''selectScan'',''', str2 ,''')'],'interruptible','on','separator','on', 'Checked', checked);
%     else
%         uimenu(hScanMenu, 'label', str, 'callback',['sliceCallBack(''selectScan'',''', str2 ,''')'],'interruptible','on', 'Checked', checked);
%     end
% end

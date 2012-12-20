function hDoseMenu = putDoseMenu(hParent)
%Function to set dose selection menu on the axial viewer.
%JOD
%Latest modifications:  JOD, 23 Feb 03, can now be called & updated from other functions.
%                       JOD, 26 Feb 03, retain original position of menu.
%                       JRA, 23 May 03, added dose subtraction menu, and bar between it and doses.
%                       JRA, 09 Jun 03, made menu self updating.
%                        DK, 15 Dec 05, added dose addition menu.
%
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
pos = 3;  %position of menu

%Create new menu if necessary.
if isfield(stateS, 'handle') & isfield(stateS.handle, 'CERRDoseMenu') & ishandle(stateS.handle.CERRDoseMenu);
    hDoseMenu = stateS.handle.CERRDoseMenu;
else
    hDoseMenu = uimenu(stateS.handle.CERRSliceViewer, 'label', '&Dose', 'callback', 'putDoseMenu;', 'Interruptible', 'off');
    stateS.handle.CERRDoseMenu = hDoseMenu;
    uimenu(hDoseMenu, 'label', 'Dose Management', 'callback',['doseManagementGui'],'interruptible','on');
    %uimenu(hDoseMenu, 'label', 'Dose Subtraction', 'callback',['doseSubtractionMenu'],'interruptible','on');
    %Separate Addition and Subtraction
    %uimenu(hDoseMenu, 'label', 'Add / Subtract', 'callback','doseAddSubtractMenu','interruptible','on');
    %KU change
    %uimenu(hDoseMenu, 'label', 'Dose Subtraction', 'callback',['doseSubtractionMenu'],'interruptible','on', 'tag', 'doseSubtraction');
    uimenu(hDoseMenu, 'label', 'Add/Subtract/Reassign', 'callback',['doseSummationMenu'],'interruptible','on', 'tag', 'doseSummation');
    
%     hDAnalysis = uimenu(hDoseMenu, 'label', '&Gamma Analyasis', 'callback', ' ', 'interruptible','on');
%     uimenu(hDAnalysis,'label','&Gamma 2D','callback','CERRGammafnc(''INIT2D'')','interruptible','on');

    uimenu(hDoseMenu,'label','Gamma 3D','callback','CERRGammafnc(''INIT3D'')','interruptible','on');

    % uimenu(hDAnalysis,'label','&Gamma 3D','callback','RPCCallBack(''GETGAMMAINPUT'',''3D'')','interruptible','on');
end

if isempty(planC)
    set(hDoseMenu, 'visible', 'off');
    return;
else
    set(hDoseMenu, 'visible', 'on');
end
indexS = planC{end};

%Find and remove old dose listings.
kids = get(hDoseMenu, 'children');
numOldMenus = length(kids);
delete(kids(1:numOldMenus-3));%2 is the number of items to be displayed on the dropdown menu

%Get list of dose distributions
numDoses = length(planC{indexS.dose});

dosesToShow = 25;

%Add current dose elements to menu.
for i = 1 : min(numDoses,dosesToShow)
    str = [num2str(i) '.  ' planC{indexS.dose}(i).fractionGroupID];
    str2 = num2str(i);
    checked = 'off';
    try
        if i==stateS.doseSet
            checked = 'on';
        else
            checked = 'off';
        end
    end
    if (i==1)
        uimenu(hDoseMenu, 'label', str, 'callback',['sliceCallBack(''selectDose'',''', str2 ,''')'],'interruptible','on','separator','on', 'Checked', checked);
    else
        uimenu(hDoseMenu, 'label', str, 'callback',['sliceCallBack(''selectDose'',''', str2 ,''')'],'interruptible','on', 'Checked', checked);
    end
end

if numDoses > dosesToShow
    uimenu(hDoseMenu, 'label', 'More Doses...', 'callback','sliceCallBack(''selectDoseMore'')','interruptible','on','separator','on');
end

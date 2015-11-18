function hStructMenu = putStructMenu(hParent)
%"putStructMenu"
%   Add structure menu to CERR slice viewer, or update the existing structure menu.
%   Uses a self-updating callback.
%
%LM:  5 Apr 02, JOD. Creation.
%    26 Mar 04, JRA, self-updating callback, added struct toggling.
%
%Usage:
%   function hStructMenu = putStructMenu()
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

structuresC = {};

IMRTPdir = fileparts(which('IMRTP'));
if ~isempty(IMRTPdir)
    pos = 7;  %position of menu
else
    pos = 6;  %position of menu
end

%Create new menu if necessary.
if isfield(stateS, 'handle') && isfield(stateS.handle, 'CERRStructMenu') && ishandle(stateS.handle.CERRStructMenu)
    hStructMenu = stateS.handle.CERRStructMenu;
else
    hStructMenu = uimenu(stateS.handle.CERRSliceViewer, 'label', '&Structures', 'callback', 'putStructMenu;', 'Interruptible', 'off');
    stateS.handle.CERRStructMenu = hStructMenu;

    %First time for menu, add permenant ui submenus.
    %Call up Mesh-representation GUI
    %uimenu(hStructMenu, 'label', 'Mesh Representation', 'callback','selectStructsToMeshGUI(''init'')','interruptible','on');
    
    %Call up editStructures
    uimenu(hStructMenu, 'label', 'Contouring', 'callback',['sliceCallBack(''contourMode'')'],'interruptible','on', 'separator', 'on');

    %Call up editStructures
    %     uimenu(hStructMenu, 'label', 'Add/Edit structures', 'callback',['editStructFields'],'interruptible','on');

    %One element for structure fusion.
    uimenu(hStructMenu, 'label', 'Derive new structure', 'callback',['sliceCallBack(''structurefusion'')'],'interruptible','on');

    %One element for copying structure from one scan to another
    uimenu(hStructMenu, 'label', 'Copy from one scan to other', 'callback',['sliceCallBack(''copyStr'')'],'interruptible','on');

    %One element for structure consensus
    uimenu(hStructMenu, 'label', 'Consensus', 'callback',['sliceCallBack(''structConsensus'')'],'interruptible','on');

    %Turn all structs on
    uimenu(hStructMenu, 'label', 'View all structures', 'callback', ['sliceCallBack(''ViewAllStructures'')'], 'interruptible', 'on', 'separator', 'on');

    uimenu(hStructMenu, 'label', 'View no structures', 'callback', ['sliceCallBack(''ViewNoStructures'')'], 'interruptible', 'on');
end

if isempty(planC)
    set(hStructMenu, 'visible', 'off');
    return;
else
    set(hStructMenu, 'visible', 'on');
end
indexS = planC{end};

numStructs = length(planC{indexS.structures});

%Init structure visible list.
if ~isfield(planC{indexS.structures}, 'visible') & length(planC{indexS.structures}) ~= 0
    [planC{indexS.structures}.visible] = deal(1);
end

%Build list of structure names.
if numStructs > 0
    [structuresC{1:numStructs}] = deal(planC{indexS.structures}.structureName);
end

%Find and remove old structure listings.
kids = get(hStructMenu, 'children');
numOldMenus = length(kids);
delete(kids(1:numOldMenus-6));

[assocScansV, relStructNum] = getStructureAssociatedScan(1:numStructs, planC);
allScans = unique(assocScansV);
for i = 1:length(allScans)
    strSep = 'off';
    if i == 1
        strSep = 'on';
    end

    hStrSetPannel(i)= uimenu(hStructMenu, 'label', ['Structure Set ' num2str(allScans(i))], 'callback','','interruptible','on', 'Separator', strSep);

    scanIndxV = find(assocScansV == allScans(i));

    uimenu(hStrSetPannel(i), 'label', ['Associated Scan Set: ' num2str(allScans(i))],'interruptible', 'off','Enable','off');
    
    %Reassign color
    uimenu(hStrSetPannel(i), 'label', 'Reassign Color', 'callback',['structColorGUI(''init'',''' num2str(allScans(i)) ''')'], 'interruptible', 'on','Separator','on');
    
    %Turn all structs on
    uimenu(hStrSetPannel(i), 'label', ['Turn ON Set ' num2str(allScans(i))], 'callback',['sliceCallBack(''ViewAllStructures'',''' num2str(allScans(i)) ''')'], 'interruptible', 'on','Separator','on');

    uimenu(hStrSetPannel(i), 'label', ['Turn OFF Set ' num2str(allScans(i))], 'callback',['sliceCallBack(''ViewNoStructures'',''' num2str(allScans(i)) ''')'], 'interruptible', 'on');

    maxStructToShow = 25;
    numStructs = length(scanIndxV);
    for j = 1:min(numStructs,maxStructToShow)
        %Populate with new structure menu items.
        
        sep = 'off';
        checked = 'off';

        str = [num2str(scanIndxV(j)) '.  ' structuresC{scanIndxV(j)}];

        %Seperator if 1st structure.
        if j == 1
            sep = 'on';
        end

        %Checkmark if visible.
        if planC{indexS.structures}(scanIndxV(j)).visible
            checked = 'on';
        end

        %Create actual menu element(s).
        uimenu(hStrSetPannel(i), 'label', str, 'callback',['sliceCallBack(''toggleSingleStruct'',''', num2str(scanIndxV(j)),''')'],...
            'interruptible','on','tag','struct menu', 'Separator', sep, 'Checked', checked);
    end

    if numStructs > maxStructToShow
        uimenu(hStrSetPannel(i), 'label', 'More Structures...', 'callback',['sliceCallBack(''selectStructMore'',',num2str(allScans(i)),')'],...
            'interruptible','on','tag','struct menu', 'Separator', sep, 'Checked', checked);
    end
    
    
end
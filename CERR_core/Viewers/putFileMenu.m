function hMenu = putFileMenu(hParent);
%Function to set CERR File menu.
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

pos = 1;  %position of menu

%Create new menu if necessary.
if isfield(stateS, 'handle') & isfield(stateS.handle, 'CERRFileMenu') & ishandle(stateS.handle.CERRFileMenu);
    hMenu = stateS.handle.CERRFileMenu;
else    
    hMenu = uimenu(stateS.handle.CERRSliceViewer, 'label', '&File', 'callback', 'putFileMenu;', 'Interruptible', 'off');
    stateS.handle.CERRFileMenu = hMenu;
    
    uimenu(hMenu, 'label', '&Open...', 'callback','sliceCallBack(''openNewPlanC'')','interruptible','on');
    uimenu(hMenu, 'label', '&Workspace planC', 'callback','sliceCallBack(''openWorkspacePlanC'')','interruptible','on', 'tag', 'WorkspaceLoadOption');
    uimenu(hMenu, 'label', '&Anonymize...', 'callback','anonymize_script','interruptible','on', 'tag', 'AnonymizeOption', 'Separator', 'on');
    uimenu(hMenu, 'label', '&Save', 'callback',['sliceCallBack(''saveplanc'');'],'interruptible','on', 'tag', 'SaveOption', 'Separator', 'on');
    uimenu(hMenu, 'label', 'Save &As...', 'callback',['sliceCallBack(''saveasplanc'');'],'interruptible','on', 'tag', 'SaveAsOption');
    
    hMerge  = uimenu(hMenu, 'label', '&Merge Plans', 'callback',['sliceCallBack(''mergePlans'');'], 'interruptible','on', 'Separator', 'on', 'tag', 'Merge');       

    hInsert = uimenu(hMenu, 'label', '&Insert CERR...','interruptible','on', 'Separator', 'on', 'tag', 'insertPlan');
    uimenu(hInsert, 'label', '&plan(s) from another study', 'interruptible','on', 'callback', 'insertPlan');
    uimenu(hInsert, 'label', '&structure(s) from another study', 'interruptible','on', 'callback', 'insertStructs');
    uimenu(hInsert, 'label', '&scan set from another study', 'interruptible','on', 'callback', 'insertScanSet');
    
    hDCMInsert = uimenu(hMenu, 'label', '&Insert DICOM...','interruptible','on', 'Separator', 'on', 'tag', 'insertDCMPlan');
    uimenu(hDCMInsert, 'label', '&Dose from another study', 'interruptible','on', 'callback', 'insertDCMDose');
    uimenu(hDCMInsert, 'label', '&Structures from another study', 'interruptible','on', 'callback', 'insertDCMStruct');

    hImport = uimenu(hMenu, 'label', '&Import...','interruptible','on', 'Separator', 'on', 'tag', 'importPlan');
    hImportRTOG = uimenu(hImport, 'label', '&RTOG','interruptible','on');
    uimenu(hImportRTOG, 'label', '&Create new study', 'interruptible','on', 'callback', 'CERRImport');
    uimenu(hImportRTOG, 'label', '&Add new plan(s) to current study', 'interruptible','on', 'callback', 'CERRImport_newplan', 'tag', 'addRTOGPlan');
    hImportDICOM = uimenu(hImport, 'label', '&DICOM','interruptible','on', 'Separator', 'on');
    uimenu(hImportDICOM, 'label', '&Create new study', 'interruptible','on', 'callback', 'CERRImportDCM4CHE');
    uimenu(hImportDICOM, 'label', '&Add new plan(s) to current study', 'interruptible','on', 'callback', 'CERRImportDICOM_newplan', 'tag', 'addPlan'); 
    uimenu(hImportDICOM, 'label', '&Add DICOM imaging to current study', 'interruptible','on', 'callback', 'CERRImportDICOM_newScan', 'tag', 'addScan');
    uimenu(hImport, 'label', '&PLUNC','interruptible','on', 'callback', 'CERRImportPLUNC', 'Separator', 'on');
    uimenu(hImport, 'label', '&Gamma Knife','interruptible','on', 'callback', 'CERRImportGammaKnife', 'Separator', 'on');
    
    hPrint = uimenu(hMenu, 'label', '&Print Screen...','callback', 'printScreen','interruptible','on', 'Separator', 'on');
end

if pos ~=0
  set(hMenu,'Position',pos)
end

toHide = [findobj(hMenu, 'tag', 'SaveOption'), findobj(hMenu, 'tag', 'SaveAsOption'), findobj(hMenu, 'tag', 'AnonymizeOption'),findobj(hMenu, 'tag', 'addPlan'), findobj(hMenu, 'tag', 'addRTOGPlan'), findobj(hMenu, 'tag', 'addScan'), findobj(hMenu, 'tag', 'insertPlan'), findobj(hMenu, 'tag', 'Merge'), findobj(hMenu, 'tag', 'insertDCMPlan')];
if stateS.planLoaded
   set(toHide, 'enable', 'on') 
else
   set(toHide, 'enable', 'off')     
end

if stateS.imageRegistration
   set(findobj('tag', 'insertPlan'), 'enable', 'off'); 
   set(findobj('tag', 'importPlan'), 'enable', 'off');
else
   set(findobj('tag', 'importPlan'), 'enable', 'on'); 
end

if stateS.workspacePlan & stateS.planLoaded
    set(findobj(hMenu, 'tag', 'SaveOption'), 'enable', 'off');
    set(findobj(hMenu, 'tag', 'AnonymizeOption'), 'enable', 'off');
elseif ~stateS.workspacePlan & stateS.planLoaded
    set(findobj(hMenu, 'tag', 'SaveOption'), 'enable', 'on');
    set(findobj(hMenu, 'tag', 'AnonymizeOption'), 'enable', 'on');
end

if ~stateS.planLoaded & ~isempty(planC) & iscell(planC)
    set(findobj('tag', 'WorkspaceLoadOption'), 'enable', 'on'); 
else
    set(findobj('tag', 'WorkspaceLoadOption'), 'enable', 'off');
end

try
    planHistory = stateS.planHistory;
catch
    planHistory = cell(0);
end

delete(findobj(hMenu, 'tag', 'planHistoryItem'));
for i=1:length(planHistory)
    if i==1
        separator = 'on';
    else
        separator = 'off';
    end
    if exist(planHistory{i}, 'file');
        enableFile = 'on';
    else
        enableFile = 'off';    
    end
    uimenu(hMenu, 'label', ['&' num2str(i) ' ' planHistory{i}], 'callback', ['sliceCallBack(''OPENNEWPLANC'', ''' planHistory{i} ''');'], 'tag', 'planHistoryItem', 'separator', separator, 'enable', enableFile);
end

uimenu(hMenu, 'label', 'E&xit', 'callback', 'sliceCallBack(''closerequest'');', 'separator', 'on', 'tag', 'planHistoryItem');

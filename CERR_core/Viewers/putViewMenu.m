function hMenu = putViewMenu(hParent)
%Function to set CERR View menu.
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
if ~exist('planC','var')
    planC = [];
end

pos = 2;  %position of menu               

%Create new menu if necessary.
if isfield(stateS, 'handle') & isfield(stateS.handle, 'CERRViewMenu') & ishandle(stateS.handle.CERRViewMenu);
    hMenu = stateS.handle.CERRViewMenu;
else    
    %Create root menu.
    hMenu = uimenu(stateS.handle.CERRSliceViewer, 'label', '&View', 'callback', 'putViewMenu;', 'Interruptible', 'off');
    stateS.handle.CERRViewMenu = hMenu;
    
    %Create Scan/Structure/Dose Toggles.
    uimenu(hMenu, 'label', 'Scan', 'callback','sliceCallBack(''CTToggle'');','interruptible','on', 'checked', 'on', 'tag', 'scanToggle');
    uimenu(hMenu, 'label', 'Structures', 'callback','sliceCallBack(''structToggle'');','interruptible','on', 'checked', 'on',  'tag', 'structToggle');
    uimenu(hMenu, 'label', 'Dose', 'callback','sliceCallBack(''doseToggle'');','interruptible','on', 'checked', 'on',  'tag', 'doseToggle');
    
    %Create 3D dose browser menu
    uimenu(hMenu, 'label', '3D Dose Browser', 'callback','doseViewer3D(''init'');','interruptible','on', 'checked', 'off', 'Separator', 'on',  'tag', 'dose3Dbrowser');
    
    %Create layout and layout children.
    hPanel = uimenu(hMenu, 'label', 'Panel Layout', 'callback','','interruptible','on', 'Separator', 'on');
    uimenu(hPanel, 'label', '1 large', 'callback', 'sliceCallBack(''layout'', 1)');
    uimenu(hPanel, 'label', '1 large + bar', 'callback', 'sliceCallBack(''layout'', 2)');
    uimenu(hPanel, 'label', '2 medium', 'callback', 'sliceCallBack(''layout'', 3)');
    uimenu(hPanel, 'label', '4 medium', 'callback', 'sliceCallBack(''layout'', 4)');
    uimenu(hPanel, 'label', '1 large 3 small', 'callback', 'sliceCallBack(''layout'', 5)');
    
    
    % Create comparison layout for scans
    uimenu(hPanel,'label','Scan Compare','callback','scanCompare(''init'')','tag','scanCompareMenu');

    % Create comparison layout for dose comparison
    uimenu(hPanel, 'label', 'Dose Comparison', 'callback', 'doseCompare(''init'')','tag','doseCompareMenu');

    % Create comparison layout for dose comparison
    uimenu(hPanel, 'label', 'Perfusion / Diffusion', 'callback', 'sliceCallBack(''layout'', 9)','tag','perfDiffusionMenu');

    %Create plan data menu item.
    hPlan = uimenu(hMenu, 'label', 'Plan Data','interruptible','on', 'Separator', 'on', 'tag', 'planData');
    uimenu(hPlan, 'label', 'Current Plan','callback', 'viewPlanData','interruptible','on');
    
    %Create import log menu item.
    hLogMenu = uimenu(hMenu, 'label', 'Import Log...','callback', 'viewImportLog','interruptible','on', 'Separator', 'on', 'tag', 'importLog');

    %Create Colorbar options selector.
    uimenu(hMenu, 'label', 'Colorbar Options...', 'callback','controlFrame(''colorbar'', ''init'');','interruptible','on', 'checked', 'off', 'Separator', 'on', 'tag', 'colorbarOptions');
    
    %Create Isodose Line options selector.
    uimenu(hMenu, 'label', 'Isodose Line Options...', 'callback','controlFrame(''isodose'', ''init'');','interruptible','on', 'checked', 'off', 'Separator', 'off', 'tag', 'isodoseOptions'); 
    
    %Create isodose Toggle
    uimenu(hMenu, 'label', 'Toggle Isodose/Colorwash', 'callback','sliceCallBack(''isodoseToggle'');','interruptible','on', 'checked', 'off', 'Separator', 'on', 'tag', 'isodoseToggle');

    %Plane locator toggle
    uimenu(hMenu, 'label', 'Toggle plane locators', 'callback','sliceCallBack(''planeLocatorToggle'');','interruptible','on', 'checked', 'off', 'Separator', 'off', 'tag', 'planeLocatorToggle');

    %Navigation montage toggle
    uimenu(hMenu, 'label', 'Toggle navigation montage', 'callback','sliceCallBack(''navMontageToggle'');','interruptible','on', 'checked', 'off', 'Separator', 'off', 'tag', 'navMontageToggle');

end

if pos ~=0
    set(hMenu,'Position',pos)
end

toHide = [findobj(hMenu, 'tag', 'scanToggle'), findobj(hMenu, 'tag', 'doseToggle'), findobj(hMenu, 'tag', 'structToggle'), findobj(hMenu, 'tag', 'isodoseToggle'), findobj(hMenu, 'tag', 'planeLocatorToggle'), findobj(hMenu, 'tag', 'navMontageToggle'), findobj('tag', 'colorbarOptions'), findobj('tag', 'isodoseOptions'), findobj('tag', 'planData'), findobj('tag', 'importLog')];
if stateS.planLoaded
   set(toHide, 'enable', 'on') 
else
   set(toHide, 'enable', 'off')     
end

toDisable = [findobj(hMenu, 'tag', 'isodoseToggle'), findobj('tag', 'colorbarOptions'), findobj('tag', 'isodoseOptions'), findobj('tag', 'planData')];
if stateS.planLoaded && isempty(planC{planC{end}.dose})
   set(toDisable, 'enable', 'off')     
end

function hMenu = putMetricsMenu(hParent)
%Function to set metric selection menu on the axial viewer.
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
    pos = 5;  %position of menu
else
    pos = 4;  %position of menu
end

try
  ishandle(stateS.handle.CERRMetricMenu);
  hMenu = stateS.handle.CERRMetricMenu;
  pos = get(stateS.handle.CERRMetricMenu,'Position');
  delete(hMenu);  %get rid of old menu
end

hMenu = uimenu(hParent, 'label', '&Metrics');

if pos ~=0
  set(hMenu,'Position',pos)
end

stateS.handle.CERRMetricMenu = hMenu;

if isempty(planC)
    set(hMenu, 'visible', 'off');
    return;
else
    set(hMenu, 'visible', 'on');
end
indexS = planC{end};

uimenu(hMenu, 'label', 'Dose Volume Histogram', 'callback',['showDVHGui(''init'')'],'interruptible','on');

uimenu(hMenu, 'label', 'Dose Location Histogram', 'callback',['DLHGui(''init'')'],'interruptible','on');

uimenu(hMenu, 'label', 'Metric Comparison', 'callback',['metricSelection(''init'')'],'interruptible','on');

uimenu(hMenu, 'label', 'Dose Projections','interruptible','on', 'callback',['sliceCallBack(''doseShadow'')']);

uimenu(hMenu, 'label', 'Intensity Volume Histogram', 'callback',['showIVHGui(''init'')'],'interruptible','on');

uimenu(hMenu, 'label', 'NTCP Modeling', 'callback',['ntcpGUI(''init'')'],'interruptible','on');

uimenu(hMenu, 'label', 'Plan Robustness Analysis', 'callback',['DVHRobustnessGUI(''init'')'],'interruptible','on');

uimenu(hMenu, 'label', 'gEUD Contribution Modeling', 'callback',['gEUDgUI(''init'')'],'interruptible','on');


% for i=1:length(planC{indexS.structures})
%     uimenu(hShadow, 'label', planC{indexS.structures}(i).structureName, 'callback',['sliceCallBack(''doseShadow'',' num2str(i) ')'],'interruptible','on');
% end
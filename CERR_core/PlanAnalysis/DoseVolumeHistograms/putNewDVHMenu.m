function putNewDVHMenu(planC)
%Make new listing of all the contoured structures which could be listed as DVHs.
%This menu appears on the DVH listing figure.
%LM:  2 Nov 02, JOD.
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

global stateS

indexS = planC{end};

%Get the figure handle
hParent = [];
try
  hParent = stateS.handle.DVHMenu;
end
if isempty(hParent)
  return
end

hMenu = [];
try
  %Get the menu handle
  hMenu = stateS.handle.DVHMenuPullDown;
  delete(hMenu)
end

hMenu = uimenu(hParent,'label','Add DVH');
stateS.handle.DVHMenuPullDown = hMenu;

%Get list of structures
numStructs = length(planC{indexS.structures});

try
  hV = stateS.handle.DVHMenuPullItems;
  delete(hV)  %get rid of old menu items
end

hV = [];
for i = 1 : numStructs
  str = [num2str(i) '.  ' planC{indexS.structures}(i).structureName];
  str2 = num2str(i);
  h = uimenu(hMenu, 'label', str, 'callback',['DVHCallBack(''selectstruct'',''', str2 ,''')'],...
        'interruptible','on');
  hV = [hV, h];
end

stateS.handle.DVHMenuPullItems = hV;

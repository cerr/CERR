function hIMRTPMenu = putIMRTPMenu(hParent)
%"putIMRTPMenu"
%   Function to set IMRTP selection menu on the axial viewer.
%   Self updating.
%
%JRA 5/16/04
%
%Usage:
%   function hMenu = putIMRTPMenu(hParent, planC, indexS)
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

pos = 4;  %position of menu

%Create new menu if necessary.
if isfield(stateS, 'handle') & isfield(stateS.handle, 'CERRIMRTPMenu') & ishandle(stateS.handle.CERRIMRTPMenu);
    hIMRTPMenu = stateS.handle.CERRIMRTPMenu;
else    
    hIMRTPMenu = uimenu(stateS.handle.CERRSliceViewer, 'label', '&IMRT', 'callback', 'putIMRTPMenu;', 'Interruptible', 'off');
    stateS.handle.CERRIMRTPMenu = hIMRTPMenu;
    uimenu(hIMRTPMenu, 'label', 'IMRTP Creation', 'callback',['sliceCallBack(''selectIMRTP'',''', '0' ,''')'],'interruptible','on');
end

%Find and remove old IMRT listings.
kids = get(hIMRTPMenu, 'children');
numOldMenus = length(kids);
delete(kids(1:numOldMenus-1));

if pos ~=0
  set(hIMRTPMenu,'Position',pos)
end

if isempty(planC)
    set(hIMRTPMenu, 'visible', 'off');
    return;
else
    set(hIMRTPMenu, 'visible', 'on');
end
indexS = planC{end};

%Get list of IMRTP distributions
try
    numIMRTPs = length(planC{indexS.IM});
catch
    numIMRTPs = 0;
    return;
end

%Remove null IMRTPs
toRemove = [];
for i = 1:numIMRTPs
   if isempty(planC{indexS.IM}(i).IMDosimetry)
        toRemove = [toRemove i];
   end
end
planC{indexS.IM}(toRemove) = [];

numIMRTPs = length(planC{indexS.IM});
for i = 1 : numIMRTPs
%   if isempty(planC{indexS.IM}(i).IMDosimetry)
%     calcString = 'Not calculated';
%  else
%     calcString = 'Calculated';   
%   end
%   str = [num2str(i) '. ' calcString];
  str = [num2str(i) '. ' planC{indexS.IM}(i).IMDosimetry.name];
  str2 = num2str(i);
  if (i==1)
    uimenu(hIMRTPMenu, 'label', str, 'callback',['sliceCallBack(''selectIMRTP'',''', str2 ,''')'],'interruptible','on','separator','on'); %JRA
  else
    uimenu(hIMRTPMenu, 'label', str, 'callback',['sliceCallBack(''selectIMRTP'',''', str2 ,''')'],'interruptible','on');
  end
end
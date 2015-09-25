function varargout = DVHCompareMenu(varargin)
%GUI to allow user to select two stored DVHs for comparison via DVHCompare.
%JRA, rewritten 06.23.03 since .fig system is not compatible with all other versions of matlab
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

global DVHCompStateS;
global planC;
indexS = planC{end};
units = 'normalized';

if nargin == 0  
    fig = figure;

    % Use system color scheme for figure:
    uicolor = get(0,'defaultUicontrolBackgroundColor');
	set(fig,'Color',uicolor);
    set(fig, 'NumberTitle', 'off');
    set(fig, 'Name', 'DVH Compare');
    set(fig, 'MenuBar', 'none');

    %Get DVH names and origin
    DVHs = {planC{indexS.DVH}.structureName};
    planOrigin = {planC{indexS.DVH}.fractionGroupID};
    for i=1:length(DVHs)
        structureAndOrigin{i} = [DVHs{i} ' -- ' planOrigin{i}];
    end
    %Make List boxes
    DVHCompStateS.handles.structureList1 = uicontrol('callback', 'DVHCompareMenu(''structureList1_Callback'');', 'units',units,'BackgroundColor',uicolor, 'Position',[.05 .1 .35 .85],'String', structureAndOrigin, 'Style','listbox','Tag','structureList1');        
    DVHCompStateS.handles.structureList2 = uicontrol('callback', 'DVHCompareMenu(''structureList2_Callback'');', 'units',units,'BackgroundColor',uicolor, 'Position',[.45 .1 .35 .85],'String', structureAndOrigin, 'Style','listbox','Tag','structureList2');            
    %Make buttons
    DVHCompStateS.handles.cancelButton = uicontrol('callback', 'DVHCompareMenu(''cancelButton_Callback'');', 'units',units,'BackgroundColor',uicolor, 'Position',[.85 .83 .13 .05],'String','Cancel', 'Style','pushbutton','Tag','cancelButton');
    DVHCompStateS.handles.compareButton = uicontrol('callback', 'DVHCompareMenu(''compareButton_Callback'');', 'units',units,'BackgroundColor',uicolor, 'Position',[.85 .9 .13 .05],'String','Compare', 'Style','pushbutton','Tag','compareButton');
    %Make text labels
    uicontrol('units',units,'BackgroundColor',uicolor, 'Position',[.405 .5 .04 .07],'String', '&', 'Style','text','Tag','andSign', 'FontSize', 20);
    uicontrol('units',units,'BackgroundColor',uicolor, 'Position',[0 0 .83 .07],'String', 'Take two precalculated DVHs and display them with the differences highlighted.', 'Style','text','Tag','descriptionText');
elseif ischar(varargin{1}) % INVOKE NAMED SUBFUNCTION OR CALLBACK
	try
		if (nargout)
			[varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
		else
			feval(varargin{:}); % FEVAL switchyard
		end
	catch
		disp(lasterr);
	end

end   

% --------------------------------------------------------------------
function varargout = structureList1_Callback()
return;

% --------------------------------------------------------------------
function varargout = structureList2_Callback()
return;

% --------------------------------------------------------------------
function varargout = compareButton_Callback()

global planC;
global DVHCompStateS;
list_entries = get(DVHCompStateS.handles.structureList1,'String');
index_selected = get(DVHCompStateS.handles.structureList1,'Value');
if length(index_selected) ~= 1
	errordlg('You must select two variables','Incorrect Selection','modal')
else
	firstDVHIndex = index_selected(1);
end  

list_entries = get(DVHCompStateS.handles.structureList2,'String');
index_selected = get(DVHCompStateS.handles.structureList2,'Value');
if length(index_selected) ~= 1
	errordlg('You must select two variables','Incorrect Selection','modal')
else
	secondDVHIndex = index_selected(1);
end  
close

DVHCompare(firstDVHIndex, secondDVHIndex);
return;

% --------------------------------------------------------------------
function varargout = cancelButton_Callback()
clear DVHCompStateS
close
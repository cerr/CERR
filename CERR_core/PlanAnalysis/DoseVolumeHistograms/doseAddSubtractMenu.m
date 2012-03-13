function varargout = doseAddSubtractMenu(command, varargin)
%"doseAddSubtractMenu"
%   Create the GUI used to subtract two doses from each other.
%
%JRA 06/23/03
%JRA 08/03/04 - Rewritten for new interpolated subtraction.
%DK  10/21/05 - Added dose addition option. Renamed file 
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
%
%Usage:
%   doseAddSubtractMenu(command, varargin)

global planC;
global stateS;
indexS = planC{end};

if nargin == 0
    command = 'init';
end

switch upper(command)
    case 'INIT'
        hFig = findobj('tag', 'CERRDoseAddSubtractFigure');
        if ~isempty(hFig)
            delete(hFig);
        end
        screenSize = get(0,'ScreenSize');        
        units = 'normalized';
        hFig = figure('Name', 'Dose Subtraction', 'doublebuffer', 'on', 'units', 'pixels', 'position',[screenSize(3)/2-200 screenSize(4)/2-133 400 266], 'MenuBar', 'none', 'NumberTitle', 'off', 'resize', 'off', 'Tag', 'CERRDoseAddSubtractFigure');    
        stateS.handle.doseSubtractionMenuFig = hFig;
        
        %Make List boxes
        ud.handles.doseList1 = uicontrol('units',units,'Position',[.05 .2 .35 .75],'String', {planC{planC{end}.dose}.fractionGroupID}, 'Style','listbox','Tag','doseList1');        
        ud.handles.doseList2 = uicontrol('units',units,'Position',[.45 .2 .35 .75],'String', {planC{planC{end}.dose}.fractionGroupID}, 'Style','listbox','Tag','doseList2');            
        
        %Make buttons
        ud.handles.addButton = uicontrol('callback', 'doseAddSubtractMenu(''ADDSUBTRACT'');', 'units',units, 'Position',[.82 .85 .17 .08],'String','Add', 'Style','pushbutton','Tag','buttonAddSubtract');
        ud.handles.compareButton = uicontrol('callback', 'doseAddSubtractMenu(''ADDSUBTRACT'');', 'units',units, 'Position',[.82 .70 .17 .08],'String','Subtract', 'Style','pushbutton','Tag','buttonAddSubtract');
        ud.handles.cancelButton = uicontrol('callback', 'doseAddSubtractMenu(''CANCEL'');', 'units',units,'Position',[.82 .55 .17 .08],'String','Cancel', 'Style','pushbutton','Tag','cancelButton');        
        set(hFig, 'userdata', ud);

    case 'ADDSUBTRACT'
        [h, hFig] = gcbo;
%         hFig = findobj('tag', 'CERRDoseAddSubtractFigure');
        ud = get(hFig, 'userdata');
		list_entries = get(ud.handles.doseList1,'String');
		index_selected = get(ud.handles.doseList1,'Value');
        command = get(h,'String');
		if length(index_selected) ~= 1
			errordlg('You must select two variables','Incorrect Selection','modal')
		else
			firstDoseIndex = index_selected(1);
		end  
		
		list_entries = get(ud.handles.doseList2,'String');
		index_selected = get(ud.handles.doseList2,'Value');
		if length(index_selected) ~= 1
			errordlg('You must select two variables','Incorrect Selection','modal')
		else
			secondDoseIndex = index_selected(1);
		end  
		
		firstDose = planC{planC{end}.dose}(firstDoseIndex);
		secondDose = planC{planC{end}.dose}(secondDoseIndex);
		delete(hFig);
        DoseAdditionSubtraction(firstDose, secondDose,command);		
        
    case 'CANCEL'
        delete(findobj('tag', 'CERRDoseAddSubtractFigure'));
end
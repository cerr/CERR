function planDBGUI(action, varargin)
% Gui to access and browse data in planDB.
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

if(nargin == 0)
    action = 'init';
end

switch upper(action)
    case 'INIT'      
		screenSize = get(0,'ScreenSize');
		y = 700; %Initial size of figure in pixels.
		x = 700;
		
		h = figure('doublebuffer', 'on', 'position', [(screenSize(3)-x)/2 (screenSize(4)-y)/2 x y], 'units', 'normalized');
        set(h, 'resizefcn', 'myResize');
		
        ud = []; %init UD.
		%Make bottom Axis, table it
		ud.handles.botAxis = axes('position', [.25 .05 .7 .4]);
   		table(ud.handles.botAxis);        
        table(ud.handles.botAxis, 'SETDBCALLBACK', 'planDBGUI(''planclicked'')');
		
        %Make top Axis, table it
		ud.handles.topAxis = axes('position', [.25 .67 .7 .28]);
  		table(ud.handles.topAxis);	
        table(ud.handles.topAxis, 'SETDBCALLBACK', 'planDBGUI(''fieldclicked'')');
        
        ud.handles.midAxis = axes('position', [.25 .55 .7 .1]);
  		table(ud.handles.midAxis);
        table(ud.handles.midAxis,'SETDBCALLBACK',  'planDBGUI(''filterclicked'')');
        
        %Init upper planDB controls
        uicontrol('style', 'frame', 'units', 'normalized', 'position', [.025 .55 .2 .4]);
        ud.handles.searchBox = uicontrol('style', 'edit', 'units', 'normalized', 'position', [.05 .875 .15 .03], 'callback', 'planDBGUI(''SEARCHENTERED'');', 'backgroundcolor', [1 1 1]);
        uicontrol('style', 'text', 'units', 'normalized', 'position', [.05 .84 .15 .03], 'string', 'Search Fieldnames');
        ud.handles.clearFieldFilter = uicontrol('style', 'pushbutton', 'string', 'Clear Search', 'units', 'normalized', 'position', [.05 .78 .15 .05], 'callback', 'planDBGUI(''clearFieldFilter'');');
        
        ud.handles.planNameSearchBox = uicontrol('style', 'edit', 'units', 'normalized', 'position', [.05 .675 .15 .03], 'callback', 'planDBGUI(''PLANNAMESEARCH'');', 'backgroundcolor', [1 1 1]);
        uicontrol('style', 'text', 'units', 'normalized', 'position', [.05 .64 .15 .03], 'string', 'Search plan names');
        ud.handles.clearPlanSearchFilter = uicontrol('style', 'pushbutton', 'string', 'Clear Search', 'units', 'normalized', 'position', [.05 .58 .15 .05], 'callback', 'planDBGUI(''clearPlanSearchFilter'');');
        

        %Initialize lower planDB controls        
        uicontrol('style', 'frame', 'units', 'normalized', 'position', [.025 .05 .2 .4]);
        uicontrol('style', 'text', 'units', 'normalized', 'position', [.05 .375 .1 .05], 'string', 'Database:', 'horizontalalignment', 'left');

        uicontrol('style', 'text', 'units', 'normalized', 'position', [.05 .265 .1 .05], 'string', '.mat files:', 'horizontalalignment', 'left');
        uicontrol('style', 'text', 'units', 'normalized', 'position', [.05 .235 .1 .05], 'string', 'plan files:', 'horizontalalignment', 'left');
        uicontrol('style', 'text', 'units', 'normalized', 'position', [.05 .205 .1 .05], 'string', 'present plans:', 'horizontalalignment', 'left');
        uicontrol('style', 'text', 'units', 'normalized', 'position', [.05 .175 .1 .05], 'string', 'num fields:', 'horizontalalignment', 'left');

        ud.handles.planNameTx = uicontrol('style', 'text', 'units', 'normalized', 'position', [.05 .355 .1 .05], 'string', '<None>', 'horizontalalignment', 'left');
        ud.handles.matFileTx = uicontrol('style', 'text', 'units', 'normalized', 'position', [.13 .265 .07 .05], 'string', '<N/A>', 'horizontalalignment', 'right');
        ud.handles.planFileTx = uicontrol('style', 'text', 'units', 'normalized', 'position', [.13 .235 .07 .05], 'string', '<N/A>', 'horizontalalignment', 'right');
        ud.handles.presPlanTx = uicontrol('style', 'text', 'units', 'normalized', 'position', [.13 .205 .07 .05], 'string', '<N/A>', 'horizontalalignment', 'right');
        ud.handles.numFieldTx = uicontrol('style', 'text', 'units', 'normalized', 'position', [.13 .175 .07 .05], 'string', '<N/A>', 'horizontalalignment', 'right');        
        
        
        ud.handles.loadDBButton = uicontrol('style', 'pushbutton', 'string', 'Load planDB', 'units', 'normalized', 'position', [.05 .075 .15 .05], 'callback', 'planDBGUI(''loadplanDB'');');
        
        if nargin == 2
            planDB = varargin{1};
            setappdata(h, 'planDB', planDB);        
        end
        set(h, 'userdata', ud);
        
    case 'LOADPLANDB'        
        planDB = [];
        ud = get(gcbf, 'userdata');
        [filename, pathname] = uigetfile('*.mat', 'Pick a .mat planDB file');
        if filename == 0
            return;
        else
            load(fullfile(pathname, filename));
        end        
        
        if exist('planDB')
            %planDB = updateplandb(planDB);
            setappdata(gcbf, 'planDB', planDB);
            ud.DB.filename = filename;
            ud.DB.path = pathname;    
            set(gcbf, 'userdata', ud);
            planDBGUI('UPDATEPLANSTATS');
            planDBGUI('SHOWALLPLANS');
            planDBGUI('SHOWALLFIELDS');            
            planDBGUI('SHOWFILTERS');
        else
            return;
        end
        
    case 'UPDATEPLANSTATS'
        planDB = getappdata(gcbf, 'planDB');
        ud = get(gcbf, 'userdata');

        set(ud.handles.planNameTx, 'String', ud.DB.filename);
        set(ud.handles.matFileTx, 'String', num2str(length(planDB.matFiles)));
        set(ud.handles.planFileTx, 'String', num2str(length(find([planDB.matFiles.isPlanC]))));
        set(ud.handles.presPlanTx, 'String', num2str(length(find([planDB.matFiles.isPlanC] & [planDB.matFiles.isPresent]))));
        set(ud.handles.numFieldTx, 'String', num2str(length(planDB.fieldIndex)));        
        set(gcbf, 'userdata', ud);
        
    case 'CLEARFIELDFILTER'
        ud = get(gcbf, 'userdata');  
        set(ud.handles.searchBox, 'string', '');
        planDBGUI('SHOWALLFIELDS');
        
    case 'SHOWALLPLANS'
        planDB = getappdata(gcbf, 'planDB');
        ud = get(gcbf, 'userdata');        
        ud.planList = [planDB.matFiles([planDB.matFiles.isPlanC]).info]; %set planlist to file info.
        set(gcbf, 'userdata', ud);
        updatePlanList(gcbf);
        numPlans = length(ud.planList);
        title(['All Plans (' num2str(numPlans) ')'], 'interpreter', 'none');
        
    case 'SHOWALLFIELDS'
        planDB = getappdata(gcbf, 'planDB');
        ud = get(gcbf, 'userdata');        
        ud.fieldStruct = searchFieldNames('.*', planDB.fieldIndex);
        set(gcbf, 'userdata', ud);        
        updateFieldList(gcbf);
        numFields = length(ud.fieldStruct);
        title(['All Fields (' num2str(numFields) ')'], 'interpreter', 'none')    
                
    case 'SHOWFILTERS'
        ud = get(gcbf, 'userdata');        
        ud.filters = struct('Filters', {}, 'fieldname', {}, 'action', {}, 'regexp', {}, 'bool', {}, 'invert', {}, 'indices', {});
        set(gcbf, 'userdata', ud);
        
    case 'SEARCHENTERED'
        planDB = getappdata(gcbf, 'planDB');
        ud = get(gcbf, 'userdata');
        searchString = get(gcbo, 'String');
        if isempty(searchString)
            planDBGUI('showallfields');
            return;
        end        
        fieldS = searchFieldNames(searchString, planDB.fieldIndex);
        ud.fieldStruct = fieldS;        
        set(gcbf, 'userdata', ud);
                
        updateFieldList(gcbf);
        
        title(['Fields matching ''' searchString ''''], 'interpreter', 'none');        

        set(gcbf, 'userdata', ud);
        
    case 'FIELDCLICKED'
        planDBGUI('newfilter', 'AND', 'exists', '0');
        
    case 'PLANCLICKED'
        ud = get(gcbf, 'userdata');
        element = table(ud.handles.botAxis, 'getcurrentelement');
        planDB = getappdata(gcbf, 'planDB');
        
        planList = ud.planList;
        name = planList(element).name;
        path = planList(element).path;        
        
        file = fullfile(path, name);
        
        CERRSliceViewer('load', file);
        
    case 'FILTERCLICKED'
        ud = get(gcbf, 'userdata');
        index = table(gca, 'getcurrentelement');
        ud.filters(index) = [];
        set(gcbf, 'userdata', ud);
        updateFilterList(gcbf);
        
    case 'NEWFILTER'
        bool = varargin{1};
        action = varargin{2};
        invert = str2num(varargin{3});
        
        ud = get(gcbf, 'userdata');
        index = table(ud.handles.topAxis, 'getcurrentelement');                
        field = ud.fieldStruct(index).fieldname;
        
        ud.filters(end+1).fieldname = field;
        ud.filters(end).bool = bool;
        ud.filters(end).action = action;
        ud.filters(end).indices = [];
        if strcmpi(action, 'contains') | strcmpi(action, 'does not contain')
            regexp = inputdlg('Regexp:','Enter a regular expression');           
        else
            regexp = {''};    
        end
        
        ud.filters(end).regexp = regexp;
        ud.filters(end).Filters = [bool ' ' field ' ' action ' ' regexp{:} '.'];
        
        set(gcbf, 'userdata', ud);
        updateFilterList(gcbf);
        
end


function hMenu = rtMenu()
%Create right click menu to be passed to table.
	h = uicontextmenu;
    
    hAnd = 	uimenu(h, 'label', 'AND this field...');
    hOr  = 	uimenu(h, 'label', 'OR this field...');
    
	uimenu(hAnd, 'label', 'contains <expression>.', 'separator', 'off', 'callback', 'planDBGUI(''newfilter'', ''AND'', ''contains'', ''0'')');
	uimenu(hAnd, 'label', 'does not contain <expression>.', 'callback', 'planDBGUI(''newfilter'', ''AND'', ''contains'', ''1'')');
	uimenu(hAnd, 'label', 'exists.', 'callback', 'planDBGUI(''newfilter'', ''AND'', ''exists'', ''0'')');
	uimenu(hAnd, 'label', 'does not exist.', 'callback', 'planDBGUI(''newfilter'', ''AND'', ''exists'', ''1'')');
	uimenu(hAnd, 'label', 'is empty.', 'callback', 'planDBGUI(''newfilter'', ''AND'', ''is empty'', ''0'')');
	uimenu(hAnd, 'label', 'is not empty.', 'callback', 'planDBGUI(''newfilter'', ''AND'', ''is empty'', ''1'')');
    
	uimenu(hOr, 'label', 'contains <expression>.', 'separator', 'off', 'callback', 'planDBGUI(''newfilter'', ''OR'', ''contains'', ''0'')');
	uimenu(hOr, 'label', 'does not contain <expression>.', 'callback', 'planDBGUI(''newfilter'', ''OR'', ''contains'', ''1'')');
	uimenu(hOr, 'label', 'exists.', 'callback', 'planDBGUI(''newfilter'', ''OR'', ''exists'', ''0'')');
	uimenu(hOr, 'label', 'does not exist.', 'callback', 'planDBGUI(''newfilter'', ''OR'', ''exists'', ''1'')');
	uimenu(hOr, 'label', 'is empty.', 'callback', 'planDBGUI(''newfilter'', ''OR'', ''is empty'', ''0'')');
	uimenu(hOr, 'label', 'is not empty.', 'callback',  'planDBGUI(''newfilter'', ''OR'', ''is empty'', ''1'')');
    hMenu = h;
    
    
function updateFieldList(hFigure)
    ud = get(hFigure, 'userdata');
    table(ud.handles.topAxis, 'data', rmfield(ud.fieldStruct, 'planIndices'));
    table(ud.handles.topAxis, 'SETRIGHTCLICKMENU', rtMenu);

function updateFilterList(hFigure)    
    ud = get(hFigure, 'userdata');
    table(ud.handles.midAxis, 'data', rmfield(ud.filters, {'fieldname', 'bool', 'action', 'regexp', 'indices', 'invert'}));
    applyFilters(hFigure);

function updatePlanList(hFigure)
    ud = get(hFigure, 'userdata');    
	table(ud.handles.botAxis);
    table( ud.handles.botAxis, 'SETDBCALLBACK', 'planDBGUI(''planclicked'')');
    table(ud.handles.botAxis, 'data', rmfield(ud.planList, {'path', 'lastMod'}));
    numPlans = length(ud.planList);
    title(['Filtered Plans (' num2str(numPlans) ')'], 'interpreter', 'none');

    
function applyFilters(hFigure)
    ud = get(hFigure, 'userdata');
    filters = ud.filters;
    if isempty(filters)
        planDBGUI('showallplans');
    else
        ud.planList = [];
        planDB = getappdata(gcbf, 'planDB');
        allFieldNames = {planDB.fieldIndex.fieldname};
        
        plans = [];
        for i=1:length(filters)                      
            if ~isempty(ud.filters(i).indices)
                indices = ud.filters(i).indices;
            else
                fIndex = find(strcmpi(allFieldNames, filters(i).fieldname));
                fieldS = planDB.fieldIndex(fIndex); 
                filters(i) = runFilter(filters(i), planDB);
            end            
            ud.filters(i).indices = filters(i).indices;
            if isempty(plans), plans = filters(i).indices;, end;
            if strcmpi(filters(i).bool, 'and')
                plans = intersect(plans, filters(i).indices);
            elseif strcmpi(filters(i).bool, 'or')
                plans = union(plans, filters(i).indices);
            end
        end
        
        fieldsToDisplay = unique({filters.fieldname});
        ud.planList = [planDB.matFiles(plans).info];
        for i=1:length(plans)
            for j=1:length(fieldsToDisplay)
                data = getFieldContents(fieldsToDisplay{j}, planDB.matFiles(plans(i)).extract);
                ud.planList(i).(['data' num2str(j)]) = data{1};
            end
        end                     
        set(hFigure, 'userdata', ud);   
        updatePlanList(hFigure);
    end
function metricSelection(keyword, varargin);
%GUI to build a planMetricS object, for passing to graphicalComparison.m
%Uses list of metrics stored in optS.planMetrics, which are the names of
%functions stored in \planMetrics, and designed for this purpose.
%JRA 06.16.03
%
%Bug Note:  If structure name selected for a metric is exactly the same as
%another structure name, the incorrect structure may be used for the
%metric.  [VHC 2/1/06]
%
%Modified:  VHC 2/1/06  Added save metric set feature.
%           VHC 2/6/06  Added criteria feature.
%                       Changed location of Output Range so it doesn't overlap.
%           VHC 2/13/06 Added report feature (not yet complete)
%
%The following function line is for compiler linking. Add functions referenced in callbacks to the list.
%#function meanDose maxDose minDose Vx Dx EUD
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


global mSState; %This is for local state info that we dont want clogging up stateS.
global planC;
global stateS;
indexS = planC{end};

uicolor              = [.9 .9 .9];
units = 'normalized';

switch lower(keyword)
    case 'init'

        %Get figure, set its size based on screen size.
        screenSize = get(0,'ScreenSize');
        h = figure('Position', [screenSize(3)/10 screenSize(4)/10 screenSize(3)/10*8 screenSize(4)/10*6]);
        stateS.handle.metricSelectionFig = h;
        set(h, 'NumberTitle', 'off');
        set(h, 'Name', 'Metric Selection');
        set(h, 'MenuBar', 'none');

        mSState = [];
        mSState.handles.figure = h;

        %Init currentMetric vars
        mSState.currentMetric = [];
        mSState.currentMetricType = [];
        mSState.currentMetricIndex = 0;
        mSState.numPlanMetrics = 0;

        %Init saved metric set var
        if ~isfield(planC{end},'metrics')
            savedMetricSetsS = struct([]); %should be empty
            savedMetricSetsNames = {};
        else
            savedMetricSetsS = planC{planC{end}.metrics}.savedMetricSets;
            savedMetricSetsNames = {savedMetricSetsS.name};
        end

        %Init List Boxes
        mSState.handles.metricList = uicontrol('callback', 'metricSelection(''metricList_Callback'');', 'Min', length(stateS.optS.planMetrics), 'Max', length(stateS.optS.planMetrics), 'units',units,'BackgroundColor',uicolor, 'Position',[.05 .5+.45/2 .2 .45/2],'String', stateS.optS.planMetrics, 'Style','listbox','Tag','metricList');
        mSState.handles.myMetricList = uicontrol('callback', 'metricSelection(''myMetricList_Callback'');', 'Min', 1, 'Max', 100, 'units',units,'BackgroundColor',uicolor, 'Position',[.3 .5 .2 .45], 'String', [], 'Style','listbox','Tag','myMetricsList');
        mSState.handles.doseList = uicontrol('Min', 0, 'Max', 100, 'units',units,'BackgroundColor', uicolor, 'Position',[.05 .13 .45 .3],'String', {planC{planC{end}.dose}.fractionGroupID}, 'Style','listbox','Tag','doseList');
        mSState.handles.metricSetList = uicontrol('callback', 'metricSelection(''metricSetList_Callback'');', 'Min', 0, 'Max', 100, 'units',units,'BackgroundColor',uicolor, 'Position',[.05 .5 .2 .45/2-.03],'String', savedMetricSetsNames, 'Style','listbox','Tag','metricSetList');
        set(mSState.handles.myMetricList, 'Value', []);
        set(mSState.handles.metricList, 'Value', 1);
        set(mSState.handles.metricSetList, 'Value', []);

        %Make frame for metric info, and add labels and text inside of it
        uicontrol('units',units,'BackgroundColor',uicolor, 'Position',[.55 .05 .4 .85],'String','frame', 'Style','frame','Tag','metricInfoFrame');
        mSState.handles.metricNameTitle = uicontrol('callback', 'metricSelection(''metricnametitle_callback'');', 'units',units,'BackgroundColor',uicolor, 'Position',[.6 .9 .3 .05],'String', '', 'Style','edit','Tag','metricNameTitle');
        mSState.handles.functionName = uicontrol('units',units,'BackgroundColor',uicolor, 'Position',[.57 .83 .35 .04],'String', 'Function callback: ', 'Style','text','Tag','functionNameText', 'horizontalalignment', 'left');
        mSState.handles.functionDesc = uicontrol('units',units,'BackgroundColor',uicolor, 'Position',[.57 .1 .35 .08],'String', 'Function description: ', 'Style','text','Tag','functionDescText', 'horizontalalignment', 'left');
        mSState.handles.parameterLabel = uicontrol('units',units,'BackgroundColor',uicolor, 'Position',[.57 .77 .1 .04],'String', 'Parameters: ', 'Style','text','Tag','functionNameText', 'horizontalalignment', 'left');
        mSState.handles.criteriaLabel = uicontrol('units',units,'BackgroundColor',uicolor, 'Position',[.57 .435 .1 .04],'String', 'Criteria: ', 'Style','text','Tag','functionNameText', 'horizontalalignment', 'left');

        %Make labels for listboxes
        uicontrol('units',units,'BackgroundColor',uicolor, 'Position',[.05 .95 .1 .03],'String', 'Available Metrics: ', 'Style','text','Tag','functionNameText', 'horizontalalignment', 'left');
        uicontrol('units',units,'BackgroundColor',uicolor, 'Position',[.3 .95 .1 .03],'String', 'Selected Metrics: ', 'Style','text','Tag','functionNameText', 'horizontalalignment', 'left');
        uicontrol('units',units,'BackgroundColor',uicolor, 'Position',[.05 .43 .11 .03],'String', 'Plans to Compare:', 'Style','text','Tag','planSelectionText', 'horizontalalignment', 'left');
        uicontrol('units',units,'BackgroundColor',uicolor, 'Position',[.05 .95-.45/2-.03 .13 .03],'String', 'Available Metric Sets:', 'Style','text','Tag','functionNameText', 'horizontalalignment', 'left');
        %uicontrol('units',units,'BackgroundColor',uicolor, 'Position',[.18 .95-.45/2-.03 .03 .03],'String', 'Load', 'Style','push','Tag','loadPush', 'horizontalalignment', 'left','callback', 'metricSelection(''metricfileselected'');');

        %make buttons for list boxes, evaluation, canceling, and saving.
        uicontrol('callback', 'metricSelection(''addMetric'');', 'units',units,'BackgroundColor',uicolor, 'Position',[.25 .75 .05 .05],'String','->', 'Style','pushbutton','Tag','metricAdd');
        uicontrol('callback', 'metricSelection(''removeMetric'');', 'units',units,'BackgroundColor',uicolor, 'Position',[.25 .70 .05 .05],'String','<-', 'Style','pushbutton','Tag','metricRemove');
        uicontrol('callback', 'metricSelection(''evaluateMetrics'');', 'units',units,'BackgroundColor',uicolor, 'Position',[.05 .04 .1 .05],'String','Evaluate', 'Style','pushbutton','Tag','evaluateMetrics');
        uicontrol('callback', 'metricSelection(''generateReport'');', 'units',units,'BackgroundColor',uicolor, 'Position',[.17 .04 .1 .05],'String','Report', 'Style','pushbutton','Tag','cancel');
        uicontrol('callback', 'metricSelection(''cancel'');', 'units',units,'BackgroundColor',uicolor, 'Position',[.29 .04 .1 .05],'String','Cancel', 'Style','pushbutton','Tag','cancel');
        uicontrol('callback', 'metricSelection(''saveMetricSet'');', 'units',units,'BackgroundColor',uicolor, 'Position',[.44 .95 .05 .05],'String','Save', 'Style','pushbutton','Tag','saveMetricSet');
        uicontrol('callback', 'metricSelection(''metricfileselected'');', 'units',units,'BackgroundColor',uicolor, 'Position',[.49 .95 .05 .05],'String','Load', 'Style','pushbutton','Tag','loadPush');
        mSState.expandesView = 0;
        return;

    case 'metriclist_callback'
        set(mSState.handles.myMetricList, 'Value', []); %unhighlight the user listbox
        set(mSState.handles.metricSetList, 'Value', []); %unhighlight the builtin set listbox
        mSState.currentMetricType = 'BuiltIn';
        mSState.currentMetricIndex = 0; %built in selected, set index to 0.
        metricSelection('builtInMetricSelected');
        if ~mSState.expandesView && strcmpi(mSState.currentMetric.name,'lkb')
            lkbExpandView('EXPANDEDVIEW')
        elseif mSState.expandesView && ~strcmpi(mSState.currentMetric.name,'lkb')
            lkbExpandView('SIMPLEVIEW')
        end
        return

    case 'mymetriclist_callback'
        set(mSState.handles.metricList, 'Value', 1); %unhighlight the builtin listbox
        set(mSState.handles.metricSetList, 'Value', []); %unhighlight the builtin set listbox
        mSState.currentMetricType = 'User';
        mSState.currentMetricIndex = get(mSState.handles.myMetricList, 'Value');
        metricSelection('usermetricselected');
        if ~mSState.expandesView && strcmpi(mSState.currentMetric.name,'lkb')
            lkbExpandView('EXPANDEDVIEW')
        elseif mSState.expandesView && ~strcmpi(mSState.currentMetric.name,'lkb')
            lkbExpandView('SIMPLEVIEW')
        end
        return

        return

    case 'metricsetlist_callback'
        set(mSState.handles.myMetricList, 'Value', []); %unhighlight the user listbox
        set(mSState.handles.metricList, 'Value', 1); %unhighlight the builtin listbox
        mSState.currentMetricType = 'BuiltInSet';
        mSState.currentMetricIndex = 0; %built in selected, set index to 0.
        metricSelection('builtInMetricSetSelected');
        return

    case 'builtinmetricselected'
        delete(findobj('tag', 'parameter')); %remove all old parameter GUI objects.
        mSState.handles.params = [];
        [planC, metric] = feval(stateS.optS.planMetrics{get(mSState.handles.metricList, 'Value')}, planC, 'getNewMetric'); %special call to get a default metric
        mSState.currentMetric = metric;
        set(mSState.handles.metricNameTitle, 'String', metric.name);
        set(mSState.handles.functionName, 'String', ['Function callback: ' func2str(metric.functionName)]);
        set(mSState.handles.functionDesc, 'String', ['Function description: ' metric.description]);
        set(mSState.handles.parameterLabel, 'String', 'Parameters: ');
        pos = get(mSState.handles.functionName,'Position');
        for i=1:length(metric.params)  %populate parameter window with all existing parameters, using passed default values
            switch metric.params(i).type
                case 'Edit'
                    mSState.handles.params = [mSState.handles.params uicontrol('callback', ['metricSelection(''parameter_callback'',' num2str(i) ');'], 'units',units,'BackgroundColor',uicolor, 'Position',[pos(1) + mod(i-1,3)*.11 .70 - mod(floor((i-1)/3), 6)*.1 .1 .04],'String', metric.params(i).value, 'Style','edit','Tag','parameter')];
                    uicontrol('units',units,'BackgroundColor',uicolor, 'Position',[pos(1) + mod(i-1,3)*.11 .74 - mod(floor((i-1)/3), 6)*.1 .1 .04],'String', metric.params(i).name, 'Style','text','Tag','parameter','horizontalalignment', 'left');
                case 'DropDown'
                    mSState.handles.params = [mSState.handles.params uicontrol('callback', ['metricSelection(''parameter_callback'',' num2str(i) ');'], 'units',units,'BackgroundColor',uicolor, 'Position',[pos(1) + mod(i-1,3)*.11 .70 - mod(floor((i-1)/3), 6)*.1 .1 .04],'String', metric.params(i).list, 'Style','popupmenu','Tag','parameter')];
                    uicontrol('units',units,'BackgroundColor',uicolor, 'Position',[pos(1) + mod(i-1,3)*.11 .74 - mod(floor((i-1)/3), 6)*.1 .1 .04],'String', metric.params(i).name, 'Style','text','Tag','parameter','horizontalalignment', 'left');
            end
        end

        %criteria
        delete(findobj('tag', 'criteria')); %remove all old criteria GUI objects.
        if ~isfield(mSState.currentMetric,'criteria') %there are no defaults for the criteria, so we'll put them in
            cS = struct();
            cS.passDirectionIndex = 1; cS.passDirectionList = {'above','below'}; cS.passValue = 0;
            cS.marginalDirectionIndex = 1; cS.marginalDirectionList = {'above','below'}; cS.marginalValue = 0;
            cS.priority = 1; cS.priorityTypeIndex = 1; cS.priorityTypeList = {'strict','fuzzy'};
            cS.passStatus = {}; %will be 'passed', 'marginal', or 'failed' for ea dose dist
            mSState.currentMetric.criteria = cS;
        else
            cS = mSState.currentMetric.criteria;
        end
        %if you change something here, then copy it to case 'usermetricselected as well.
        set(mSState.handles.criteriaLabel, 'String', 'Criteria: ');
        uicontrol('units',units,'BackgroundColor',uicolor, 'Position',[pos(1) .435-.04 .12 .04],'String', 'Pass:       Value must be ', 'Style','text','Tag','criteria', 'horizontalalignment', 'left');
        mSState.handles.criteria.passDirectionIndex = uicontrol('callback', 'metricSelection(''criteria_callback'', ''passDirectionIndex'');', 'units',units,'BackgroundColor',uicolor, 'Position',[pos(1)+.12 .435-.031 .07 .04],'String', cS.passDirectionList, 'Value', cS.passDirectionIndex, 'Style','popupmenu','Tag','criteria');
        mSState.handles.criteria.passValue = uicontrol('callback', ['metricSelection(''criteria_callback'', ''passValue'');'], 'units',units,'BackgroundColor',uicolor, 'Position',[pos(1)+.12+.07+.005 .435-.031 .1 .04],'String', cS.passValue, 'Style','edit','Tag','criteria');
        uicontrol('units',units,'BackgroundColor',uicolor, 'Position',[pos(1) .435-.095 .12 .04],'String', 'Marginal:  Value must be ', 'Style','text','Tag','criteria', 'horizontalalignment', 'left');
        mSState.handles.criteria.marginalDirectionIndex = uicontrol('callback', 'metricSelection(''criteria_callback'', ''marginalDirectionIndex'');', 'units',units,'BackgroundColor',uicolor, 'Position',[pos(1)+.12 .435-.086 .07 .04],'String', cS.marginalDirectionList, 'Value', cS.marginalDirectionIndex, 'Style','popupmenu','Tag','criteria');
        mSState.handles.criteria.marginalValue = uicontrol('callback', ['metricSelection(''criteria_callback'', ''marginalValue'');'], 'units',units,'BackgroundColor',uicolor, 'Position',[pos(1)+.12+.07+.005 .435-.086 .1 .04],'String', cS.marginalValue, 'Style','edit','Tag','criteria');
        uicontrol('units',units,'BackgroundColor',uicolor, 'Position',[pos(1) .435-.15 .055 .04],'String', 'Priority: ', 'Style','text','Tag','criteria', 'horizontalalignment', 'left');
        mSState.handles.criteria.priority = uicontrol('callback', ['metricSelection(''criteria_callback'', ''priority'');'], 'units',units,'BackgroundColor',uicolor, 'Position',[pos(1)+.060 .435-.141 .05 .04],'String', cS.priority, 'Style','edit','Tag','criteria');
        uicontrol('units',units,'BackgroundColor',uicolor, 'Position',[pos(1)+.145 .435-.15 .15 .04],'String', '1 = highest, 2 = second-highest, etc.', 'Style','text','Tag','criteria', 'horizontalalignment', 'left');
        uicontrol('units',units,'BackgroundColor',uicolor, 'Position',[pos(1) .435-.205 .1 .04],'String', 'Priority Type: ', 'Style','text','Tag','criteria', 'horizontalalignment', 'left');
        mSState.handles.criteria.priorityTypeIndex = uicontrol('callback', 'metricSelection(''criteria_callback'', ''priorityTypeIndex'');', 'units',units,'BackgroundColor',uicolor, 'Position',[pos(1)+.07 .435-.196 .07 .04],'String', cS.priorityTypeList, 'Value', cS.priorityTypeIndex, 'Style','popupmenu','Tag','criteria');

        %dont forget range dialogue, defaults again
        %         mSState.handles.range = [uicontrol('callback', ['metricSelection(''range_callback'');'], 'units',units,'BackgroundColor',uicolor, 'Position',[.57 .1 .1 .04],'String', num2str(metric.range), 'Style','edit','Tag','parameter')];
        %         uicontrol('units',units,'BackgroundColor',uicolor, 'Position', [.57 .06 .1 .04],'String', 'Output Range', 'Style','text','Tag','parameter','horizontalalignment', 'center');
        %Double clicks automatically add metric to userlist
        if strcmpi(get(mSState.handles.figure, 'SelectionType'), 'open')
            set(mSState.handles.figure, 'SelectionType', 'normal');
            metricSelection('addmetric');
        end

    case 'metricfileselected'
        delete(findobj('tag', 'parameter')); %remove all old parameter GUI objects.
        mSState.handles.params = [];
        [fname, pathname] = uigetfile({'*.xls'}, 'Select Excel file to load stored Metric');
        if isnumeric(fname) && fname == 0
            return;
        end
        file = fullfile(pathname, fname);
        [numeric,txt,rawData] = xlsread(file);
        [planC, metric] = feval(rawData{2,2}, planC, 'getNewMetric'); %special call to get a default metric
        delete(findobj('tag', 'criteria')); %remove all old criteria GUI objects.
        cS = struct();
        cS.passDirectionIndex = 1; cS.passDirectionList = {'above','below'}; cS.passValue = 0;
        cS.marginalDirectionIndex = 1; cS.marginalDirectionList = {'above','below'}; cS.marginalValue = 0;
        cS.priority = 1; cS.priorityTypeIndex = 1; cS.priorityTypeList = {'strict','fuzzy'};
        cS.passStatus = {}; %will be 'passed', 'marginal', or 'failed' for ea dose dist

        %Fill-in user defined params and criteria
        structIndex = strmatch(lower(rawData{7,2}),lower({planC{indexS.structures}.structureName}),'exact');
        switch lower(metric.name)
            case {'meandose','mindose','maxdose','stdDevDose'}
                %Set params
                metric.params(1).value = structIndex;
                if strcmpi(lower(rawData{8,2}),'no')
                    metric.params(2).value = 2;
                else
                    metric.params(2).value = 1;
                end
                critInd = 11;

            case 'vx'
                %Set params
                metric.params(1).value = structIndex;
                metric.params(2).value = rawData{8,2};
                if strcmpi(lower(rawData{9,2}),'absolute')
                    metric.params(3).value = 2;
                else
                    metric.params(3).value = 1;
                end
                if strcmpi(lower(rawData{10,2}),'no')
                    metric.params(4).value = 2;
                else
                    metric.params(4).value = 1;
                end
                critInd = 13;

            case 'dx'
                %Set params
                metric.params(1).value = structIndex;
                metric.params(2).value = rawData{8,2};
                if strcmpi(lower(rawData{9,2}),'no')
                    metric.params(3).value = 2;
                else
                    metric.params(3).value = 1;
                end
                critInd = 12;

            case 'eud'
                %Set params
                metric.params(1).value = structIndex;
                if strcmpi(lower(rawData{8,2}),'no')
                    metric.params(2).value = 2;
                else
                    metric.params(2).value = 1;
                end
                metric.params(3).value = rawData{9,2};
                critInd = 12;

            case 'erp'
                %Set params
                metric.params(1).value = structIndex;
                if strcmpi(lower(rawData{8,2}),'no')
                    metric.params(2).value = 2;
                else
                    metric.params(2).value = 1;
                end
                metric.params(3).value = rawData{9,2};
                metric.params(4).value = rawData{10,2};
                metric.params(5).value = rawData{11,2};
                critInd = 13;

            case 'lkb'
                %Set params
                metric.params(1).value = structIndex;
                if strcmpi(lower(rawData{8,2}),'no')
                    metric.params(2).value = 2;
                else
                    metric.params(2).value = 1;
                end
                metric.params(3).value = rawData{9,2};
                metric.params(4).value = rawData{10,2};
                metric.params(5).value = rawData{11,2};
                critInd = 14;

        end

        %Set criteria
        if strcmpi(rawData{critInd,2},'above')
            cS.passDirectionIndex = 1;
        else
            cS.passDirectionIndex = 2;
        end
        cS.passValue = rawData{critInd+1,2};
        if strcmpi(rawData{critInd+2,2},'above')
            cS.marginalDirectionIndex = 1;
        else
            cS.marginalDirectionIndex = 2;
        end
        if strcmpi(rawData{critInd+4,2},'high')
            cS.priority = 1;
        else
            cS.priority = 2;
        end
        if strcmpi(rawData{critInd+5,2},'strict')
            cS.priorityTypeIndex = 1;
        else
            cS.priorityTypeIndex = 2;
        end
        metric.criteria = cS;

        mSState.currentMetric = metric;
        set(mSState.handles.metricNameTitle, 'String', metric.name);
        set(mSState.handles.functionName, 'String', ['Function callback: ' func2str(metric.functionName)]);
        set(mSState.handles.functionDesc, 'String', ['Function description: ' metric.description]);
        set(mSState.handles.parameterLabel, 'String', 'Parameters: ');
        for i=1:length(metric.params)  %populate parameter window with all existing parameters, using passed default values
            switch metric.params(i).type
                case 'Edit'
                    mSState.handles.params = [mSState.handles.params uicontrol('callback', ['metricSelection(''parameter_callback'',' num2str(i) ');'], 'units',units,'BackgroundColor',uicolor, 'Position',[.57 + mod(i-1,3)*.11 .70 - mod(floor((i-1)/3), 6)*.1 .1 .04],'String', metric.params(i).value, 'Style','edit','Tag','parameter')];
                    uicontrol('units',units,'BackgroundColor',uicolor, 'Position',[.57 + mod(i-1,3)*.11 .74 - mod(floor((i-1)/3), 6)*.1 .1 .04],'String', metric.params(i).name, 'Style','text','Tag','parameter','horizontalalignment', 'left');
                case 'DropDown'
                    mSState.handles.params = [mSState.handles.params uicontrol('callback', ['metricSelection(''parameter_callback'',' num2str(i) ');'], 'units',units,'BackgroundColor',uicolor, 'Position',[.57 + mod(i-1,3)*.11 .70 - mod(floor((i-1)/3), 6)*.1 .1 .04],'String', metric.params(i).list, 'Style','popupmenu','Tag','parameter')];
                    uicontrol('units',units,'BackgroundColor',uicolor, 'Position',[.57 + mod(i-1,3)*.11 .74 - mod(floor((i-1)/3), 6)*.1 .1 .04],'String', metric.params(i).name, 'Style','text','Tag','parameter','horizontalalignment', 'left');
            end
        end

        %if you change something here, then copy it to case 'usermetricselected as well.
        set(mSState.handles.criteriaLabel, 'String', 'Criteria: ');
        uicontrol('units',units,'BackgroundColor',uicolor, 'Position',[.57 .435-.04 .15 .04],'String', 'Pass:       Value must be ', 'Style','text','Tag','criteria', 'horizontalalignment', 'left');
        mSState.handles.criteria.passDirectionIndex = uicontrol('callback', 'metricSelection(''criteria_callback'', ''passDirectionIndex'');', 'units',units,'BackgroundColor',uicolor, 'Position',[.57+.15 .435-.031 .07 .04],'String', cS.passDirectionList, 'Value', cS.passDirectionIndex, 'Style','popupmenu','Tag','criteria');
        mSState.handles.criteria.passValue = uicontrol('callback', ['metricSelection(''criteria_callback'', ''passValue'');'], 'units',units,'BackgroundColor',uicolor, 'Position',[.57+.15+.07+.005 .435-.031 .1 .04],'String', cS.passValue, 'Style','edit','Tag','criteria');
        uicontrol('units',units,'BackgroundColor',uicolor, 'Position',[.57 .435-.095 .15 .04],'String', 'Marginal:  Value must be ', 'Style','text','Tag','criteria', 'horizontalalignment', 'left');
        mSState.handles.criteria.marginalDirectionIndex = uicontrol('callback', 'metricSelection(''criteria_callback'', ''marginalDirectionIndex'');', 'units',units,'BackgroundColor',uicolor, 'Position',[.57+.15 .435-.086 .07 .04],'String', cS.marginalDirectionList, 'Value', cS.marginalDirectionIndex, 'Style','popupmenu','Tag','criteria');
        mSState.handles.criteria.marginalValue = uicontrol('callback', ['metricSelection(''criteria_callback'', ''marginalValue'');'], 'units',units,'BackgroundColor',uicolor, 'Position',[.57+.15+.07+.005 .435-.086 .1 .04],'String', cS.marginalValue, 'Style','edit','Tag','criteria');
        uicontrol('units',units,'BackgroundColor',uicolor, 'Position',[.57 .435-.15 .055 .04],'String', 'Priority: ', 'Style','text','Tag','criteria', 'horizontalalignment', 'left');
        mSState.handles.criteria.priority = uicontrol('callback', ['metricSelection(''criteria_callback'', ''priority'');'], 'units',units,'BackgroundColor',uicolor, 'Position',[.57+.060 .435-.141 .1 .04],'String', cS.priority, 'Style','edit','Tag','criteria');
        uicontrol('units',units,'BackgroundColor',uicolor, 'Position',[.57+.165 .435-.15 .21 .04],'String', '1 = highest, 2 = second-highest, etc.', 'Style','text','Tag','criteria', 'horizontalalignment', 'left');
        uicontrol('units',units,'BackgroundColor',uicolor, 'Position',[.57 .435-.205 .1 .04],'String', 'Priority Type: ', 'Style','text','Tag','criteria', 'horizontalalignment', 'left');
        mSState.handles.criteria.priorityTypeIndex = uicontrol('callback', 'metricSelection(''criteria_callback'', ''priorityTypeIndex'');', 'units',units,'BackgroundColor',uicolor, 'Position',[.57+.10 .435-.196 .07 .04],'String', cS.priorityTypeList, 'Value', cS.priorityTypeIndex, 'Style','popupmenu','Tag','criteria');

        mSState.currentMetricType = 'BuiltIn';
        metricSelection('addmetric');


    case 'builtinmetricsetselected'  %need to remove more things than just this
        delete(findobj('tag', 'parameter')); %remove all old parameter GUI objects.
        delete(findobj('tag', 'criteria')); %remove all old criteria GUI objects.
        mSState.handles.params = [];
        mSState.currentMetric = [];
        set(mSState.handles.metricNameTitle, 'String', planC{planC{end}.metrics}.savedMetricSets(get(mSState.handles.metricSetList, 'Value')).name);
        set(mSState.handles.functionName, 'String', '');
        set(mSState.handles.functionDesc, 'String', '');
        set(mSState.handles.parameterLabel, 'String', '');
        set(mSState.handles.criteriaLabel, 'String', '');
        %Double clicks automatically add metric set to userlist
        if strcmpi(get(mSState.handles.figure, 'SelectionType'), 'open')
            set(mSState.handles.figure, 'SelectionType', 'normal');
            metricSelection('addmetric');
        end


    case 'usermetricselected'
        delete(findobj('tag', 'parameter')); %remove all old parameter GUI objects.
        mSState.handles.params = [];
        metric = mSState.planMetricsS(get(mSState.handles.myMetricList, 'Value'));
        if length(metric)>=1
            metric = metric(1);
        else
            return;
        end
        set(mSState.handles.metricNameTitle, 'String', metric.name);
        set(mSState.handles.functionName, 'String', ['Function callback: ' func2str(metric.functionName)]);
        set(mSState.handles.functionDesc, 'String', ['Function description: ' metric.description]);
        set(mSState.handles.parameterLabel, 'String', 'Parameters: ');
        mSState.currentMetric = metric;
        pos = get(mSState.handles.functionName,'Position');
        for i=1:length(metric.params)  %populate parameter window with all existing parameters, using passed default values
            switch metric.params(i).type
                case 'Edit'
                    mSState.handles.params = [mSState.handles.params uicontrol('callback', ['metricSelection(''parameter_callback'',' num2str(i) ');'], 'units',units,'BackgroundColor',uicolor, 'Position',[pos(1) + mod(i-1,3)*.11 .70 - mod(floor((i-1)/3), 6)*.1 .1 .04],'String', metric.params(i).value, 'Style','edit','Tag','parameter')];
                    uicontrol('units',units,'BackgroundColor',uicolor, 'Position',[pos(1) + mod(i-1,3)*.11 .74 - mod(floor((i-1)/3), 6)*.1 .1 .04],'String', metric.params(i).name, 'Style','text','Tag','parameter','horizontalalignment', 'left');
                case 'DropDown'
                    mSState.handles.params = [mSState.handles.params uicontrol('callback', ['metricSelection(''parameter_callback'',' num2str(i) ');'], 'units',units,'BackgroundColor',uicolor, 'Position',[pos(1) + mod(i-1,3)*.11 .70 - mod(floor((i-1)/3), 6)*.1 .1 .04],'String', metric.params(i).list, 'value', metric.params(i).value, 'Style','popupmenu','Tag','parameter')];
                    uicontrol('units',units,'BackgroundColor',uicolor, 'Position',[pos(1) + mod(i-1,3)*.11 .74 - mod(floor((i-1)/3), 6)*.1 .1 .04],'String', metric.params(i).name, 'Style','text','Tag','parameter','horizontalalignment', 'left');
            end
        end

        %criteria
        delete(findobj('tag', 'criteria')); %remove all old criteria GUI objects.
        if ~isfield(mSState.currentMetric,'criteria') %there are no defaults for the criteria, so we'll put them in
            cS = struct();
            cS.passDirectionIndex = 1; cS.passDirectionList = {'above','below'}; cS.passValue = 0;
            cS.marginalDirectionIndex = 1; cS.marginalDirectionList = {'above','below'}; cS.marginalValue = 0;
            cS.priority = 1; cS.priorityTypeIndex = 1; cS.priorityTypeList = {'strict','fuzzy'};
            cS.passStatus = {}; %will be 'passed', 'marginal', or 'failed' for ea dose dist
            mSState.currentMetric.criteria = cS;
        else
            cS = mSState.currentMetric.criteria;
        end
        %if you change something here, then copy it to case 'usermetricselected as well.
        set(mSState.handles.criteriaLabel, 'String', 'Criteria: ');
        uicontrol('units',units,'BackgroundColor',uicolor, 'Position',[pos(1) .435-.04 .12 .04],'String', 'Pass:       Value must be ', 'Style','text','Tag','criteria', 'horizontalalignment', 'left');
        mSState.handles.criteria.passDirectionIndex = uicontrol('callback', 'metricSelection(''criteria_callback'', ''passDirectionIndex'');', 'units',units,'BackgroundColor',uicolor, 'Position',[pos(1)+.12 .435-.031 .07 .04],'String', cS.passDirectionList, 'Value', cS.passDirectionIndex, 'Style','popupmenu','Tag','criteria');
        mSState.handles.criteria.passValue = uicontrol('callback', ['metricSelection(''criteria_callback'', ''passValue'');'], 'units',units,'BackgroundColor',uicolor, 'Position',[pos(1)+.12+.07+.005 .435-.031 .1 .04],'String', cS.passValue, 'Style','edit','Tag','criteria');
        uicontrol('units',units,'BackgroundColor',uicolor, 'Position',[pos(1) .435-.095 .12 .04],'String', 'Marginal:  Value must be ', 'Style','text','Tag','criteria', 'horizontalalignment', 'left');
        mSState.handles.criteria.marginalDirectionIndex = uicontrol('callback', 'metricSelection(''criteria_callback'', ''marginalDirectionIndex'');', 'units',units,'BackgroundColor',uicolor, 'Position',[pos(1)+.12 .435-.086 .07 .04],'String', cS.marginalDirectionList, 'Value', cS.marginalDirectionIndex, 'Style','popupmenu','Tag','criteria');
        mSState.handles.criteria.marginalValue = uicontrol('callback', ['metricSelection(''criteria_callback'', ''marginalValue'');'], 'units',units,'BackgroundColor',uicolor, 'Position',[pos(1)+.12+.07+.005 .435-.086 .1 .04],'String', cS.marginalValue, 'Style','edit','Tag','criteria');
        uicontrol('units',units,'BackgroundColor',uicolor, 'Position',[pos(1) .435-.15 .055 .04],'String', 'Priority: ', 'Style','text','Tag','criteria', 'horizontalalignment', 'left');
        mSState.handles.criteria.priority = uicontrol('callback', ['metricSelection(''criteria_callback'', ''priority'');'], 'units',units,'BackgroundColor',uicolor, 'Position',[pos(1)+.060 .435-.141 .05 .04],'String', cS.priority, 'Style','edit','Tag','criteria');
        uicontrol('units',units,'BackgroundColor',uicolor, 'Position',[pos(1)+.145 .435-.15 .15 .04],'String', '1 = highest, 2 = second-highest, etc.', 'Style','text','Tag','criteria', 'horizontalalignment', 'left');
        uicontrol('units',units,'BackgroundColor',uicolor, 'Position',[pos(1) .435-.205 .1 .04],'String', 'Priority Type: ', 'Style','text','Tag','criteria', 'horizontalalignment', 'left');
        mSState.handles.criteria.priorityTypeIndex = uicontrol('callback', 'metricSelection(''criteria_callback'', ''priorityTypeIndex'');', 'units',units,'BackgroundColor',uicolor, 'Position',[pos(1)+.07 .435-.196 .07 .04],'String', cS.priorityTypeList, 'Value', cS.priorityTypeIndex, 'Style','popupmenu','Tag','criteria');

        %dont forget range dialogue, stored values
        mSState.handles.range = uicontrol('callback', 'metricSelection(''range_callback'');', 'units',units,'BackgroundColor',uicolor, 'Position',[.57 .1-.015 .1 .04],'String', num2str(metric.range), 'Style','edit','Tag','parameter');
        uicontrol('units',units,'BackgroundColor',uicolor, 'Position', [pos(1) .06-.015+.01 .1 .04-.01],'String', 'Output Range', 'Style','text','Tag','parameter','horizontalalignment', 'center');
        %Double clicks automatically remove metric from userlist
        if strcmpi(get(mSState.handles.figure, 'SelectionType'), 'open')
            set(mSState.handles.figure, 'SelectionType', 'normal');
            metricSelection('removemetric');
        end
        

    case 'addmetric' %add current metric to the user metrics list, and store--select the stored user metric as the current metric.
        if(strcmp(mSState.currentMetricType, 'BuiltIn'))
            mSState.planMetricsS(mSState.numPlanMetrics + 1) = mSState.currentMetric;
            mSState.numPlanMetrics = mSState.numPlanMetrics + 1;
            set(findobj('tag', 'myMetricsList'), 'String', {mSState.planMetricsS.name});
            set(findobj('tag', 'myMetricsList'), 'Value', mSState.numPlanMetrics);
            metricSelection('mymetriclist_callback');
        elseif (strcmp(mSState.currentMetricType, 'BuiltInSet'))
            numMetricSet = get(mSState.handles.metricSetList, 'Value');
            for i=1:size(planC{planC{end}.metrics}.savedMetricSets(numMetricSet).metricSet,2)
                mSState.currentMetric = planC{planC{end}.metrics}.savedMetricSets(numMetricSet).metricSet(i);
                mSState.currentMetricType = 'BuiltIn';
                metricSelection('addmetric');
            end
            mSState.currentMetricType = 'BuiltInSet';
        end

        return;

    case 'parameter_callback' %parameter has changed, update the current and stored version if it exists
        switch get(mSState.handles.params(varargin{1}), 'Style');
            case 'edit'
                mSState.currentMetric.params(varargin{1}).value = get(mSState.handles.params(varargin{1}), 'String');
            case 'popupmenu'
                mSState.currentMetric.params(varargin{1}).value = get(mSState.handles.params(varargin{1}), 'Value');
        end
        if(strcmp(mSState.currentMetricType, 'User'))
            mSState.planMetricsS(mSState.currentMetricIndex) = mSState.currentMetric;
        end
        if strcmpi(mSState.currentMetric.name,'lkb')
            lkbExpandView('UPDATECURVE')
        end

    case 'criteria_callback' %criteria input has changed, update the current and stored version if it exists
        tempHandle = eval(['mSState.handles.criteria.' varargin{1}]);
        switch get(tempHandle, 'Style');
            case 'edit'
                eval(['mSState.currentMetric.criteria.' varargin{1} ' = str2num(get(tempHandle, ''String''));']);
            case 'popupmenu'
                eval(['mSState.currentMetric.criteria.' varargin{1} ' = get(tempHandle, ''Value'');']);
        end
        if(strcmp(mSState.currentMetricType, 'User'))
            mSState.planMetricsS(mSState.currentMetricIndex) = mSState.currentMetric;
        end

    case 'range_callback' %range has changed, update current and stored version if it exists
        mSState.currentMetric.range = str2num(get(mSState.handles.range, 'String'));
        if(strcmp(mSState.currentMetricType, 'User'))
            mSState.planMetricsS(mSState.currentMetricIndex) = mSState.currentMetric;
        end

    case 'metricnametitle_callback' %metric name has changed, update current and stored version if it exists
        mSState.currentMetric.name = get(findobj('tag', 'metricNameTitle'), 'String');
        if(strcmp(mSState.currentMetricType, 'User'))
            mSState.planMetricsS(mSState.currentMetricIndex) = mSState.currentMetric;
            set(findobj('tag', 'myMetricsList'), 'String', {mSState.planMetricsS.name});
        end

    case 'removemetric' %current metric, if it is in the user list, is removed from list & planMetricsS
        if(strcmp(mSState.currentMetricType, 'User'))
            mSState.planMetricsS(mSState.currentMetricIndex) = [];
            if(mSState.currentMetricIndex == mSState.numPlanMetrics)
                set(mSState.handles.myMetricList, 'Value', [mSState.currentMetricIndex - 1]);
                mSState.currentMetricIndex = mSState.currentMetricIndex - 1;
            end
            mSState.numPlanMetrics = mSState.numPlanMetrics - length(mSState.currentMetricIndex);
            set(findobj('tag', 'myMetricsList'), 'String', {mSState.planMetricsS.name});
        end

    case 'evaluatemetrics' %init graphical comparison, and give it planMetricsS and a list of doses/names to perform calcs on
        try
            graphicalComparison('init', planC);
            dosesToCompare = get(mSState.handles.doseList, 'Value');

            badDosesV = [];
            for i=1:length(dosesToCompare)
                if isCompressed(planC{indexS.dose}(dosesToCompare(i)).doseArray)
                    badDosesV = [badDosesV i];
                end
            end
            if ~isempty(badDosesV)
                warning(['Cannot calculate metrics on compressed dosearrays.  Skipping doses [' num2str(badDosesV) '].']);
            end
            dosesToCompare(badDosesV) = [];

            for i=1:length(mSState.planMetricsS) %set doses to operate on in metrics.
                mSState.planMetricsS(i).doseSets = dosesToCompare;
            end
            planC = graphicalComparison('add', planC, stateS.optS, mSState.planMetricsS, {planC{indexS.dose}(mSState.planMetricsS(1).doseSets).fractionGroupID});
        catch
            warning(['Error in graphicalComparison: ' lasterr]);
        end

    case 'generatereport'
        try

            %get name of html report file to generate
            [fname, pathname] = uiputfile({'*.html', 'HTML files (*.html)';'*.*', 'All Files (*.*)'}, 'Select a location and filename to save the generated html report file'); %,'Location',[100,100]);

            if (fname == 0) %then user canceled
                return;
            end

            %get doses to compare, and put them into appropriate place in planMetricsS
            dosesToCompare = get(mSState.handles.doseList, 'Value');

            badDosesV = [];
            for i=1:length(dosesToCompare)
                if isCompressed(planC{indexS.dose}(dosesToCompare(i)).doseArray)
                    badDosesV = [badDosesV i];
                end
            end
            if ~isempty(badDosesV)
                warning(['Cannot calculate metrics on compressed dosearrays.  Skipping doses [' num2str(badDosesV) '].']);
            end
            dosesToCompare(badDosesV) = [];

            for i=1:length(mSState.planMetricsS) %set doses to operate on in metrics.
                mSState.planMetricsS(i).doseSets = dosesToCompare;
            end

            %call function to generate report
            [planC, mSState.planMetricsS] = generateReport(planC, mSState.planMetricsS, fname, pathname, {planC{indexS.dose}(mSState.planMetricsS(1).doseSets).fractionGroupID}); % stateS.optS

            %display html file in help browser
            open([pathname fname]);

        catch
            warning(['Error in generateReport: ' lasterr]);
        end

    case 'savemetricset' %save a set of metrics (in planC) for later reference.
        if ~isfield(mSState, 'planMetricsS') | isempty(mSState.planMetricsS)
            errordlg('Cannot save a metric set with no metrics in it.');
            return;
        end
        if ~isfield(planC{end},'metrics')
            metricSelection('createMetricsStructInPlanC');
        end
        metricSetNameC = inputdlg('Name to save metric set as:');
        if isempty(metricSetNameC) %they cancelled
            return;
        end
        planC{planC{end}.metrics}.savedMetricSets(end+1).name = metricSetNameC{1};
        planC{planC{end}.metrics}.savedMetricSets(end).metricSet = mSState.planMetricsS;
        set(mSState.handles.metricSetList, 'String', {planC{planC{end}.metrics}.savedMetricSets.name});

    case 'createmetricsstructinplanc'
        planC{end}.metrics = size(planC,2);
        planC{end}.indexS = size(planC,2)+1;
        planC{planC{end}.indexS} = planC{end};
        planC{planC{end}.metrics} = struct('savedMetricSets',struct([]));

    case 'cancel'
        close;

    otherwise
        metricSelectionError = 1
end
function varargout = graphicalComparison(keyword, planC, optS, varargin);
%Graphical Comparison Tool, displays given metrics and a linear aggregate based on weights.
%JRA 6.4.03
%JRA 6.6.03 added alot of stuff, mode change etc.
%JRA 6.9.03 units
%went to CVS
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

global gCState;
uicolor              = [.9 .9 .9];
units = 'normalized';
nargout = 0;

switch lower(keyword)
    case 'init'
        gCState = [];
        gCState.metrics = [];
        gCState.optS.mode='bar';
        gCState.optS.units='on';
        %Get figure, set its size based on screen size.
        screenSize = get(0,'ScreenSize');
        h = figure('Position', [screenSize(3)/10 screenSize(4)/10 screenSize(3)/10*8 screenSize(4)/10*6]);
        try
            global stateS
            stateS.handle.graphicalComparisonFig = h;
        end
        set(h, 'NumberTitle', 'off');
        set(h, 'Name', 'Graphical Comparison of Metrics');
        set(h, 'MenuBar', 'none');
        gCState.handles.figure = h;

        %Specify plot dimensions
        gCState.graphics.plotWidth = .9;
        gCState.graphics.plotHeight = .7;
        gCState.graphics.plotLeft = (1 - gCState.graphics.plotWidth)/2;
        gCState.graphics.plotBottom = .2;

        %Specify other graphic positions
        gCState.graphics.buttonBottom = .155;
        gCState.graphics.buttonWidth =.150;
        gCState.graphics.buttonHeight = .035;
        pause(.01);


    case 'mode' %interface to change from bar to line mode.
        if(length(varargin) ~= 0)
            if(lower(varargin{1}) == 'bar')
                gCState.optS.mode='bar';
            elseif(lower(varargin{1}) == 'line')
                gCState.optS.mode='line';
            end
        else
            if(strcmpi(gCState.optS.mode,'bar'))
                gCState.optS.mode='line';
            else
                gCState.optS.mode='bar';
            end
        end
        graphicalComparison('draw');

    case 'toggleunits' %interface to toggle units
        if(length(varargin) ~= 0)
            if(lower(varargin{1}) == 'on')
                gCState.optS.units='on';
            elseif(lower(varargin{1}) == 'off')
                gCState.optS.units='off';
            end
        else
            if(strcmpi(gCState.optS.units,'on'))
                gCState.optS.units='off';
            else
                gCState.optS.units='on';
            end
        end
        graphicalComparison('units');

    case 'add' %interface to add metric functions, takes cell array of metrics
        if(nargin == 5)
            gCState.plans.names = varargin{2};
        else
            gCState.plans.names = [];
        end
        planMetricsS = varargin{1};
        numMetrics = length(planMetricsS);

        %Evaluate metrics, data is stored in metric's valueV field.
        statusBar = waitbar(0,'Calculating/Retrieving Metric Data');
        for i=1:numMetrics
            [planC, planMetricsS(i)] = feval(planMetricsS(i).functionName, planC, planMetricsS(i), 'evaluate');
            waitbar(i/numMetrics,statusBar)
        end
        close(statusBar)

        %Store metrics locally
        gCState.metrics = planMetricsS;
        graphicalComparison('refresh');
        nargout = 1;
        varargout{1} = planC;
        return;

    case 'refresh'
        figure(gCState.handles.figure);
        numMetrics = length(gCState.metrics);
        numPlans = length(gCState.metrics(1).doseSets);

        %Normalize the metrics on a scale of 0-1, store under normalizedMetrics. Range values stored in metrics are used.
        normalizedMetrics = [];
        normalizedPlan = [];
        for i=1:numMetrics
            if gCState.metrics(i).range(1) == inf;
                minValue = max(gCState.metrics(i).valueV);
            elseif gCState.metrics(i).range(1) == -inf;
                minValue = min(gCState.metrics(i).valueV);
            else
                minValue = gCState.metrics(i).range(1);
            end
            if gCState.metrics(i).range(2) == inf;
                maxValue = max(gCState.metrics(i).valueV);
            elseif gCState.metrics(i).range(2) == -inf;
                maxValue = min(gCState.metrics(i).valueV);
            else
                maxValue = gCState.metrics(i).range(2);
            end
            metricRange = maxValue - minValue;
            for j=1:length(gCState.metrics(i).valueV)
                if metricRange == 0
                    relativeValue = .5; %If all values are equal, set to .5.
                else
                    relativeValue = (gCState.metrics(i).valueV(j) - minValue) / metricRange;
                end
                normalizedPlan = [normalizedPlan;relativeValue];
            end
            normalizedMetrics = [normalizedMetrics normalizedPlan];
            normalizedPlan = [];
        end
        gCState.normalizedMetrics = normalizedMetrics;
        weights = ones(numMetrics, 1);
        gCState.weights = weights;
        %

        hV = findobj('tag', 'metricWeight');
        delete(hV);
        hV = findobj('tag', 'aggregate');
        delete(hV);

        %Set up graphics stuff, including labels and weight boxes
        hV = findobj('tag', 'ComparisonAxes');
        delete(hV);
        gCState.handles.axes = axes('units', units, 'Position', [gCState.graphics.plotLeft, gCState.graphics.plotBottom, gCState.graphics.plotWidth, gCState.graphics.plotHeight], 'tag', 'ComparisonAxes');
        gCState.handles.weights = [];

        %Clear previous Graphics
        hV = findobj('tag', 'metricWeight');
        delete(hV);
        hV = findobj('tag', 'metricNameTag');
        delete(hV);
        hV = findobj('tag', 'aggregate');
        delete(hV);
        hV = findobj('tag', 'modeToggle');
        delete(hV);
        hV = findobj('tag', 'unitToggle');
        delete(hV);

        widthOfWorkingArea = gCState.graphics.plotWidth;
        weightButtonYValue = gCState.graphics.buttonBottom;
        weightButtonWidth = min(gCState.graphics.buttonWidth, widthOfWorkingArea/(numMetrics+1) - .01);
        weightButtonHeight = gCState.graphics.buttonHeight;
        %Draw labels and weight fields for all but aggregate
        for i=1:numMetrics
            weightButtonXValue = widthOfWorkingArea/(numMetrics+1)/2 + (i-1)*widthOfWorkingArea/(numMetrics+1) + gCState.graphics.plotLeft - weightButtonWidth/2;

            gCState.handles.weights = [gCState.handles.weights uicontrol('units',units,'BackgroundColor',uicolor,'Position',[weightButtonXValue weightButtonYValue weightButtonWidth weightButtonHeight], ...
                'String',weights(i),'Style','edit','Tag','metricWeight','callback','graphicalComparison(''weightChange'');','tooltipstring','Change Weight of this Metric')];

            uicontrol('units',units,'BackgroundColor',uicolor,'Position',[weightButtonXValue weightButtonYValue-weightButtonHeight weightButtonWidth weightButtonHeight],'String',gCState.metrics(i).name, ...
                'Style','text','Tag','metricNameTag');
            uicontrol('units',units,'BackgroundColor',uicolor,'Position',[weightButtonXValue weightButtonYValue-2*weightButtonHeight weightButtonWidth weightButtonHeight],'String',gCState.metrics(i).units, ...
                'Style','text','Tag','metricNameTag');
            uicontrol('units',units,'BackgroundColor',uicolor,'Position',[weightButtonXValue weightButtonYValue-3*weightButtonHeight weightButtonWidth weightButtonHeight],'String',gCState.metrics(i).note, ...
                'Style','text','Tag','metricNameTag');
        end
        %Draw labels and weight fields for aggregate
        uicontrol('units',units,'BackgroundColor',uicolor, ...
            'Position',[weightButtonXValue+widthOfWorkingArea/(numMetrics+1) weightButtonYValue weightButtonWidth weightButtonHeight],'String','Aggregate', ...
            'Style','text','Tag','aggregate');

        uicontrol('units',units,'BackgroundColor',uicolor, ...
            'Position',[weightButtonXValue+widthOfWorkingArea/(numMetrics+1) weightButtonYValue-gCState.graphics.plotLeft weightButtonWidth weightButtonHeight],'String','Mode', ...
            'Style','pushbutton','Tag','modeToggle', 'callback', 'graphicalComparison(''mode'');');
        uicontrol('units',units,'BackgroundColor',uicolor, ...
            'Position',[weightButtonXValue+widthOfWorkingArea/(numMetrics+1) weightButtonYValue-2*gCState.graphics.plotLeft weightButtonWidth weightButtonHeight],'String','Values', ...
            'Style','pushbutton','Tag','unitToggle', 'callback', 'graphicalComparison(''toggleunits'');');

        %Call the function to draw lines/bars and labels.
        graphicalComparison('draw');


        %Draw graphicalComparison lines/bars.
    case 'draw'
        numMetrics = length(gCState.metrics);
        widthOfWorkingArea = gCState.graphics.plotWidth;
        figure(gCState.handles.figure);
        %Delete old bars/lines
        hV = findobj('tag', 'comparisonBar');
        delete(hV)
        hV = findobj('tag', 'comparisonLine');
        delete(hV)
        %end
        normalizedMetrics = gCState.normalizedMetrics;
        if max(cumsum(gCState.weights)) ~= 0
            normalizedWeights = gCState.weights / max(cumsum(gCState.weights));
        else
            normalizedWeights = gCState.weights * 0;
        end
        aggregate = normalizedMetrics * normalizedWeights;
        axis off;
        %Draw bars, and set callbacks/tags
        if strcmpi(gCState.optS.mode,'bar')
            gCState.handles.bars = bar([normalizedMetrics';aggregate']);
            for i=1:length(gCState.handles.bars)
                set(gCState.handles.bars(i), 'ButtonDownFcn', ['graphicalComparison(''test'',' num2str(i) ');'], 'Tag', 'comparisonBar');
            end
            axis([.5 numMetrics+1.5 0 1])
            %Draw lines, and set callbacks/tags
        elseif strcmpi(gCState.optS.mode,'line')
            gCState.handles.lines = plot([normalizedMetrics';aggregate'], 'Marker', 'o', 'Tag', 'comparisonLine', 'LineWidth', 2);
            for i=1:length(gCState.handles.lines)
                set(gCState.handles.lines(i), 'ButtonDownFcn', ['graphicalComparison(''test'',' num2str(i) ');'], 'Tag', 'comparisonLine');
            end
            axis([.5 numMetrics+1.5 0 1])
        end
        refresh;
        legend(gCState.plans.names) %legend placement is up in the air
        graphicalComparison('units')


        %Draw (or erase) values in graph for either lines or bars
    case 'units'
        hV = findobj('tag', 'metricValues');
        delete(hV)
        if(strcmpi(gCState.optS.units,'off'))
            return;
        end
        numMetrics = length(gCState.metrics);
        yValues = gCState.normalizedMetrics;
        if(strcmpi(gCState.optS.mode,'line'))
            numLines = length(gCState.handles.lines);
            for i=1:numMetrics
                for j=1:numLines
                    text((1/(numMetrics+1))*(i-1) + 1/(numMetrics+1)/2+.01, yValues(j,i), num2str(gCState.metrics(i).valueV(j)), 'FontSize', 8,'units', units, 'Tag', 'metricValues');
                end
            end
        elseif(strcmpi(gCState.optS.mode,'bar'))
            numBars = length(gCState.handles.bars);
            for i=1:numMetrics
                for j=1:numBars
                    if(numBars*numMetrics > 9) %use vertical text if too many bars.
                        text(i - (numBars/2)*1/(numBars+1.9) + (j-1)*1/(numBars+1.5) + 1/(numBars+1.9)/2, yValues(j,i) + .01, num2str(gCState.metrics(i).valueV(j)), 'FontSize', 8, 'Tag', 'metricValues', 'Rotation', 90);
                    else
                        text(i - (numBars/2)*1/(numBars+1.9) + (j-1)*1/(numBars+1.5), yValues(j,i) + .02, num2str(gCState.metrics(i).valueV(j)), 'FontSize', 8, 'Tag', 'metricValues', 'Rotation', 0);
                    end
                end
            end
        end


        %Weight change callback.
    case 'weightchange'
        gCState.weights = [];
        for i=1:length(gCState.handles.weights)
            weight = str2num(get(gCState.handles.weights(i), 'String'));
            if isempty(weight)|weight == 0
                warndlg('Please enter weights as some finite value');
                return;
            end
            gCState.weights = [gCState.weights weight];
        end
        gCState.weights = gCState.weights';
        graphicalComparison('draw');


    case 'test'
        if isempty(varargin)
            return
        end
        planNum = varargin{1}
        pointerMatrix = get(gCState.handles.axes, 'CurrentPoint');
        metricNum = round(pointerMatrix(1,1))
end
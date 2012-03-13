function varargout = table(varargin)
%"table"
%   Function to create and manipulate interactive GUI tables in matlab.
%   Written in 6.5
%
%   JRA
%
%Usage: hAxis = table         %Creates a new figure and new table 
%       hAxis = table(hAxis, 'init')
%       hAxis = table(hAxis, 'data', data)
%       hAxis = table(hAxis, 'barcolor1', [r g b]);
%       hAxis = table(hAxis, 'barcolor2', [r g b]);
%       hAxis = table(hAxis, 'highlightcolor', [r g b]);
%       numEle = table(hAxis, 'currentelement');
%       numEle = table(hAxis, 'currentelement');
%       table('colwidth', colwidths')
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

%Parse input args, set up handles.
switch nargin
    %Just 'table' was called.  Make new fig/axis->table.
    case 0
        action = 'INIT';
        hFig = figure;
        hAxis = axes('parent', hFig);
        varargout{1} = hAxis;
    case 1
    %Only valid 1 argument inputs are callbacks, or 'table(hAxis)'.
        if ishandle(varargin{1}) & strcmpi(get(varargin{1}, 'type'), 'axes')
            action = 'INIT';        
            hAxis  = varargin{1};
        elseif ischar(varargin{1}) & ~isempty(gcbo)
            action = varargin{1};            
            hAxis = get(gcbo, 'userdata');          
        else
            error('Invalid table input. Try: table(hAxis, ''<PropertyName>'', ''<PropertyVal>'');');
        end
    case 2
    %User is getting property or making a one parameter call.
    %OR Gui object is making a two parameter call.
        if ishandle(varargin{1}) & strcmpi(get(varargin{1}, 'type'), 'axes')
            hAxis = varargin{1};
            action = varargin{2};
        elseif ~isempty(gcbo)
            hAxis = get(gcbo, 'parent')
            action = varargin{1};
            inVal = varargin{2};
        else
            error('Invalid table input. Try: table(hAxis, ''<PropertyName>'', ''<PropertyVal>'');');
        end
    case 3
    %User is setting property or making a two parameter call.
        if ishandle(varargin{1}) & strcmpi(get(varargin{1}, 'type'), 'axes')
            hAxis  = varargin{1};
            action = varargin{2};
            inVal  = varargin{3};
        else
            error('Invalid table input. Try: table(hAxis, ''<PropertyName>'', ''<PropertyVal>'');');
        end
    otherwise 
        error('Invalid table input. Try: table(hAxis, ''<PropertyName>'', ''<PropertyVal>'');');        
end

%Master switchyard for callbacks & user calls.
switch upper(action)
    
    case 'INIT'
        hFigure = get(hAxis, 'parent');
        delete(get(hAxis, 'children'));            
        try
            %Clear out old scrollbars/buttons in case this used to be a table axis.
            ud = get(hAxis, 'userdata');
            delete(ud.handles.scrollbarUD);
            delete(ud.handles.scrollbarLR);  
            delete(ud.handles.optButton);
        end
        set(hAxis, 'userdata', []);

        %Clear hAxis userdata.
        ud = [];
        
        %Use the axis and font to determine the widths of all characters.
        %This info is used when deciding to truncate strings with '...'
        ud.charSizes = getCharSizes(hAxis);
                
        hFig = get(hAxis, 'parent');
        set(hFig, 'doublebuffer', 'on', 'renderer', 'zbuffer');
        axis(hAxis, 'ij', 'off') 
        
        set(hAxis, 'units', 'pixels');                      
        axPos    = get(hAxis, 'position');
        axWidth  = axPos(3);                
        axHeight = axPos(4);

        %Hardcoded values for scrollbar width and height.
        ud.scrWidth  = 15;
        ud.barHeight = 17;
        ud.numBars   = axHeight/ud.barHeight;
        
        %Last bar is a fraction of ud.barHeight.
        lastBarHeight = mod(axHeight, ud.barHeight);
        
        %Create scrollbars and option button.
        ud.handles.scrollbarUD = uicontrol('style', 'slider', 'units', 'pixels', 'position', [axPos(1)+axPos(3)+1 axPos(2) ud.scrWidth axPos(4)], 'enable', 'off', 'callback', 'table(''UDSCROLLBARCLICKED'');', 'userdata', hAxis);
        set(ud.handles.scrollbarUD, 'units', 'normalized');
        
        ud.handles.scrollbarLR = uicontrol('style', 'slider', 'units', 'pixels', 'position', [axPos(1) axPos(2)-ud.scrWidth axPos(3) ud.scrWidth], 'enable', 'off', 'callback', 'table(''LRSCROLLBARCLICKED'');', 'userdata', hAxis);
        set(ud.handles.scrollbarLR, 'units', 'normalized');
        
        ud.handles.optButton = uicontrol('style', 'pushbutton', 'units', 'pixels', 'position', [axPos(1)+axPos(3)+1 axPos(2)-ud.scrWidth ud.scrWidth ud.scrWidth], 'enable', 'off', 'userdata', hAxis);
        set(ud.handles.optButton, 'units', 'normalized');
       
        %Use axis size in pixels for axis limits.
        set(hAxis, 'xlim', [0 axWidth-1], 'ylim', [0 axHeight]);
        set(hAxis, 'xtick', [], 'ytick', []);        
        
        %Default GUI colors.
        ud.colors.evenBars               = [1 1 1];
        ud.colors.oddBars                = [.9 1 1];
        ud.colors.activeBars             = [0 1 1];
        ud.colors.barOutline             = [.8 .8 .8];
        ud.colors.headerColor            = [.8 .8 .8];   
        ud.colors.scrollbarcolor         = [.9 .9 .9];
        ud.colors.black                  = [0 0 0];
        ud.colors.raisedButtons(1,1,1:3) = [1 1 1];
        ud.colors.raisedButtons(1,2,1:3) = [0 0 0];
        ud.colors.raisedButtons(1,3,1:3) = [0 0 0];
        ud.colors.raisedButtons(1,4,1:3) = [1 1 1];

        %Create the single pre-init column header.
        ud.handles.colheaders(1) = patch([1 axWidth-1 axWidth-1 1],[1 1 ud.barHeight-1 ud.barHeight-1], ud.colors.raisedButtons, 'edgecolor', 'flat', 'facecolor', ud.colors.headerColor, 'parent', hAxis);
               
        %Draw the bars that appear undernear the data, alternating between
        %the color for evenBars and for oddBars.
        for i=1:floor(ud.numBars-1)
            color = mod(i,2)*(ud.colors.evenBars) + (1-mod(i,2))*(ud.colors.oddBars);
            ud.handles.highlights(i) = patch([0 axWidth axWidth 0],[i*ud.barHeight i*ud.barHeight (i+1)*ud.barHeight (i+1)*ud.barHeight], color, 'edgecolor', ud.colors.barOutline, 'buttondownfcn', ['table(''highlightClicked'', ' num2str(i) ');'], 'parent', hAxis);             
        end
        i = i+1;
        color = mod(i,2)*(ud.colors.evenBars) + (1-mod(i,2))*(ud.colors.oddBars);        
        ud.handles.highlights(i) = patch([0 axWidth axWidth 0],[i*ud.barHeight i*ud.barHeight (i+lastBarHeight)*ud.barHeight (i+lastBarHeight)*ud.barHeight], color, 'edgecolor', ud.colors.barOutline, 'buttondownfcn', ['table(''highlightClicked'', ' num2str(i) ');'], 'parent', hAxis);             
                            
        %Set and store state.
        ud.state.numBars    = i;
        ud.state.numCols    = 1;
        ud.state.axWidth    = axWidth;
        ud.state.axHeight   = axHeight;
        ud.state.doubleclickCallback = '';
        ud.state.sortedby   = 0;
        set(hAxis, 'userdata', ud);  
        set(hAxis, 'units', 'normalized')

        %Necessary?
        selectionChanged(1,hAxis);
               
    case 'SELECTELEMENT'
        ud = get(hAxis, 'userdata');
        selectionChanged(inVal, hAxis);
        
    case 'SELECTPREV'      
        ud = get(hAxis, 'userdata');
        selectionChanged(ud.state.selectedBar-1, hAxis);
        
    case 'SELECTNEXT'
        ud = get(hAxis, 'userdata');
        selectionChanged(ud.state.selectedBar+1, hAxis);
        
    case 'BARCOLOR1'       
        ud = get(hAxis, 'userdata');        
        ud.colors.evenBars = inVal;
        for i=1:floor(ud.numBars)
            color = mod(i,2)*(ud.colors.evenBars) + (1-mod(i,2))*(ud.colors.oddBars);
            set(ud.handles.highlights(i), 'facecolor', color, 'edgecolor', color)            
        end
        set(hAxis, 'userdata', ud);         
        
    case 'BARCOLOR2'
        ud = get(hAxis, 'userdata');        
        ud.colors.oddBars = inVal;
        for i=1:floor(ud.numBars)
            color = mod(i,2)*(ud.colors.evenBars) + (1-mod(i,2))*(ud.colors.oddBars);
            set(ud.handles.highlights(i), 'facecolor', color, 'edgecolor', color)            
        end 
        set(hAxis, 'userdata', ud);
        
    case 'HIGHLIGHTCOLOR'
        ud = get(hAxis, 'userdata');        
        ud.colors.activeBars = inVal;
        set(hAxis, 'userdata', ud);        
        selectionChanged(ud.state.selectedBar, hAxis);
        
    case 'COLWIDTH'
        ud = get(hAxis, 'userdata');
        colWidthsV = inVal;
        if length(colWidthsV) == ud.numCols
            ud.state.colSpacing = colWidthsV;
        else
            error('Column widths must be a vector with the same number of elements as fields in the data.');
        end
        set(hAxis, 'userdata', ud);
        displayHeaders(hAxis);
        displayData(hAxis);  
        
    case 'REDRAW'
        ud = get(hAxis, 'userdata');
        if isempty(ud)
            return;
        end
        table(hAxis, 'init');
        try
            data = getappdata(hAxis, 'TABLEDATA');% ud.data;
            callback = ud.state.doubleclickCallback;
        catch
            return;
        end
        table(hAxis, 'data', data);
        table(hAxis, 'setDBCALLBACK', callback);
        
    case 'DATA'
        data = inVal;        
        if iscell(data) & length(size(data)) == 2            
            %Convert cell into a struct array.
            fieldNames = {};
            for i=1:size(data, 2)
                fieldNames = {fieldNames{:} ['Col_' num2str(i)]};                                
            end
            data = cell2struct(data,fieldNames,2);            
        elseif isstruct(data)
        else
            error('Only NxN cell arrays or Nx1 struct arrays are valid table data.')
        end
            
        ud = get(hAxis, 'userdata');
        setappdata(hAxis, 'TABLEDATA', data);
        ud.numCols          = length(fields(data));
        ud.numRows          = length(data);
        ud.dataHeaders      = fields(data);
        ud.numFields        = length(ud.dataHeaders);
        ud.datamap          = [1:ud.numRows];
        ud.state.topElement = 1;
        ud.state.leftElement= 1;        
%         ud.state.colSpacing = [0 getOptimumColSpacing(data, ud.charSizes)*ud.state.axWidth];
        ud.state.colSpacing = repmat(.3, [1 ud.numFields-1]);
        set(hAxis, 'userdata', ud);                
        displayHeaders(hAxis);
        displayData(hAxis);       
        
    case 'GETCURRENTELEMENT'
        ud = get(hAxis, 'userdata');
        index = ud.state.topElement + ud.state.selectedBar - 1;
        varargout{1} = ud.datamap(index);               
        
    case 'SETDBCALLBACK'
        ud = get(hAxis, 'userdata');
        ud.state.doubleclickCallback = inVal;
        set(hAxis, 'userdata', ud);
        
    case 'SETRIGHTCLICKMENU'
        hMenu = inVal;
        ud = get(hAxis, 'userdata');
        set(ud.handles.highlights, 'uicontextmenu', hMenu);                        
        
    case 'UDSCROLLBARCLICKED'
        ud = get(hAxis, 'userdata');
        ud.state.topElement = round(ud.numrows - get(gcbo,'value') + 1);
        set(hAxis, 'userdata', ud);
        displayData(hAxis);        
        
	case 'LRSCROLLBARCLICKED'
        ud = get(hAxis, 'userdata');
        ud.state.leftElement = round(get(gcbo,'value'));
        set(hAxis, 'userdata', ud);
        displayHeaders(hAxis)        
        displayData(hAxis);        
        
    case {'DIVIDERCLICKED', 'DIVIDERMOVE', 'DIVIDERDONE', 'HIGHLIGHTCLICKED', 'HEADERCLICKED', 'SCROLLUPCLICKED', 'SCROLLDOWNCLICKED'} %ALL in axis clicks here.
        
        switch upper(action)
            case 'HEADERCLICKED'
                ud = get(hAxis, 'userdata');
                headerNum = inVal + ud.state.leftElement - 1;
                if headerNum == ud.state.sortedby
                    ud.datamap = ud.datamap(end:-1:1);
                else
                    data = getappdata(hAxis, 'TABLEDATA');
                    fieldNames = fields(data);
                    whichField = fieldNames{headerNum};
                    dataCol = {data.(whichField)};
%                     dataCol = ud.data(:,headerNum);
                    try
                        [y,i] = sort(dataCol);                        
%                         [y,i] = sortrows(data, headerNum);
                    catch
                        [y,i] = sortrows(cell2mat(data(:,headerNum)));
                    end
                    ud.datamap = i;
                    ud.state.sortedby = headerNum;
                end
                set(hAxis, 'userdata', ud);  
                displayData(hAxis);
                
            case 'DIVIDERCLICKED'
                set(gcbo, 'erasemode', 'xor');
                ud = get(hAxis, 'userdata');
                hFig = get(hAxis, 'parent');
                try
                    lastLine = ud.lastSelectedLine;
                    set(lastLine, 'selected', 'off');
                end
                ud.UISTATE=uisuspend(hFig);
                set(hFig, 'windowbuttonupfcn', 'table(''DIVIDERDONE'')');
                set(hFig, 'windowbuttonmotionfcn', 'table(''DIVIDERMOVE'')');                
                ud.lastSelectedLine = gcbo;
                ud.lastSelectedLineNum = inVal;
                set(gcbo, 'selected', 'on');
                set(hAxis, 'userdata', ud);
                
            case 'HIGHLIGHTCLICKED'                  
                ud = get(hAxis, 'userdata');
                barNum = inVal;
                then = inf;
                try
                    then = ud.state.lastHighlightClick;
                end
                ud.state.lastHighlightClick = now;
                set(hAxis, 'userdata', ud);
                
                if ud.state.selectedBar == barNum & abs(then-now) < 5e-006
                    eval(ud.state.doubleclickCallback); %MUST BE CHANGED
                else
                    selectionChanged(barNum, hAxis);
                end
                
            case 'DIVIDERDONE'                
                line = gco;
                xD = get(line, 'xData');                 
                set(line, 'selected', 'off');
                set(line, 'erasemode', 'normal');                
                
                hAxis = get(line, 'parent');
                ud = get(hAxis, 'userdata');
                axWidth         = ud.state.axWidth;                 
                lineNum = ud.lastSelectedLineNum;
                colSpacing = ud.state.colSpacing;                
                lE = ud.state.leftElement;
                if lineNum == 1 & lE == 1
                else
                    cumColSpacing = [0 cumsum(colSpacing(lE:end))];                
                    colSpacing(lE+lineNum-2) = (xD(1) / axWidth) - cumColSpacing(lineNum-1);
                    ud.state.colSpacing = colSpacing;                    
                end
                hFig = get(hAxis, 'parent');
                uirestore(ud.UISTATE);
                ud.UISTATE = [];
                set(hAxis, 'userdata', ud);                
                displayHeaders(hAxis);
                displayData(hAxis);
                
            case 'DIVIDERMOVE'
                line = gco;
                hAxis = get(line, 'parent');
                ud = get(hAxis, 'userdata');
                axWidth         = ud.state.axWidth; 
                cp = get(hAxis, 'CurrentPoint');
                lineNum = ud.lastSelectedLineNum;
                lowerBound = 0;
                lE = ud.state.leftElement;
                upperBound = ud.state.axWidth;
                colSpacing = ud.state.colSpacing;
                cumColSpacing = [0 cumsum(colSpacing(lE:end))];                
                try
                    lowerBound = cumColSpacing(lineNum-1)*axWidth;
                end
                try
                    upperBound = axWidth;%colSpacing(lineNum)*axWidth;
                end
                xVal = min(max(lowerBound, cp(1,1)), upperBound);
                
                set(ud.lastSelectedLine, 'xData', [xVal xVal]);
        end
end         

function selectionChanged(barNum, h)
    ud = get(h, 'userdata');
    try
        lastSelected = ud.state.selectedBar;
        color = mod(lastSelected,2)*(ud.colors.evenBars) + (1-mod(lastSelected,2))*(ud.colors.oddBars);
        set(ud.handles.highlights(lastSelected), 'facecolor', color);           
    end
    barNum = mod(barNum-1, ud.state.numBars) + 1;    
    set(ud.handles.highlights(barNum), 'facecolor', ud.colors.activeBars);
    ud.state.selectedBar = barNum; 
    set(h, 'userdata', ud);
return;


function displayHeaders(hAxis)
    ud              = get(hAxis, 'userdata');
    numFields       = ud.numFields;
    axHeight        = ud.state.axHeight;
    axWidth         = ud.state.axWidth; 
    barHeight       = ud.barHeight;
    
    colSpacing = ud.state.colSpacing;

    leftElement = ud.state.leftElement;
    rightElement = max(find(cumsum(ud.state.colSpacing(leftElement:end)) < 1)) + leftElement;
    colSpacing = [0 cumsum(ud.state.colSpacing(leftElement:rightElement-1)) 1];
    maxLength = diff(colSpacing*axWidth);
    colSpacing = colSpacing * axWidth;
    
    if isfield(ud.handles, 'dividers') & ishandle(ud.handles.dividers)
        delete(ud.handles.dividers);
        ud.handles.dividers = [];
    end
    
    for i=1:length(colSpacing)
        ud.handles.dividers(i) = line([colSpacing(i) colSpacing(i)], [0 axHeight], 'color', ud.colors.barOutline, 'buttondownfcn', ['table(''DIVIDERCLICKED'',' num2str(i) ')']);    
    end    
    
    if isfield(ud.handles, 'colheaders') & isfield(ud.handles, 'headerText') & ishandle(ud.handles.colheaders)
        delete(ud.handles.colheaders);
        ud.handles.colheaders = [];
        delete(ud.handles.headerText);
        ud.handles.headerText = [];        
    end

%     maxLength = diff([colSpacing axWidth]);
    for i=1:length(colSpacing)-1
%        ud.handles.colheaders(i) = patch([colSpacing(i)+1 colSpacing(i+1)-1 colSpacing(i+1)-1 colSpacing(i)+1],[1 1 barHeight-1 barHeight-1], ud.colors.raisedButtons, 'edgecolor', 'flat', 'facecolor', ud.colors.headerColor, 'buttondownfcn', ['table(''headerClicked'', ' num2str(i) ');']);                     
        ud.handles.colheaders(i) = patch([colSpacing(i) colSpacing(i+1) colSpacing(i+1) colSpacing(i)],[0 0 barHeight barHeight], ud.colors.headerColor, 'buttondownfcn', ['table(''headerClicked'', ' num2str(i) ');']);                     
        headerstring = dataString(ud.dataHeaders{i+leftElement-1}, maxLength(i)-1, ud.charSizes);
        ud.handles.headerText(i) = text(colSpacing(i)+2, 0, headerstring, 'verticalalignment', 'top', 'hittest', 'off', 'interpreter', 'none');    
    end
    set(hAxis, 'userdata', ud);

    
function displayData(h)
    axes(h);
    ud              = get(h, 'userdata');
    numBars         = ud.state.numBars;
    data            = getappdata(h, 'TABLEDATA');%ud.data;
    axHeight        = ud.state.axHeight;
    axWidth         = ud.state.axWidth;   
    topElement      = ud.state.topElement;    
    leftElement     = ud.state.leftElement;

    barHeight       = ud.barHeight;
    datamap         = ud.datamap;
         
    numRows         = length(data); 
    numFields       = length(fields(data));
    
    ud.numrows = numRows;
    ud.numfields = numFields;

    if topElement > numRows
        topElement = numRows;
    end
    if topElement < 1
        topElement = 1;        
    end
    ud.state.topElement = topElement;

    if leftElement > numFields
        leftElement = numFields;
    end
    if leftElement < 1
        leftElement = 1;        
    end
    ud.state.leftElement = leftElement;
          
    hBar = ud.handles.scrollbarUD;
    hBar1 = ud.handles.scrollbarLR;    
    
    if numRows > 1
       set(hBar, 'min', 1, 'max', numRows, 'enable', 'on', 'value', numRows - topElement + 1, 'sliderstep', [1/(numRows-1) numBars/(numRows-1)]);
%        set(hBar, 'min', numBars, 'max', numRows, 'enable', 'on', 'value', numRows - topElement + 1, 'sliderstep', [1/(numRows-numBars) numBars/(numRows-numBars)]);
    else
        set(hBar, 'enable', 'off');
    end
    if numFields > 1
       set(hBar1, 'min', 1, 'max', numFields, 'enable', 'on', 'value', leftElement, 'sliderstep', [1/(numFields-1) 4/(numFields-1)]);
%        set(hBar, 'min', numBars, 'max', numRows, 'enable', 'on', 'value', numRows - topElement + 1, 'sliderstep', [1/(numRows-numBars) numBars/(numRows-numBars)]);
    else
        set(hBar1, 'enable', 'off');
    end
    try 
        colSpacing = ud.state.colSpacing;
    catch
        colSpacing = 0:ud.options.scrollbarleft/numFields:ud.options.scrollbarleft;    
    end
    ud.state.colSpacing = colSpacing;
    maxLength = diff([colSpacing axWidth]);
    
    spacing = 0;    

    rightElement = max(find(cumsum(ud.state.colSpacing(leftElement:end)) < 1)) + leftElement;
    if isempty(rightElement)
        rightElement = leftElement;
    end
    colSpacing = [0 cumsum(ud.state.colSpacing(leftElement:rightElement-1)) 1];

    try
        delete(ud.handles.text);
        ud.handles.text = [];
    end
    
    maxLength = diff(colSpacing*axWidth);
    colSpacing = colSpacing*axWidth;
        
    for i=topElement:topElement+numBars-1
        currentBar = i-topElement+1;
        try
            dataRow = data(datamap(i));
            myFields = fields(dataRow);
            k = 1;
            for j=leftElement:rightElement
                ud.handles.text(currentBar,k) = text(colSpacing(k)+1, currentBar*barHeight, dataString(dataRow.(myFields{j}), maxLength(k)-1, ud.charSizes), 'verticalalignment', 'top', 'hittest', 'off', 'interpreter', 'none', 'clipping', 'on');    
                k = k+1;
            end
        catch
            %out of data, return;
            set(h, 'userdata', ud);
            return;
        end
    end
    set(h, 'userdata', ud);
return;        
    
    
    
    
function string = dataString(data, maxLength, charSizes)
%return a string that will be used in the field.
    datatype = class(data);
    maxLength = floor(maxLength);
    
    switch datatype
        case 'cell'
            string = [getSizeString(size(data)) ' cell'];
        case 'struct'
            string = [getSizeString(size(data)) ' struct'];
        case 'char'
            string = data;
        otherwise
            if size(data, 1) > 2
                string = [getSizeString(size(data)) ' numeric'];                           
            elseif isnumeric(data) | islogical(data)
                string = num2str(data);
            else
                string = '[Unrecognized Data]';
            end
    end
    
    if exist('charSizes')
        lengths = cumsum(charSizes(string+1));
        index = max(find(lengths<maxLength));
	
        %In case no characters will fit...
        if isempty(index) & ~isempty(lengths)
            string = '.';
            return;
        end
        
        if index<length(string)
            dotLength = sum(charSizes('...'));
            index = max(find((lengths+dotLength)<maxLength));        
            string = [string(1:index) '...'];    
        end
    end

function string = getSizeString(siz)
%Return a string replacement for siz.
    string = '[';
    for i=1:length(siz)-1
        string = [string num2str(siz(i)) 'x'];
    end
    string = [string num2str(siz(i+1)) ']'];
    
function colSpacing = getOptimumColSpacing(data, charSizes);
% data is a struct. Returns spacing that is mean of strings for allvals.

fields1 = fields(data);
for i=1:length(fields1)
    tally = 0;
    for j=1:length(data)
        string = dataString(data(j).(fields1{i}), inf, charSizes);
        tally = tally+length(string);
    end
    colSpacing(i) = tally/length(data);
end
colSpacing = colSpacing / sum(colSpacing);
colSpacing = cumsum(colSpacing);

function chars = getCharSizes(axis)
%Prints each Ascii character and captures the width in pixels of each.  
axes(axis);
oldUnits = get(axis, 'units');
set(axis, 'units', 'pixels');
h = text(1, 1, 1, '||', 'margin', .01, 'interpreter', 'none', 'units', 'pixels');
extent = get(h, 'extent');
delete(h);
baseline = extent(3);

for i=0:255
    h = text(1, 1, 1, ['|' char(i) '|'], 'margin', .01, 'interpreter', 'none', 'units', 'pixels');
    extent = get(h, 'extent');
    output(i+1) = extent(3) - baseline;
    delete(h);
end
chars = output;
set(axis, 'units', oldUnits);


function [sorted, x] = sortData(data)
%Sorts cell array vectors containing mixed datatypes.  Each datatype is first grouped
%together and then sorted, with (in ascending order)
%null < numeric < char < cell < struct.

sorted      = {};
x           = [];
nullInds    = [];
numericInds = [];
charInds    = [];
cellInds    = [];
structInds  = [];
for i = 1:length(data)
    classType = class(data{i});
    if isempty(data{i})
        classType = 'null';
    end
    if isnumeric(data{i}) | islogical(data{i})
        classType = 'numeric';
    end
    switch classType
        case 'null'
            nullInds = [nullInds i];
        case 'numeric'
            numericInds = [numericInds i];
        case 'char'
            charInds = [charInds i];
        case 'cell'
            cellInds = [cellInds i];
        case 'struct'
            structInds = [structInds i];
        otherwise
            error('Unrecognized Type.');
    end            
end

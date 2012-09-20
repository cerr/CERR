function varargout = structureFusionGui(command, varargin)
%"structureFusionGui" GUI
%   Create a GUI to combine and fuse CERR structures.
%
%   JRA
%
%Usage: structureFusionGui('init', planC)
%
% LM: APA, 7/21/06: (i) extended the figure window to the right, showing a new
% category: 'Intermediate'. (ii) Made second selection invalid if same strcuture
% is selected twice (e.g. PTV U PTV is not possible).
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
indexS = planC{end};

screenSize = get(0,'ScreenSize');
y = 446;
x = 838;
units = 'normalized';
maxStringSize = 45;

%command
if ~strcmpi(command, 'INIT')
    hFig = findobj('Tag', 'StuctureFusionFigure');
    userData = get(hFig, 'UserData');
end

switch upper(command)

    case 'INIT' %pass planC as an argument.
        h = findobj('tag', 'StuctureFusionFigure');

        %Close already open structure fusion GUIs.
        if ~isempty(h)
            delete(h)
        end

        indexS = planC{end};
        structures = {planC{indexS.structures}.structureName};
        if isempty(structures)
            warndlg('No Structures Present','Stucture Fusion');
            return
        end
        %Set up the GUI window, loading its graphical background.
        file = ['structureFusionBackground.png'];
        background = imread(file,'png');
        StuctureFusionFigure = figure('doublebuffer', 'on', 'units', 'pixels', 'position',[(screenSize(3)-x)/2 (screenSize(4)-y)/2 x y], 'MenuBar', 'none', 'NumberTitle', 'off', 'resize', 'off', 'Tag', 'StuctureFusionFigure', 'Color', [.75 .75 .75]);
        stateS.handle.structureFusionFig = StuctureFusionFigure;
        set(StuctureFusionFigure, 'Name','Structure Fusion');
        hAxis = axes('Position', [0 0 1 1]);
        image(background, 'CDataMapping', 'direct', 'ButtonDownFcn', 'structureFusionGui(''ButtonDown'', ''1'')', 'Tag', 'FusionBackgroundImage', 'parent', hAxis)
        axis(hAxis, 'off', 'image');

        %Layer buttons and text labels over the background
        uicontrol('units',units,'Position',[.12 .54 .05 .05],'String','1', 'Style', 'edit', 'Tag', 'GrowValue');
        uicontrol('units',units,'Position',[.12 .43 .05 .05],'String','1', 'Style', 'edit', 'Tag', 'ShrinkValue');
        uicontrol('units',units,'Position',[.12 .315 .05 .05],'String','1', 'Style', 'edit', 'Tag', 'Grow3DValue');
        uicontrol('units',units,'Position',[.12 .20 .05 .05],'String','1', 'Style', 'edit', 'Tag', 'Shrink3DValue');
        text('units',units,'Position',[.17 .56],'String','cm', 'Tag', 'units');
        text('units',units,'Position',[.17 .45],'String','cm', 'Tag', 'units');
        text('units',units,'Position',[.17 .33],'String','cm', 'Tag', 'units');
        text('units',units,'Position',[.17 .22],'String','cm', 'Tag', 'units');

        uicontrol('units',units,'Position',[.26 .04 .46 .05],'String','Status:', 'Style', 'frame');
        uicontrol('units',units,'Position',[.28 .05 .42 .03],'String','Status:', 'Style', 'text', 'HorizontalAlignment', 'left', 'ForegroundColor', [1 0 0], 'Tag', 'StatusText');

        uicontrol('units',units,'Position',[.26 .09 .46 .12], 'Style', 'frame');
        uicontrol('units',units,'Position',[.28 .15 .34 .05],'String','Select Structures followed by ''Make Intermediate''', 'Style', 'text', 'HorizontalAlignment', 'left');
        uicontrol('units',units,'Position',[.28 .10 .34 .05],'String','Page through structures', 'Style', 'text', 'HorizontalAlignment', 'left');
        uicontrol('units',units,'Position',[.43 .11 .05 .05],'String', '<-', 'Style', 'pushButton', 'Tag', 'PageBack', 'Callback', 'structureFusionGui(''PrevPage'')');
        uicontrol('units',units,'Position',[.49 .11 .05 .05],'String', '->', 'Style', 'pushButton', 'Tag', 'PageForward', 'Callback', 'structureFusionGui(''NextPage'')');
        uicontrol('units',units,'Position',[.58 .15 .12 .05],'String', 'Make Intermediate', 'Style', 'pushButton', 'Tag', 'makeIntermediate', 'Callback', 'structureFusionGui(''INTERMEDIATE'');');

        uicontrol('units',units,'Position',[.77 .15 .08 .05],'String', 'Make Struct', 'Tag', 'EvalButton', 'Style', 'toggle', 'Callback', 'structureFusionGui(''SELECTSTRUCTTOEVAL'');');
        uicontrol('units',units,'Position',[.85 .15 .05 .05],'String', 'Quit', 'Style', 'pushButton', 'Tag', 'QuitButton', 'Callback', 'structureFusionGui(''Quit'')');
        uicontrol('units',units,'Position',[.91 .15 .03 .05],'String', '<-', 'Style', 'pushButton', 'Tag', 'PageBack', 'Callback', 'structureFusionGui(''PrevPageUneval'')');
        uicontrol('units',units,'Position',[.94 .15 .03 .05],'String', '->', 'Style', 'pushButton', 'Tag', 'PageForward', 'Callback', 'structureFusionGui(''NextPageUneval'')');

        uicontrol('units',units,'Position',[.77 .04 .2 .1],'String','Select "Make Struct" followed by an intermediate structure', 'Style', 'text', 'HorizontalAlignment', 'center', 'ForegroundColor', [1 0 0]);
        
        % titles
        uicontrol('units',units,'Position',[.02 .925 .2 .04],'String','Select Operation', 'Style', 'text', 'HorizontalAlignment', 'center', 'ForegroundColor', [0 0 0],'fontSize',10, 'BackgroundColor', [.75 .75 .75],'fontWeight','bold');
        uicontrol('units',units,'Position',[.28 .925 .4 .04],'String','Existing Structures', 'Style', 'text', 'HorizontalAlignment', 'center', 'ForegroundColor', [0 0 0],'fontSize',10, 'BackgroundColor', [.75 .75 .75],'fontWeight','bold');
        uicontrol('units',units,'Position',[.77 .925 .2 .04],'String','Intermediate', 'Style', 'text', 'HorizontalAlignment', 'center', 'ForegroundColor', [0 0 0],'fontSize',10, 'BackgroundColor', [.75 .75 .75],'fontWeight','bold');
        
        % page numbers
        uicontrol('units',units,'Position',[.69 .925 .04 .04],'String','Pg. 1', 'Style', 'text', 'HorizontalAlignment', 'left', 'ForegroundColor', [0 0 0],'fontSize',10, 'BackgroundColor', [.75 .75 .75],'tag','pageNumExistStr');
        uicontrol('units',units,'Position',[.94 .925 .04 .04],'String','Pg. 1', 'Style', 'text', 'HorizontalAlignment', 'left', 'ForegroundColor', [0 0 0],'fontSize',10, 'BackgroundColor', [.75 .75 .75],'tag','pageNumUnevalStr');        

        userData                    = get(gcf, 'UserData');
        userData.currentStructure   = [];
        userData.lastStructure      = [];
        userData.currentOp          = 'INTERSECT';
        userData.hAxis              = hAxis;
        hText = text(160,62.5,' \leftarrow','FontSize',18, 'Tag', 'OpArrow');

        for i=1:length(structures)
            BGColor{i} = getColor(i, planC{indexS.CERROptions}.colorOrder);
            ForeColor{i} = setCERRLabelColor(i, planC{indexS.CERROptions});
            userData.structures(i).name = structures{i};
            userData.structures(i).op = 'Predefined';
            userData.structures(i).s1 = i;
            userData.structures(i).s2 = [];
            userData.structures(i).assocScan = getStructureAssociatedScan(i);
        end

        userData.currentPage = 1;
        userData.currentPageUneval = 1;
        set(StuctureFusionFigure,'userData',userData);
        listStructures(userData.structures, userData.currentPage, userData.currentPageUneval, planC);
        
        userData.BGColor            = BGColor;
        userData.ForeColor          = ForeColor;
        structureFusionGui('Status', 'Select two structures to intersect, or pick a different operation.');

    case 'QUIT'
        close;

    case 'STATUS'
        status = varargin{1};
        set(findobj('Tag', 'StatusText'), 'String', [status]);
        drawnow

    case 'BUTTONDOWN'
        h = gca;
        clickCoordinate = get(h, 'CurrentPoint');
        if clickCoordinate(1,1) > 13 & clickCoordinate(1,1) < 120 & clickCoordinate(1,2) > 50 & clickCoordinate(1,2) < 79
            delete(findobj('Tag', 'OpArrow'));
            hText = text(160,64.5,' \leftarrow','FontSize',18, 'Tag', 'OpArrow');
            userData.currentOp = 'INTERSECT';
            structureFusionGui('Status', 'Select two structures to intersect.');
            %userData.currentStructure = [];
            set(hFig,'userData',userData)
            listStructures(userData.structures, userData.currentPage, userData.currentPageUneval, planC);
        elseif clickCoordinate(1,1) > 13 & clickCoordinate(1,1) < 120 & clickCoordinate(1,2) > 86 & clickCoordinate(1,2) < 123
            delete(findobj('Tag', 'OpArrow'));
            hText = text(160,104.5,' \leftarrow','FontSize',18, 'Tag', 'OpArrow');
            userData.currentOp = 'DIFF';
            structureFusionGui('Status', 'Select two structures to subtract.');
            %userData.currentStructure = [];
            set(hFig,'userData',userData)
            listStructures(userData.structures, userData.currentPage, userData.currentPageUneval, planC);
        elseif clickCoordinate(1,1) > 13 & clickCoordinate(1,1) < 120 & clickCoordinate(1,2) > 130 & clickCoordinate(1,2) < 160
            delete(findobj('Tag', 'OpArrow'));
            hText = text(160,145,' \leftarrow','FontSize',18, 'Tag', 'OpArrow');
            userData.currentOp = 'UNION';
            structureFusionGui('Status', 'Select two structures to union.');
            %userData.currentStructure = [];
            set(hFig,'userData',userData)
            listStructures(userData.structures, userData.currentPage, userData.currentPageUneval, planC);
        elseif clickCoordinate(1,1) > 13 & clickCoordinate(1,1) < 120 & clickCoordinate(1,2) > 165 & clickCoordinate(1,2) < 209
            delete(findobj('Tag', 'OpArrow'));
            hText = text(160,187,' \leftarrow','FontSize',18, 'Tag', 'OpArrow');
            userData.currentOp = 'GROW';
            structureFusionGui('Status', 'Select one structure to add a margin to.');
            userData.lastStructure = [];
            set(hFig,'userData',userData)
            listStructures(userData.structures, userData.currentPage, userData.currentPageUneval, planC);
        elseif clickCoordinate(1,1) > 13 & clickCoordinate(1,1) < 120 & clickCoordinate(1,2) > 212 & clickCoordinate(1,2) < 260
            delete(findobj('Tag', 'OpArrow'));
            hText = text(160,236,' \leftarrow','FontSize',18, 'Tag', 'OpArrow');
            userData.currentOp = 'SHRINK';
            structureFusionGui('Status', 'Select one structure to subtract a margin from.');
            userData.lastStructure = [];
            set(hFig,'userData',userData)
            listStructures(userData.structures, userData.currentPage, userData.currentPageUneval, planC);
        elseif clickCoordinate(1,1) > 13 & clickCoordinate(1,1) < 120 & clickCoordinate(1,2) > 264 & clickCoordinate(1,2) < 310
            delete(findobj('Tag', 'OpArrow'));
            hText = text(160,287,' \leftarrow','FontSize',18, 'Tag', 'OpArrow');
            userData.currentOp = 'GROW3D';
            structureFusionGui('Status', 'Select one structure to add a 3D margin to.');
            userData.lastStructure = [];
            set(hFig,'userData',userData)
            listStructures(userData.structures, userData.currentPage, userData.currentPageUneval, planC);
        elseif clickCoordinate(1,1) > 13 & clickCoordinate(1,1) < 120 & clickCoordinate(1,2) > 313 & clickCoordinate(1,2) < 361
            delete(findobj('Tag', 'OpArrow'));
            hText = text(160,337,' \leftarrow','FontSize',18, 'Tag', 'OpArrow');
            userData.currentOp = 'SHRINK3D';
            structureFusionGui('Status', 'Select one structure to subtract 3D margin from.');
            userData.lastStructure = [];
            set(hFig,'userData',userData)
            listStructures(userData.structures, userData.currentPage, userData.currentPageUneval, planC);
        elseif clickCoordinate(1,1) > 13 & clickCoordinate(1,1) < 120 & clickCoordinate(1,2) > 366 & clickCoordinate(1,2) < 419
            delete(findobj('Tag', 'OpArrow'));
            hText = text(160,392.5,' \leftarrow','FontSize',18, 'Tag', 'OpArrow');
            userData.currentOp = 'FILL';
            structureFusionGui('Status', 'Select one structure to fill in empty slices.');
            userData.lastStructure = [];
            set(hFig,'userData',userData)
            listStructures(userData.structures, userData.currentPage, userData.currentPageUneval, planC);
        end

    case 'STRUCTURECLICK'
        if ~get(gcbo,'value')
            if userData.currentStructure == varargin{1}                
                userData.currentStructure = [];
                set(hFig, 'UserData',userData)
            elseif userData.lastStructure == varargin{1}
                userData.lastStructure = [];
                set(hFig, 'UserData',userData)
            end
            set(hFig, 'UserData',userData)
            listStructures(userData.structures, userData.currentPage, userData.currentPageUneval, planC);
            return;
        else
            if isempty(userData.lastStructure)
                userData.lastStructure = userData.currentStructure;
            end
            currentStructure = varargin{1};
            userData.currentStructure = currentStructure;
            set(hFig, 'UserData',userData)
            listStructures(userData.structures, userData.currentPage, userData.currentPageUneval, planC);
        end

        %check for eval
        state = get(findobj('Tag', 'EvalButton'), 'Value');
        if state == 1
            hStructText = findobj('style','text', 'Tag', 'StructureText');
            set(hStructText,'visible','off')
            structureFusionGui('EVALANDADD');
            set(findobj('Tag', 'EvalButton'), 'Value', 0);
            userData = get(findobj('Tag', 'StuctureFusionFigure'), 'UserData');
            userData.currentStructure = [];
            userData.lastStructure = [];
            set(findobj('Tag', 'StuctureFusionFigure'), 'UserData', userData);
            listStructures(userData.structures, userData.currentPage, userData.currentPageUneval, planC);
            return;
        end


    case 'INTERMEDIATE'
        structures = userData.structures;
        num = length(userData.structures) + 1;
        validStructure = 1;
        BGColor = userData.BGColor;
        ForeColor = userData.ForeColor;
        %switch varargin{1}
        switch upper(userData.currentOp)
            case 'UNION'
                if isempty(userData.lastStructure) | isempty(userData.currentStructure)
                    structureFusionGui('Status', 'Please choose structures A and B for union.');
                    return;
                end
                str = 'U';
                part1 = userData.structures(userData.lastStructure).name;
                part2 = userData.structures(userData.currentStructure).name;
                s1 = userData.lastStructure;
                s2 = userData.currentStructure;
                if ~isequal(userData.structures(userData.lastStructure).assocScan, userData.structures(userData.currentStructure).assocScan)
                    structureFusionGui('Status', 'Cannot fuse two structures that have different associated scans.');
                    validStructure = 0;
                else
                    userData.structures(num).assocScan = userData.structures(userData.lastStructure).assocScan;
                end
            case 'DIFF'
                if isempty(userData.lastStructure) | isempty(userData.currentStructure)
                    structureFusionGui('Status', 'Please choose structures A and B for difference.');
                    return;
                end
                str = '-';
                part1 = userData.structures(userData.lastStructure).name;
                part2 = userData.structures(userData.currentStructure).name;
                s1 = userData.lastStructure;
                s2 = userData.currentStructure;
                if ~isequal(userData.structures(userData.lastStructure).assocScan, userData.structures(userData.currentStructure).assocScan)
                    structureFusionGui('Status', 'Cannot fuse two structures that have different associated scans.');
                    validStructure = 0;
                else
                    userData.structures(num).assocScan = userData.structures(userData.lastStructure).assocScan;
                end
            case 'INTERSECT'
                if isempty(userData.lastStructure) | isempty(userData.currentStructure)
                    structureFusionGui('Status', 'Please choose structures A and B for intersection.');
                    return;
                end
                str = '\cap';
                part1 = userData.structures(userData.lastStructure).name;
                part2 = userData.structures(userData.currentStructure).name;
                s1 = userData.lastStructure;
                s2 = userData.currentStructure;
                if ~isequal(userData.structures(userData.lastStructure).assocScan, userData.structures(userData.currentStructure).assocScan)
                    structureFusionGui('Status', 'Cannot fuse two structures that have different associated scans.');
                    validStructure = 0;
                else
                    userData.structures(num).assocScan = userData.structures(userData.lastStructure).assocScan;
                end
            case 'GROW'
                if isempty(userData.currentStructure)
                    structureFusionGui('Status', 'Please choose a structure for adding margin.');
                    return;
                elseif isempty(get(findobj('Tag', 'GrowValue'), 'String')) | isempty(str2num(get(findobj('Tag', 'GrowValue'), 'String')))
                    structureFusionGui('Status', 'Margin value must be a valid number.');
                    return;
                end
                str = '+';
                part1 = userData.structures(userData.currentStructure).name;
                part2 = get(findobj('Tag', 'GrowValue'), 'String');
                s1 = userData.currentStructure;
                s2 = str2num(part2);
                userData.structures(num).assocScan = userData.structures(userData.currentStructure).assocScan;
            case 'SHRINK'
                if isempty(userData.currentStructure)
                    structureFusionGui('Status', 'Please choose a structure for subtracting margin.');
                    return;
                elseif isempty(get(findobj('Tag', 'ShrinkValue'), 'String')) | isempty(str2num(get(findobj('Tag', 'ShrinkValue'), 'String')))
                    structureFusionGui('Status', 'Margin value must be a valid number.');
                    return;
                end
                str = '-';
                part1 = userData.structures(userData.currentStructure).name;
                part2 = get(findobj('Tag', 'ShrinkValue'), 'String');
                s1 = userData.currentStructure;
                s2 = str2num(part2);
                userData.structures(num).assocScan = userData.structures(userData.currentStructure).assocScan;
            case 'GROW3D'
                if isempty(userData.currentStructure)
                    structureFusionGui('Status', 'Please choose a structure for adding 3D margin.');
                    return;
                elseif isempty(get(findobj('Tag', 'Grow3DValue'), 'String')) | isempty(str2num(get(findobj('Tag', 'Grow3DValue'), 'String')))
                    structureFusionGui('Status', 'Margin value must be a valid number.');
                    return;
                end
                str = '3D+';
                part1 = userData.structures(userData.currentStructure).name;
                part2 = get(findobj('Tag', 'Grow3DValue'), 'String');
                s1 = userData.currentStructure;
                s2 = str2num(part2);
                userData.structures(num).assocScan = userData.structures(userData.currentStructure).assocScan;
            case 'SHRINK3D'
                if isempty(userData.currentStructure)
                    structureFusionGui('Status', 'Please choose a structure for subtracting 3D margin.');
                    return;
                elseif isempty(get(findobj('Tag', 'Shrink3DValue'), 'String')) | isempty(str2num(get(findobj('Tag', 'Shrink3DValue'), 'String')))
                    structureFusionGui('Status', 'Margin value must be a valid number.');
                    return;
                end
                str = '3D-';
                part1 = userData.structures(userData.currentStructure).name;
                part2 = get(findobj('Tag', 'Shrink3DValue'), 'String');
                s1 = userData.currentStructure;
                s2 = str2num(part2);
                userData.structures(num).assocScan = userData.structures(userData.currentStructure).assocScan;                                
            case 'FILL'
                if isempty(userData.currentStructure)
                    structureFusionGui('Status', 'Please choose a structure for filling slice gaps.');
                    return;
                end
                str = 'Filled';
                part1 = userData.structures(userData.currentStructure).name;
                part2 = '';
                s1 = userData.currentStructure;
                s2 = [];                
                userData.structures(num).assocScan = userData.structures(userData.currentStructure).assocScan;
        end
        if validStructure
            userData.structures(num).op = userData.currentOp;
            userData.structures(num).s1 = s1;
            userData.structures(num).s2 = s2;
            userData.structures(num).name = ['(' part1 ' ' str ' ' part2 ')'];
            userData.currentPageUneval = max(1,ceil((length(structures(~strcmpi({structures.op},'Predefined')))+1)/16));
            userData.currentStructure = [];
            userData.lastStructure = [];
            
        end
        
        set(hFig,'userData',userData)
        listStructures(userData.structures, userData.currentPage, userData.currentPageUneval, planC);
        varargout{1} = userData;
        nargout = 1;

        return;

    case 'SELECTSTRUCTTOEVAL'
        state = get(findobj('Tag', 'EvalButton'), 'Value');
        if state == 1
            structureFusionGui('Status', 'Click a structure above to evaluate and add to the plan.');
        else
            structureFusionGui('Status', 'Ready.');
        end

    case 'EVALANDADD'
        if(strcmpi(userData.structures(userData.currentStructure).op, 'Predefined'))
            structureFusionGui('Status', 'Selected Structure Already exists. Only intermediate structures can be added.');
            return;
        end
        indexS = planC{end};
        structureName = userData.structures(userData.currentStructure).name;
        scanNum       = userData.structures(userData.currentStructure).assocScan;
        %         [xSize,ySize,zSize] = size(planC{indexS.scan}(scanNum).scanArray);
        [xSize,ySize,zSize] = size(getScanArray(planC{indexS.scan}(scanNum)));
        
        rasterSegs = structureFusionGui('EVALUATE', userData.currentStructure, planC);
        structureFusionGui('Status', ['Creating Contour of ' structureName]);
        contour = rasterToPoly(rasterSegs, scanNum, planC);
        structureFusionGui('Status', 'Saving new structure to plan.');
        newStr = newCERRStructure(scanNum);
        numStructs = length(planC{planC{end}.structures});
        toAdd = numStructs + 1;
        newStr.rasterSegments = rasterSegs;
        newStr.contour = contour;
        newStr.structureName = userData.structures(userData.currentStructure).name;
        newStr.associatedScan = scanNum;
        newStr.strUID = createUID('structure');
        newStr.assocScanUID = planC{indexS.scan}(scanNum).scanUID;
        newStr.visible = 1;        
        planC{indexS.structures} = dissimilarInsert(planC{indexS.structures}, newStr, toAdd);
        userData.structures(userData.currentStructure).op = 'Predefined';
        set(findobj('Tag', 'StuctureFusionFigure'), 'UserData', userData);
        listStructures(userData.structures, userData.currentPage, userData.currentPageUneval, planC);
        planC = updateStructureMatrices(planC, numStructs+1);
        hAxis = userData.hAxis;
        hFig  = get(userData.hAxis, 'parent');
        set(hAxis, 'nextplot', 'add');
        stateS.structsChanged = 1;
        sliceCallBack('refresh');
        figure(hFig);
        set(hAxis, 'nextplot', 'replace');
        structureFusionGui('Status', 'Ready.');

    case 'EVALUATE'
        nargout = 1;
        structToEval = varargin{1};
        scanNum = userData.structures(structToEval).assocScan;
        planC = varargin{2};
        indexS = planC{end};

        switch userData.structures(structToEval).op
            case 'Predefined'
                structureFusionGui('Status', ['Processing substructure ' userData.structures(structToEval).name]);
                [varargout{1}, planC, isError] = getRasterSegments(structToEval, planC);
                %varargout{1} = planC{indexS.structures}(structToEval).rasterSegments;
            case 'UNION'
                segs1 = structureFusionGui('EVALUATE', userData.structures(structToEval).s1, planC);
                segs2 = structureFusionGui('EVALUATE', userData.structures(structToEval).s2, planC);
                structureFusionGui('Status', ['Processing substructure ' userData.structures(structToEval).name]);
                varargout{1} = structUnion(segs1, segs2, scanNum, planC);
            case 'DIFF'
                segs1 = structureFusionGui('EVALUATE', userData.structures(structToEval).s1, planC);
                segs2 = structureFusionGui('EVALUATE', userData.structures(structToEval).s2, planC);
                structureFusionGui('Status', ['Processing substructure ' userData.structures(structToEval).name]);
                varargout{1} = structDiff(segs1, segs2, scanNum, planC);
            case 'INTERSECT'
                segs1 = structureFusionGui('EVALUATE', userData.structures(structToEval).s1, planC);
                segs2 = structureFusionGui('EVALUATE', userData.structures(structToEval).s2, planC);
                structureFusionGui('Status', ['Processing substructure ' userData.structures(structToEval).name]);
                varargout{1} = structIntersect(segs1, segs2, scanNum, planC);
            case 'GROW'
                segs1 = structureFusionGui('EVALUATE', userData.structures(structToEval).s1, planC);
                structureFusionGui('Status', ['Processing substructure ' userData.structures(structToEval).name]);
                halo = structMargin(segs1, userData.structures(structToEval).s2, scanNum, planC);
                varargout{1} = structUnion(halo, segs1, scanNum, planC);
            case 'SHRINK'
                segs1 = structureFusionGui('EVALUATE', userData.structures(structToEval).s1, planC);
                structureFusionGui('Status', ['Processing substructure ' userData.structures(structToEval).name]);
                halo = structMargin(segs1, userData.structures(structToEval).s2, scanNum, planC);
                varargout{1} = structDiff(segs1, halo, scanNum, planC);

            case 'GROW3D'
                structureFusionGui('Status', ['Processing substructure ' userData.structures(structToEval).name]);
                maskM = getSurfaceExpand(userData.structures(structToEval).s1, userData.structures(structToEval).s2, 1);                
                %If registered to uniformized data, use nearest slice neighbor
                %interpolation.
                [xUni, yUni, zUni] = getUniformScanXYZVals(planC{indexS.scan}(userData.structures(structToEval).assocScan));
                [xSca, ySca, zSca] = getScanXYZVals(planC{indexS.scan}(userData.structures(structToEval).assocScan));
                unisiz = getUniformScanSize(planC{indexS.scan}(userData.structures(structToEval).assocScan));
                normsiz = size(getScanArray(planC{indexS.scan}(userData.structures(structToEval).assocScan)));
                tmpM = false(normsiz);
                for i=1:normsiz(3)
                    zVal = zSca(i);
                    uB = find(zUni > zVal, 1 );
                    lB = find(zUni <= zVal, 1, 'last' );
                    if isempty(uB) || isempty(lB)
                        continue
                    end
                    if abs(zUni(uB) - zVal) < abs(zUni(lB) - zVal)
                        tmpM(:,:,i) = logical(maskM(:,:,uB));
                    else
                        tmpM(:,:,i) = logical(maskM(:,:,lB));
                    end
                end
                varargout{1} = maskToRaster(tmpM, 1:normsiz(3), userData.structures(structToEval).assocScan, planC);
            case 'SHRINK3D'
                structureFusionGui('Status', ['Processing substructure ' userData.structures(structToEval).name]);                
                maskM = getSurfaceContract(userData.structures(structToEval).s1, userData.structures(structToEval).s2, 1);
                %If registered to uniformized data, use nearest slice neighbor
                %interpolation.
                [xUni, yUni, zUni] = getUniformScanXYZVals(planC{indexS.scan}(userData.structures(structToEval).assocScan));
                [xSca, ySca, zSca] = getScanXYZVals(planC{indexS.scan}(userData.structures(structToEval).assocScan));
                unisiz = getUniformScanSize(planC{indexS.scan}(userData.structures(structToEval).assocScan));
                normsiz = size(getScanArray(planC{indexS.scan}(userData.structures(structToEval).assocScan)));
                tmpM = repmat(logical(0), normsiz);
                for i=1:normsiz(3)
                    zVal = zSca(i);
                    uB = min(find(zUni > zVal));
                    lB = max(find(zUni <= zVal));
                    if isempty(uB) | isempty(lB)
                        continue
                    end
                    if abs(zUni(uB) - zVal) < abs(zUni(lB) - zVal)
                        tmpM(:,:,i) = logical(maskM(:,:,uB));
                    else
                        tmpM(:,:,i) = logical(maskM(:,:,lB));
                    end
                end
                varargout{1} = maskToRaster(tmpM, 1:normsiz(3), userData.structures(structToEval).assocScan, planC);

            case 'FILL'
                segs1 = structureFusionGui('EVALUATE', userData.structures(structToEval).s1, planC);
                structureFusionGui('Status', ['Processing substructure ' userData.structures(structToEval).name]);
                varargout{1} = structFillin(segs1, scanNum, planC);
        end
        
    case 'NEXTPAGE'
        structures = userData.structures;
        structuresPreDefIndexV = find(strcmpi({structures.op},'Predefined'));
        nPreDef = length(structuresPreDefIndexV);
        if userData.currentPage < ceil(nPreDef/32)
            userData.currentPage = userData.currentPage + 1;
            set(hFig,'userData',userData)
            listStructures(userData.structures, userData.currentPage, userData.currentPageUneval, planC);
        end
    case 'PREVPAGE'
        if userData.currentPage > 1
            userData.currentPage = userData.currentPage - 1;
            set(hFig,'userData',userData)
            listStructures(userData.structures, userData.currentPage, userData.currentPageUneval, planC);
        end
    case 'NEXTPAGEUNEVAL'
        structures = userData.structures;
        structuresNoPreDefIndexV = find(~strcmpi({structures.op},'Predefined'));
        nNoPreDef = length(structuresNoPreDefIndexV);
        if userData.currentPageUneval < ceil(nNoPreDef/16)
            userData.currentPageUneval = userData.currentPageUneval + 1;
            set(hFig,'userData',userData)
            listStructures(userData.structures, userData.currentPage, userData.currentPageUneval, planC);
        end
    case 'PREVPAGEUNEVAL'
        if userData.currentPageUneval > 1
            userData.currentPageUneval = userData.currentPageUneval - 1;
            set(hFig,'userData',userData)
            listStructures(userData.structures, userData.currentPage, userData.currentPageUneval, planC);
        end
end

set(findobj('Tag', 'StuctureFusionFigure'), 'UserData', userData);


function listStructures(structures, page, pageUneval, planC)
units = 'normalized';
indexS = planC{end};
delete(findobj('Tag', 'StructureText'));
maxStringSize=22;
maxStructsPerColumn = 16;
maxStructsPerPage = maxStructsPerColumn*2;
firstElement = page * maxStructsPerPage + 1;
colorNum = 1;
hStrFusGUI = findobj('tag', 'StuctureFusionFigure');
userData = get(hStrFusGUI,'userData');

% list Predefined structures
structuresPreDefIndexV = find(strcmpi({structures.op},'Predefined'));
nPreDef = min(length(structuresPreDefIndexV)-(page-1)*maxStructsPerPage, maxStructsPerPage);
for i=1:nPreDef
    structNum = structuresPreDefIndexV((page-1)*maxStructsPerPage + i);
    if structNum > length(planC{indexS.structures})
        BGColor{structNum} = getColor(structNum, planC{indexS.CERROptions}.colorOrder);
    else
        BGColor{structNum} = planC{indexS.structures}(structNum).structureColor;
    end
    ForeColor{structNum} = setCERRLabelColor(structNum, planC{indexS.CERROptions});    
    colorNum = colorNum+1;
    string = structures(structNum).name;
    hstructToggle = uicontrol(hStrFusGUI ,'style', 'toggle', 'Tag', 'StructureText', 'units',units,'Position',[.27 + floor((i-1)/maxStructsPerColumn)*.25, .85 - mod(i-1,maxStructsPerColumn)*.038, .20, .038],'String', stringResize(string, maxStringSize), 'ForegroundColor', BGColor{structNum},'Callback', ['structureFusionGui(''StructureClick'', ' num2str(structNum) ');'], 'FontName', 'Courier','HorizontalAlignment', 'left', 'TooltipString', string);
    hpanel = uicontrol(hStrFusGUI , 'units',units, 'style','text', 'Tag', 'StructureText','Position',[.25 + floor((i-1)/maxStructsPerColumn)*.25, .85 - mod(i-1,maxStructsPerColumn)*.038, .02, .038],'string','','visible','off');
    if isempty(userData.lastStructure) & ~isempty(userData.currentStructure) & (structNum == userData.currentStructure)
        set(hpanel,'ForegroundColor',[0 0 0],'BackgroundColor',[0.75 0.75 0.75],'visible','on','string','A','FontAngle','italic','FontWeight','bold')
        set(hstructToggle,'value',1)
    end
    if ~isempty(userData.lastStructure) & (structNum == userData.lastStructure)
        set(hpanel,'ForegroundColor',[0 0 0],'BackgroundColor',[0.75 0.75 0.75],'visible','on','string','A','FontAngle','italic','FontWeight','bold')
        set(hstructToggle,'value',1)
    end
    if ~isempty(userData.currentStructure) & ~isempty(userData.lastStructure) & (structNum == userData.currentStructure)
        set(hpanel,'ForegroundColor',[0 0 0],'BackgroundColor',[0.75 0.75 0.75],'visible','on','string','B','FontAngle','italic','FontWeight','bold')
        set(hstructToggle,'value',1)
    end
end

% list other than Predefined structures
structuresNoPreDefIndexV = find(~strcmpi({structures.op},'Predefined'));
nNoPreDef = min(length(structuresNoPreDefIndexV)-(pageUneval-1)*maxStructsPerColumn, maxStructsPerColumn);
for i=1:nNoPreDef
    structNum = structuresNoPreDefIndexV((pageUneval-1)*maxStructsPerColumn + i);
    BGColor{structNum} = [.5 .5 .5];
    ForeColor{structNum} = [0 0 0];
    string = structures(structNum).name;
    hstructToggle = uicontrol(hStrFusGUI ,'style', 'toggle', 'Tag', 'StructureText', 'units',units,'Position',[.78 + floor((i-1)/maxStructsPerColumn)*.315, .85 - mod(i-1,maxStructsPerColumn)*.038, .20, .038],'String', stringResize(string, maxStringSize), 'ForegroundColor', ForeColor{structNum},'Callback', ['structureFusionGui(''StructureClick'', ' num2str(structNum) ');'], 'FontName', 'Courier','HorizontalAlignment', 'left', 'TooltipString', string);
    hpanel = uicontrol(hStrFusGUI , 'units',units, 'style','text', 'Tag', 'StructureText','Position',[.76 + floor((i-1)/maxStructsPerColumn)*.25, .85 - mod(i-1,maxStructsPerColumn)*.038, .02, .038],'string','','visible','off');
    if isempty(userData.lastStructure) & ~isempty(userData.currentStructure) & (structNum == userData.currentStructure)
        set(hpanel,'ForegroundColor',[0 0 0],'BackgroundColor',[0.75 0.75 0.75],'visible','on','string','A','FontAngle','italic','FontWeight','bold')
        set(hstructToggle,'value',1)
    end
    if ~isempty(userData.lastStructure) & (structNum == userData.lastStructure)
        set(hpanel,'ForegroundColor',[0 0 0],'BackgroundColor',[0.75 0.75 0.75],'visible','on','string','A','FontAngle','italic','FontWeight','bold')
        set(hstructToggle,'value',1)
    end
    if ~isempty(userData.currentStructure) & ~isempty(userData.lastStructure) & (structNum == userData.currentStructure)
        set(hpanel,'ForegroundColor',[0 0 0],'BackgroundColor',[0.75 0.75 0.75],'visible','on','string','B','FontAngle','italic','FontWeight','bold')
        set(hstructToggle,'value',1)
    end
end

% update page number display
HpageNumUneval = findobj('tag','pageNumUnevalStr');
HpageNumExist = findobj('tag','pageNumExistStr');
set(HpageNumExist,'string',['Pg. ',num2str(page)])
set(HpageNumUneval,'string',['Pg. ',num2str(pageUneval)])


function output = stringResize(string, size)
%takes string, pads it with blanks on both sides if it is smaller than
%size, and cuts off its end characters if it is longer than size.
%string = string{1};
numChars = length(string);
if numChars > size
    output = [string(1:size-3) '...'];
elseif numChars == size
    output = string;
else
    numToPad = size - numChars;
    startPadNum = floor(numToPad/2);
    endPadNum = numToPad - startPadNum;
    startPad = char(ones(startPadNum, 1)' * char(' '));
    endPad = char(ones(endPadNum, 1)' * char(' '));
    output = [startPad string endPad];
end
return

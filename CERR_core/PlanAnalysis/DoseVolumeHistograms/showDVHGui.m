function showDVHGui(command, varargin)
%"showDVHGui"
%
%Usage:
%   With a planC loaded: showDVHGui()
%
%  Create a GUI to display, plot and manipulate DVHs.
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

global stateS planC
indexS = planC{end};

if ~exist('command')
    command = 'INIT';
end

%Find old DVHGui figure.
hFig = findobj('Tag', 'DVHGui');

%If old figure exists, refresh it.
if isempty(hFig) & ~strcmpi(command, 'INIT')
    error('DVHGui no longer exists. Callback failed.');
    return;
elseif ~isempty(hFig) & strcmpi(command, 'INIT')
    figure(hFig);
    showDVHGui('REFRESH')
    return;
end

switch upper(command)
    case 'INIT'
        units = 'pixels';
        screenSize = get(0,'ScreenSize');
        w = 800; h = 600;

        %Initial size of figure in pixels. Figure scales fairly well.
        hFig = figure('name', 'DVH Menu', 'units', units, 'position',[(screenSize(3)-w)/2 (screenSize(4)-h)/2 w h], 'MenuBar', 'none', 'NumberTitle', 'off', 'resize', 'on', 'Tag', 'DVHGui', 'DoubleBuffer', 'on');
        stateS.handle.DVHMenuFigure = hFig;
        ud.figure.w = w; ud.figure.h = h;

        %Set up add frame
        afX = 10; afW = w - 2*afX; afH = 50; afY = h - 10 - afH;
        ud.af.X = afX; ud.af.W = afW; ud.af.H = afH; ud.af.Y = afY;
        uicontrol(hFig, 'style', 'frame', 'units', units, 'position', [afX afY afW afH], 'enable', 'inactive');
        uicontrol(hFig, 'style', 'text', 'units', units, 'position', [afX afY+afH - 15 65 15], 'string', 'Add DVH', 'fontweight', 'bold');

        %Set up DVH list frame
        dfX = 10; dfW = w - 2*dfX; dfY = 10; dfH = afY - 10 - dfY;
        ud.df.X = dfX; ud.df.W = dfW; ud.df.Y = dfY; ud.df.H = dfH;
        hDf = uicontrol(hFig, 'style', 'frame', 'units', units, 'position', [dfX dfY dfW dfH], 'enable', 'inactive');
        uicontrol(hFig, 'style', 'text', 'units', units, 'position', [dfX dfY+dfH - 15 65 15], 'string', 'DVH/DSHs', 'fontweight', 'bold');
        frameColor = get(hDf, 'backgroundcolor');

        %Setup dose list item and tag.
        doseList = {planC{indexS.dose}.fractionGroupID};
        uicontrol(hFig, 'style', 'text', 'units', units, 'position',[afX+10 afY + 7 53 22], 'string', 'DoseSet:', 'horizontalAlignment', 'left');
        if isempty(stateS.doseSet)
            initialDoseNum = 1;
        else
            initialDoseNum = stateS.doseSet;
        end
        ud.af.handles.dose = uicontrol(hFig, 'style', 'popupmenu', 'units', units, 'position',  [afX+10+55 afY + 10 110 22] , 'string', doseList, 'value', initialDoseNum, 'horizontalAlignment', 'left', 'callback', 'showDVHGui(''DOSEPICKED'')','Tag','doseSelectTag');

        %Setup structure list item and tag.
        prefix = 'Select a structure.';
        strList = {prefix, planC{indexS.structures}.structureName};
        uicontrol(hFig, 'style', 'text', 'units', units, 'position', [afX+75+110 afY + 7 53 22] , 'string', 'Structure:', 'horizontalAlignment', 'left');
        ud.af.handles.structure = uicontrol(hFig, 'style', 'popupmenu', 'units', units, 'position',[afX+75+110+55 afY + 10 120 22], 'string', strList, 'horizontalAlignment', 'left','Tag','structSelectTag');
        uicontrol(hFig, 'style', 'pushbutton', 'units', units, 'position',[afX+75+110+55+140 afY + 10 60 22], 'string', 'Add DVH', 'horizontalAlignment', 'center', 'callback', 'showDVHGui(''ADDDVH'')');

        %Add newFigure checkbox and tag.
        ud.af.newPlot = 0;
        uicontrol(hFig, 'style', 'text', 'units', units, 'position', [afX+460 afY+0.5 70 22], 'string', 'New figure:', 'horizontalAlignment', 'left');
        uicontrol(hFig, 'style', 'checkbox', 'units', units, 'position', [afX+520 afY+5.5 20 22], 'value', ud.af.newPlot, 'horizontalAlignment', 'left', 'callback', 'showDVHGui(''NEWFIGCLICKED'')');

        % Add std Deviation flag
        ud.af.stdavgDVH = 0;
        uicontrol(hFig, 'style', 'text', 'units', units, 'position', [afX+460 afY+20 70 22], 'string', 'Std Avg DVH:', 'horizontalAlignment', 'left');
        uicontrol(hFig, 'style', 'checkbox', 'units', units, 'position', [afX+520 afY+23 20 22], 'value', ud.af.stdavgDVH, 'horizontalAlignment', 'left', 'callback', 'showDVHGui(''STDDVHVLICKED'')');

        %Add grid checkbox and tag.
        ud.af.grid = 1;
        uicontrol(hFig, 'style', 'text', 'units', units, 'position', [afX+560 afY + 7 70 22], 'string', 'Gridlines:', 'horizontalAlignment', 'left');
        uicontrol(hFig, 'style', 'checkbox', 'units', units, 'position', [afX+610 afY + 10 20 22], 'value', ud.af.grid, 'horizontalAlignment', 'left', 'callback', 'showDVHGui(''GRIDCLICKED'')');

        %Add plot button and tag.
        uicontrol(hFig, 'style', 'pushbutton', 'units', units, 'position', [afX+640 afY + 25 100 20], 'string', 'Plot Cumulative', 'horizontalAlignment', 'left', 'callback', 'showDVHGui(''PLOT'',''CUMU'')');
        uicontrol(hFig, 'style', 'pushbutton', 'units', units, 'position', [afX+640 afY + 2 100 20], 'string', 'Plot Differential', 'horizontalAlignment', 'left', 'callback', 'showDVHGui(''PLOT'',''DIFF'')');

        %Set parameters for each row of DVHs
        ud.df.rowH = 20;
        ud.df.rowW = w - 20;

        %Calculate maxNum of rows that can be displayed.
        ud.df.nRows = floor(ud.df.H / ud.df.rowH) - 3;

        %Create row headers.
        uicontrol(hFig, 'style', 'text', 'units', units, 'position', [dfX+30 dfY+dfH-15-ud.df.rowH 100 15], 'string', 'Structure', 'horizontalAlignment', 'center');
        uicontrol(hFig, 'style', 'text', 'units', units, 'position', [dfX+140 dfY+dfH-15-ud.df.rowH 30 15], 'string', 'Vol', 'horizontalAlignment', 'center');
        uicontrol(hFig, 'style', 'text', 'units', units, 'position', [dfX+170 dfY+dfH-15-ud.df.rowH 30 15], 'string', 'Surf', 'horizontalAlignment', 'center');
        uicontrol(hFig, 'style', 'text', 'units', units, 'position', [dfX+200 dfY+dfH-15-ud.df.rowH 30 15], 'string', 'Avg', 'horizontalAlignment', 'center');
        uicontrol(hFig, 'style', 'text', 'units', units, 'position', [dfX+230 dfY+dfH-15-ud.df.rowH 30 15], 'string', 'Abs', 'horizontalAlignment', 'center');
        uicontrol(hFig, 'style', 'text', 'units', units, 'position', [dfX+270 dfY+dfH-15-ud.df.rowH 35 15], 'string', 'Comp', 'horizontalAlignment', 'center');
        uicontrol(hFig, 'style', 'text', 'units', units, 'position', [dfX+dfW-58 dfY+dfH-15-ud.df.rowH 30 15], 'string', 'Delete', 'horizontalAlignment', 'center');

        midW = dfW - 280 - 58;
        fieldW = [60 120 80 80 80];
        uicontrol(hFig, 'style', 'text', 'units', units, 'position', [dfX+305 dfY+dfH-15-ud.df.rowH fieldW(1) 15], 'string', 'planID', 'horizontalAlignment', 'center');
        uicontrol(hFig, 'style', 'text', 'units', units, 'position', [dfX+280+(fieldW(1))+10 dfY+dfH-15-ud.df.rowH fieldW(2) 15], 'string', 'FractionGroupID', 'horizontalAlignment', 'center');
        uicontrol(hFig, 'style', 'text', 'units', units, 'position', [dfX+280+(sum(fieldW(1:2))) dfY+dfH-15-ud.df.rowH fieldW(3) 15], 'string', 'Dose Index', 'horizontalAlignment', 'center');
        uicontrol(hFig, 'style', 'text', 'units', units, 'position', [dfX+280+(sum(fieldW(1:3))) dfY+dfH-15-ud.df.rowH fieldW(4) 15], 'string', 'Structure Index', 'horizontalAlignment', 'center');
        uicontrol(hFig, 'style', 'text', 'units', units, 'position', [dfX+280+(sum(fieldW(1:4))) dfY+dfH-15-ud.df.rowH fieldW(5) 15], 'string', 'dateOfDVH', 'horizontalAlignment', 'center');

        ud.df.handles.volMaster   = uicontrol(hFig, 'style', 'checkbox', 'units', units, 'position', [dfX+150 dfY+dfH-15-ud.df.rowH - ud.df.rowH 20 15], 'horizontalAlignment', 'center', 'visible', 'on', 'userdata', 1, 'callback', 'showDVHGui(''VOLMASTER'')');
        ud.df.handles.surfMaster  = uicontrol(hFig, 'style', 'checkbox', 'units', units, 'position', [dfX+180 dfY+dfH-15-ud.df.rowH - ud.df.rowH 20 15], 'horizontalAlignment', 'center', 'visible', 'on', 'userdata', 1, 'callback', 'showDVHGui(''SURFMASTER'')');
        ud.df.handles.avgMaster   = uicontrol(hFig, 'style', 'checkbox', 'units', units, 'position', [dfX+210 dfY+dfH-15-ud.df.rowH - ud.df.rowH 20 15], 'horizontalAlignment', 'center', 'visible', 'on', 'userdata', 1, 'callback', 'showDVHGui(''AVGMASTER'')');
        ud.df.handles.absMaster   = uicontrol(hFig, 'style', 'radiobutton', 'units', units, 'position', [dfX+240 dfY+dfH-15-ud.df.rowH - ud.df.rowH 20 15], 'horizontalAlignment', 'center', 'visible', 'on', 'userdata', 1, 'callback', 'showDVHGui(''ABSMASTER'')');

        ud.df.handles.delMaster   = uicontrol(hFig, 'style', 'pushbutton', 'units', units, 'position', [dfX+dfW-58-25/2 dfY+dfH-15-ud.df.rowH-1-ud.df.rowH 25*2 19], 'string', 'DelAll', 'horizontalAlignment', 'center', 'visible', 'on', 'userdata', 1, 'callback', 'showDVHGui(''DELMASTER'')');
        ud.df.handles.delStale    = uicontrol(hFig, 'style', 'pushbutton', 'units', units, 'position', [dfX+280+sum(fieldW(1:2))+20/2 dfY+dfH-15-ud.df.rowH-1-ud.df.rowH 25*2 19], 'string', 'DelStale', 'horizontalAlignment', 'center', 'visible', 'off', 'userdata', 1, 'callback', 'showDVHGui(''DELSTALE'')');

        %Create rows and make them invisible.
        for i = 1:ud.df.nRows
            if i/2 == floor(i/2)
                bgColor = frameColor;
            else
                bgColor = [.9 .9 .9];
            end
            ud.df.handles.bgTxt(i) = uicontrol(hFig, 'style', 'text', 'units', units, 'position', [20 dfY+dfH-15-ud.df.rowH - ud.df.rowH*(i+1)-2 ud.df.rowW-20 ud.df.rowH], 'string', '', 'horizontalAlignment', 'center', 'visible', 'off', 'userdata', i, 'backgroundcolor', bgColor);

            ud.df.handles.ind(i)   = uicontrol(hFig, 'style', 'text', 'units', units, 'position', [dfX+10 dfY+dfH-15-ud.df.rowH - ud.df.rowH*(i+1) 20 15], 'string', [num2str(i) '.'], 'horizontalAlignment', 'center', 'visible', 'off', 'userdata', i);
            ud.df.handles.name(i)  = uicontrol(hFig, 'style', 'text', 'units', units, 'position', [dfX+30 dfY+dfH-15-ud.df.rowH - ud.df.rowH*(i+1) 100 15], 'string', 'Brain', 'horizontalAlignment', 'center', 'visible', 'off', 'userdata', i);
            ud.df.handles.vol(i)   = uicontrol(hFig, 'style', 'checkbox', 'units', units, 'position', [dfX+150 dfY+dfH-15-ud.df.rowH - ud.df.rowH*(i+1) 20 15], 'horizontalAlignment', 'center', 'visible', 'off', 'userdata', i, 'callback', 'showDVHGui(''VOL'')');
            ud.df.handles.surf(i)  = uicontrol(hFig, 'style', 'checkbox', 'units', units, 'position', [dfX+180 dfY+dfH-15-ud.df.rowH - ud.df.rowH*(i+1) 20 15], 'horizontalAlignment', 'center', 'visible', 'off', 'userdata', i, 'callback', 'showDVHGui(''SURF'')');
            ud.df.handles.avg(i)   = uicontrol(hFig, 'style', 'checkbox', 'units', units, 'position', [dfX+210 dfY+dfH-15-ud.df.rowH - ud.df.rowH*(i+1) 20 15], 'horizontalAlignment', 'center', 'visible', 'off', 'userdata', i, 'callback', 'showDVHGui(''AVG'')');

            ud.df.handles.abs(i)   = uicontrol(hFig, 'style', 'radiobutton', 'units', units, 'position', [dfX+240 dfY+dfH-15-ud.df.rowH - ud.df.rowH*(i+1) 20 15], 'horizontalAlignment', 'center', 'visible', 'off', 'userdata', i, 'callback', 'showDVHGui(''ABS'')');
            ud.df.handles.comp(i)  = uicontrol(hFig, 'style', 'text', 'units', units, 'position', [dfX+270 dfY+dfH-15-ud.df.rowH - ud.df.rowH*(i+1) 30 15], 'string', 'Y', 'horizontalAlignment', 'center', 'visible', 'off', 'userdata', i);
            ud.df.handles.del(i)   = uicontrol(hFig, 'style', 'pushbutton', 'units', units, 'position', [dfX+dfW-58 dfY+dfH-15-ud.df.rowH-1 - ud.df.rowH*(i+1) 25 19], 'string', '-', 'horizontalAlignment', 'center', 'visible', 'off', 'userdata', i, 'callback', 'showDVHGui(''DELDVH'')');

            ud.df.handles.pID(i)   = uicontrol(hFig, 'style', 'text', 'units', units, 'position', [dfX+310 dfY+dfH-15-ud.df.rowH - ud.df.rowH*(i+1) fieldW(1) 15], 'string', '2', 'horizontalAlignment', 'center', 'visible', 'off', 'userdata', i);
            ud.df.handles.fID(i)   = uicontrol(hFig, 'style', 'text', 'units', units, 'position', [dfX+280+(fieldW(1)+10) dfY+dfH-15-ud.df.rowH - ud.df.rowH*(i+1) fieldW(2) 15], 'string', 'fd', 'horizontalAlignment', 'center', 'visible', 'off', 'userdata', i);
            ud.df.handles.dInd(i)  = uicontrol(hFig, 'style', 'text', 'units', units, 'position', [dfX+280+(sum(fieldW(1:2))) dfY+dfH-15-ud.df.rowH - ud.df.rowH*(i+1) fieldW(3) 15], 'string', '1', 'horizontalAlignment', 'center', 'visible', 'off', 'userdata', i);            
            ud.df.handles.SInd(i)  = uicontrol(hFig, 'style', 'text', 'units', units, 'position', [dfX+280+(sum(fieldW(1:3))) dfY+dfH-15-ud.df.rowH - ud.df.rowH*(i+1) fieldW(3) 15], 'string', '1', 'horizontalAlignment', 'center', 'visible', 'off', 'userdata', i);            
            ud.df.handles.date(i)  = uicontrol(hFig, 'style', 'text', 'units', units, 'position', [dfX+280+(sum(fieldW(1:4))) dfY+dfH-15-ud.df.rowH - ud.df.rowH*(i+1) fieldW(4) 15], 'string', date, 'horizontalAlignment', 'center', 'visible', 'off', 'userdata', i);
        end

        nDVH = length(planC{indexS.DVH});
        ud.state.vol  = zeros(1,nDVH);
        ud.state.surf = zeros(1,nDVH);
        ud.state.avg  = zeros(1,nDVH);
        ud.state.abs  = zeros(1,nDVH);


        %Create scrollbar on right side. Inactive to start.
        ud.df.handles.scroll = uicontrol(hFig, 'style', 'slider', 'units', units, 'position', [dfX-1+dfW-20 dfY+1 20 dfH], 'enable', 'off', 'callback', 'showDVHGui(''SLIDER'')');

        %Set range of currently displayed DVHs.
        ud.df.range = 1:min(i, nDVH);
        set(hFig, 'userdata', ud);
        drawnow;

        set(get(hFig, 'children'), 'units', 'normalized');

        %Check for stale DVHs... later examine doseSig field.
        %         [isStale, planC] = findStaleDVHs(planC);

        showDVHGui('REFRESH');

    case 'DELMASTER'
        ud = get(hFig, 'userdata');
        if length(planC{indexS.DVH}) > 0
            planC{indexS.DVH}(1:end) = [];
            ud.state.vol (1:end) = [];
            ud.state.surf(1:end) = [];
            ud.state.avg (1:end) = [];
            ud.state.abs (1:end) = [];
        end

        nRows = ud.df.nRows;
        nDVH  = length(planC{indexS.DVH});
        if nDVH < nRows
            ud.df.range = 1:nDVH;
        elseif max(ud.df.range) > nDVH
            ud.df.range = max(1, nDVH-nRows+1):nDVH;
        end

        set(hFig, 'userdata', ud);
        showDVHGui('REFRESH');

    case 'DELSTALE'
        %Find stale DVHs.
        [isStale, planC] = findStaleDVHs(planC);
        if length(planC{indexS.DVH}) == 0
            return
        end
        %Find computed DVHs
        for i=1:length(planC{indexS.DVH})
            if ~isempty(planC{indexS.DVH}(i).DVHMatrix)
                comp(i) = 1;
            else
                comp(i) = 0;
            end
        end

        isStale = find(isStale & comp);
        ud = get(hFig, 'userdata');
        if length(planC{indexS.DVH}) > 0
            planC{indexS.DVH}(isStale) = [];
            ud.state.vol(isStale) = [];
            ud.state.surf(isStale) = [];
            ud.state.avg (isStale) = [];
            ud.state.abs(isStale) = [];
        end

        nRows = ud.df.nRows;
        nDVH  = length(planC{indexS.DVH});
        if nDVH < nRows
            ud.df.range = 1:nDVH;
        elseif max(ud.df.range) > nDVH
            ud.df.range = max(1, nDVH-nRows+1):nDVH;
        end

        set(hFig, 'userdata', ud);
        showDVHGui('REFRESH');

    case 'VOLMASTER'
        onOrOff = get(gcbo, 'value');
        ud = get(hFig, 'userdata');
        if ~(any(ud.state.surf) || any(ud.state.avg))
            ud.state.vol = ones(1,length(ud.state.vol))*onOrOff;
        else
            set(gcbo, 'value', 0);
            errordlg('Please De-select all Volume or Surf. DVHs', 'De-Select surf/avg', 'modal');
        end                
        set(hFig, 'userdata', ud);
        showDVHGui('REFRESH');

    case 'SURFMASTER'
        onOrOff = get(gcbo, 'value');
        ud = get(hFig, 'userdata');
        if ~(any(ud.state.vol) || any(ud.state.avg))
            ud.state.surf = ones(1,length(ud.state.surf))*onOrOff;
        else
            set(gcbo, 'value', 0);
            errordlg('Please De-select all Volume or Avg. DVHs', 'De-Select surf/avg', 'modal');
        end                
        set(hFig, 'userdata', ud);
        showDVHGui('REFRESH');

    case 'AVGMASTER'
        onOrOff = get(gcbo, 'value');
        ud = get(hFig, 'userdata');        
        if ~(any(ud.state.vol) || any(ud.state.avg))
            ud.state.avg = ones(1,length(ud.state.avg))* onOrOff;
        else
            set(gcbo, 'value', 0);
            errordlg('Please De-select all Volume or Surf. DVHs', 'De-Select surf/avg', 'modal');
        end                
        
        set(hFig, 'userdata', ud);
        showDVHGui('REFRESH');

    case 'ABSMASTER'
        onOrOff = get(gcbo, 'value');
        ud = get(hFig, 'userdata');
        ud.state.abs = ones(1,length(ud.state.abs))*onOrOff;
        set(hFig, 'userdata', ud);
        showDVHGui('REFRESH');

    case 'REFRESH'
        ud = get(hFig, 'userdata');

        %Total number of DVHs
        nDVH = length(planC{indexS.DVH});

        %Number of visible DVHs.
        nvDVH = length(ud.df.range);

        if nDVH > ud.df.nRows
            set(ud.df.handles.scroll, 'min', 0, 'max', nDVH-nvDVH, 'value', nDVH-nvDVH+1-min(ud.df.range), 'enable', 'on', 'sliderstep', [1/(nDVH-nvDVH), nvDVH/(nDVH-nvDVH)]);
        else
            set(ud.df.handles.scroll, 'enable', 'off');
        end

        %         %Excessively slow to be done every refresh...
        %         [isStale, planC] = findStaleDVHs(planC);

        for i = 1:min(ud.df.nRows, nvDVH)
            %Which DVH is in spot i?
            indDVH = ud.df.range(i);

            %Is DVH calculated?
            if ~isempty(planC{indexS.DVH}(indDVH).DVHMatrix)
                comp = 'Y';
            else
                comp = 'N';
            end

            try
                strName = planC{indexS.DVH}(indDVH).structureName;
            catch
                strName = 'Unknown';
            end

            if isempty(planC{indexS.DVH}(indDVH).doseIndex)
                dshActive = 'off';
            else
                dshActive = 'on';
            end
            % DK
            %Inform user if DVH appears stale.
            % if (~isfield(planC{indexS.DVH}(indDVH), 'doseSignature') | isempty(planC{indexS.DVH}(indDVH).doseSignature)) & ~isempty(planC{indexS.DVH}(indDVH).DVHMatrix)
            % if isStale(indDVH) & ~isempty(planC{indexS.DVH}(indDVH).DVHMatrix)
            %    doseIndexText = 'Stale';
            %    doseIndexTextColor = [1 0 0];
            %    doseIndexTooltip = 'Source dose was modified/deleted, or DVH calculated outside of CERR.';
            % else
            %     doseIndexText = planC{indexS.DVH}(indDVH).doseIndex;
            %     doseIndexTextColor = [0 0 0];
            %     doseIndexTooltip = '';
            % end
            doseInd = num2str(getAssociatedDose(planC{indexS.DVH}(indDVH).assocDoseUID));
            strInd  = num2str(getAssociatedStr(planC{indexS.DVH}(indDVH).assocStrUID));
            
            if isfield(planC{indexS.DVH},'fractionGroupID')
                fractGroupID = planC{indexS.DVH}(indDVH).fractionGroupID;
            else
                fractGroupID = planC{indexS.DVH}(indDVH).fractionIDOfOrigin;
            end

            doseIndexTextColor = [0 0 0];
            doseIndexTooltip = '';
            doseFontWeight = 'normal';
            
            if isempty(doseInd)
                doseIndexTooltip = 'Source dose was modified/deleted, or DVH calculated outside of CERR.';
                doseInd = 'N-A';
                doseIndexTextColor = [1 0 0]; 
                doseFontWeight = 'Bold';
            end

            strIndexTextColor = [0 0 0];
            strIndexTooltip = '';
            strFontWeight = 'normal';
            
            if isempty(strInd)
                strInd = 'N-A';
                strIndexTooltip = 'Source structure was modified/deleted, or DVH calculated outside of CERR.';
                strIndexTextColor = [1 0 0];
                strFontWeight = 'Bold';
            end
            
            %Get color for this structure.
            structNum = getStructNum(strName,planC,indexS);
            if structNum ~= 0
                colorNum = structNum;
                BGColor = planC{indexS.structures}(colorNum).structureColor;
            else
                colorNum = indDVH;
                BGColor = getColor(colorNum, stateS.optS.colorOrder, 'loop');
            end            
            FGColor = setCERRLabelColor(colorNum);

            barColor = get(ud.df.handles.bgTxt(i), 'backgroundcolor');

            %Refresh fields.
            set(ud.df.handles.bgTxt(i), 'visible', 'on', 'backgroundColor', barColor)
            set(ud.df.handles.ind(i) , 'visible', 'on', 'backgroundColor', barColor, 'string', [num2str(indDVH) '.'])
            set(ud.df.handles.name(i), 'visible', 'on', 'string', strName, 'backgroundColor', BGColor, 'foregroundColor', FGColor);
            set(ud.df.handles.vol(i) , 'visible', 'on', 'value', ud.state.vol(indDVH), 'backgroundColor', barColor);
            set(ud.df.handles.surf(i), 'visible', 'on', 'value', ud.state.surf(indDVH), 'backgroundColor', barColor, 'enable', dshActive);
            set(ud.df.handles.avg(i),  'visible', 'on', 'value', ud.state.avg(indDVH), 'backgroundColor', barColor);
            set(ud.df.handles.abs(i) , 'visible', 'on', 'value', ud.state.abs(indDVH), 'backgroundColor', barColor)
            set(ud.df.handles.comp(i), 'visible', 'on', 'string', comp, 'backgroundColor', barColor)
            set(ud.df.handles.pID(i) , 'visible', 'on', 'string',  planC{indexS.DVH}(indDVH).planIDOfOrigin, 'backgroundColor', barColor);
            set(ud.df.handles.fID(i) , 'visible', 'on', 'string',  fractGroupID, 'backgroundColor', barColor);
            set(ud.df.handles.dInd(i), 'visible', 'on', 'string',  doseInd, 'backgroundColor', barColor, 'foregroundcolor', doseIndexTextColor,'tooltipstring', doseIndexTooltip,'FontWeight',doseFontWeight);            
            set(ud.df.handles.SInd(i), 'visible', 'on', 'string',  strInd, 'backgroundColor', barColor, 'foregroundcolor', strIndexTextColor,'tooltipstring', strIndexTooltip,'FontWeight',strFontWeight);            
            set(ud.df.handles.date(i), 'visible', 'on', 'string',  planC{indexS.DVH}(indDVH).dateOfDVH, 'backgroundColor', barColor);
            set(ud.df.handles.del(i) , 'visible', 'on', 'backgroundColor', barColor);
        end
        for i = min(ud.df.nRows, nvDVH)+1:ud.df.nRows
            set(ud.df.handles.bgTxt(i), 'visible', 'off')
            set(ud.df.handles.ind(i) , 'visible', 'off');
            set(ud.df.handles.name(i), 'visible', 'off');
            set(ud.df.handles.vol(i) , 'visible', 'off');
            set(ud.df.handles.surf(i), 'visible', 'off');
            set(ud.df.handles.avg(i) , 'visible', 'off');
            set(ud.df.handles.abs(i) , 'visible', 'off') ;
            set(ud.df.handles.comp(i), 'visible', 'off');
            set(ud.df.handles.pID(i) , 'visible', 'off');
            set(ud.df.handles.fID(i) , 'visible', 'off');
            set(ud.df.handles.dInd(i), 'visible', 'off');
            set(ud.df.handles.SInd(i), 'visible', 'off');
            set(ud.df.handles.date(i), 'visible', 'off');
            set(ud.df.handles.del(i) , 'visible', 'off');
        end
        drawnow

    case 'ADDDVH'
        %Add a new DVH to planC{indexS.DVH}, refresh.
        ud = get(hFig, 'userdata');
        %strNum = get(gcbo,'value') - 1;
        strNum = get(findobj('Tag','structSelectTag'),'value') - 1;
        if strNum == 0
            return;
        end
        doseIndex = get(findobj('Tag','doseSelectTag'),'value');
        strName = planC{indexS.structures}(strNum).structureName;

        nDVH = length(planC{indexS.DVH});
        planC{indexS.DVH}(nDVH+1).structureName = strName;
        planC{indexS.DVH}(nDVH+1).assocStrUID=planC{indexS.structures}(strNum).strUID;
        planC{indexS.DVH}(nDVH+1).dvhUID = createUID('dvh');
        planC{indexS.DVH}(nDVH+1).doseIndex = doseIndex;
        planC{indexS.DVH}(nDVH+1).assocDoseUID = planC{indexS.dose}(doseIndex).doseUID;
        planC{indexS.DVH}(nDVH+1).dateOfDVH = date;
        planC{indexS.DVH}(nDVH+1).fractionIDOfOrigin = planC{indexS.dose}(doseIndex).fractionGroupID;
        ud.state.vol(nDVH+1) = get(ud.df.handles.volMaster, 'value');
        ud.state.surf(nDVH+1) = get(ud.df.handles.surfMaster, 'value');
        ud.state.avg (nDVH+1) = get(ud.df.handles.avgMaster, 'value');
        ud.state.abs(nDVH+1) = get(ud.df.handles.absMaster, 'value');
        %set(gcbo, 'value', 1);

        nRows = ud.df.nRows;
        nDVH = length(planC{indexS.DVH});
        ud.df.range = max(1, nDVH-nRows+1):nDVH;

        set(hFig, 'userdata', ud);
        showDVHGui('REFRESH');

    case 'DELDVH'
        %Delete a DVH from planC{indexS.DVH}, refresh.
        ud = get(hFig, 'userdata');
        ind = get(gcbo, 'userdata');
        indDVH = ud.df.range(ind);
        planC{indexS.DVH}(indDVH) = [];
        ud.state.vol(indDVH) = [];
        ud.state.surf(indDVH) = [];
        ud.state.avg(indDVH)  = [];
        ud.state.abs(indDVH) = [];

        nRows = ud.df.nRows;
        nDVH  = length(planC{indexS.DVH});
        if nDVH < nRows
            ud.df.range = 1:nDVH;
        elseif max(ud.df.range) > nDVH
            ud.df.range = max(1, nDVH-nRows+1):nDVH;
        end

        set(hFig, 'userdata', ud);
        showDVHGui('REFRESH');

    case 'SLIDER'
        %Slider was clicked, move ud.df.range.
        ud = get(hFig, 'userdata');
        val = round(get(gcbo, 'value'));

        nRows = ud.df.nRows;
        nDVH  = length(planC{indexS.DVH});

        lastDVH = nDVH - val;
        ud.df.range = max(1, lastDVH-nRows+1):lastDVH;
        set(hFig, 'userdata', ud);
        showDVHGui('REFRESH');

    case 'ABS'
        %Absolute dose has been checked.  Set internal struct, refresh.
        ud = get(hFig, 'userdata');
        ind = get(gcbo, 'userdata');
        indDVH = ud.df.range(ind);
        val = get(gcbo, 'value');
        ud.state.abs(indDVH) = val;
        set(hFig, 'userdata', ud);
        showDVHGui('REFRESH');

    case 'AVG'
        %Surf has been checked.  Set internal struct, refresh.
        ud = get(hFig, 'userdata');
        ind = get(gcbo, 'userdata');
        indDVH = ud.df.range(ind);
        val = get(gcbo, 'value');
        if ~(any(ud.state.vol) || any(ud.state.surf))            
            ud.state.avg(indDVH) = val;
        else
            set(gcbo, 'value', 0);
            errordlg('Please De-select all Surface or Volume DVHs', 'De-Select surf/vol', 'modal');
        end
        set(hFig, 'userdata', ud);
        showDVHGui('REFRESH');

    case 'SURF'
        %Surf has been checked.  Set internal struct, refresh.
        ud = get(hFig, 'userdata');
        ind = get(gcbo, 'userdata');
        indDVH = ud.df.range(ind);
        val = get(gcbo, 'value');
        if ~(any(ud.state.vol) || any(ud.state.avg))            
            ud.state.surf(indDVH) = val;
        else
            set(gcbo, 'value', 0);
            errordlg('Please De-select all Volume or Avg. DVHs', 'De-Select vol/avg', 'modal');
        end
        set(hFig, 'userdata', ud);
        showDVHGui('REFRESH');

    case 'VOL'
        %Vol has been checked.  Set internal struct, refresh.
        ud = get(hFig, 'userdata');
        ind = get(gcbo, 'userdata');
        indDVH = ud.df.range(ind);
        val = get(gcbo, 'value');
        if ~(any(ud.state.surf) || any(ud.state.avg))
            ud.state.vol(indDVH) = val;
        else
            set(gcbo, 'value', 0);
            errordlg('Please De-select all Surface or Avg. DVHs', 'De-Select surf/avg', 'modal');
        end
        set(hFig, 'userdata', ud);
        showDVHGui('REFRESH');

    case 'NEWFIGCLICKED'
        ud = get(hFig, 'userdata');
        val = get(gcbo, 'value');
        ud.af.newPlot = val;
        set(hFig, 'userdata', ud);
        
    case 'STDDVHVLICKED'
        ud = get(hFig, 'userdata');
        val = get(gcbo, 'value');
        ud.af.stdavgDVH = val;
        set(hFig, 'userdata', ud);
        
    case 'GRIDCLICKED'
        ud = get(hFig, 'userdata');
        val = get(gcbo, 'value');
        ud.af.grid = val;
        set(hFig, 'userdata', ud);

    case 'PLOT'
        %Plot DVH/DSHs.
        ud = get(hFig, 'userdata');
        cum_diff_string = varargin{1};
        plotDVH(ud.state.surf, ud.state.vol, ud.state.avg, ud.state.abs, ud.af.newPlot, ud.af.grid, ud.af.stdavgDVH, cum_diff_string);
        showDVHGui('REFRESH');
end
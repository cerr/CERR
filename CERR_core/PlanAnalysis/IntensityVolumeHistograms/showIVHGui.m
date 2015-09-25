function showIVHGui(command, varargin)
%"showIVHGui"
%   Create a GUI to display, plot and manipulate IVHs.
% DK 07/25/2006
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
%   With a planC loaded: showIVHGui()


global stateS planC
indexS = planC{end};

if ~exist('command')
    command = 'INIT';
end

%Find old IVHGui figure.
hFig = findobj('Tag', 'IVHGui');

%If old figure exists, refresh it.
if isempty(hFig) & ~strcmpi(command, 'INIT')
    error('IVHGui no longer exists. Callback failed.');
    return;
elseif ~isempty(hFig) & strcmpi(command, 'INIT')
    figure(hFig);
    showIVHGui('REFRESH')
    return;
end

switch upper(command)
    case 'INIT'
        if stateS.imageRegistration
            warning('please exit Fusion before using IVH');
            return
        end
        units = 'pixels';
        screenSize = get(0,'ScreenSize');
        w = 800; h = 600;

        %Initial size of figure in pixels. Figure scales fairly well.
        hFig = figure('name', 'Intensity Volume Histogram Menu', 'units', units, 'position',[(screenSize(3)-w)/2 (screenSize(4)-h)/2 w h],...
            'MenuBar', 'none', 'NumberTitle', 'off', 'resize', 'on', 'Tag', 'IVHGui', 'DoubleBuffer', 'on');
        stateS.handle.IVHMenuFigure = hFig;
        ud.figure.w = w; ud.figure.h = h;

        %Set up add frame
        afX = 10; afW = w - 2*afX; afH = 50; afY = h - 10 - afH;
        ud.af.X = afX; ud.af.W = afW; ud.af.H = afH; ud.af.Y = afY;
        uicontrol(hFig, 'style', 'frame', 'units', units, 'position', [afX afY-15 afW afH+15], 'enable', 'inactive');
        uicontrol(hFig, 'style', 'text', 'units', units, 'position', [w/2-50 afY+afH-5 100 15], 'string', 'Control Panel',...
            'FontWeight', 'bold','fontsize',9.2);

        %Set up IVH list frame
        dfX = 10; dfW = w - 2*dfX; dfY = 10; dfH = afY - 10 - dfY;
        ud.df.X = dfX; ud.df.W = dfW; ud.df.Y = dfY; ud.df.H = dfH;
        hDf = uicontrol(hFig, 'style', 'frame', 'units', units, 'position', [dfX dfY dfW dfH-30], 'enable', 'inactive');
        uicontrol(hFig, 'style', 'text', 'units', units, 'position', [w/2-50 dfY+dfH-35 100 15], 'string', 'Intensity Volume',...
            'FontWeight', 'bold','fontsize',9.2);
        frameColor = get(hDf, 'backgroundcolor');

        %Setup Scan list item and tag.
        for i = 1:length(planC{indexS.scan})
            patientName = planC{indexS.scan}(i).scanInfo(1).imageType;
            patientName = [num2str(i) '.' patientName];
            ScanList{i} = patientName;
        end

        uicontrol(hFig, 'style', 'text', 'units', units, 'position',[afX+15 afY+18 100 22], 'string', 'Select Scan Set','FontWeight','Bold');
        ud.af.handles.scan = uicontrol(hFig, 'style', 'popupmenu', 'units', units, 'position',  [afX+10 afY 150 22] ,...
            'string', ScanList, 'value', stateS.scanSet,'horizontalAlignment', 'left', ...
            'callback', 'showIVHGui(''SCANPICKED'')','Tag','scanSelectTag');

        %Setup structure list item and tag.
        prefix = 'Select a structure.';
        strList = {prefix, planC{indexS.structures}.structureName};
        uicontrol(hFig, 'style', 'text', 'units', units, 'position',[afX+85+155 afY+18 100 22], 'string', 'Select Structure','FontWeight','Bold');
        uicontrol(hFig, 'style', 'popupmenu', 'units', units, 'position',[afX+85+150 afY 150 22], 'string', strList,...
            'horizontalAlignment', 'left', 'callback', 'showIVHGui(''ADDIVH'')');

        %Add grid checkbox and tag.
        ud.af.grid = 1;
        uicontrol(hFig, 'style', 'text', 'units', units, 'position', [afX+470 afY+15 70 22], 'string', 'Gridlines','FontWeight','Bold');
        uicontrol(hFig, 'style', 'checkbox', 'units', units, 'position', [afX+460 afY+20 20 22], 'value', ud.af.grid,...
            'horizontalAlignment', 'left', 'callback', 'showIVHGui(''GRIDCLICKED'')');

        %Add newFigure checkbox and tag.
        ud.af.newPlot = 0;
        uicontrol(hFig, 'style', 'text', 'units', units, 'position', [afX+470 afY-10 80 22], 'string', 'New figure','FontWeight','Bold');
        uicontrol(hFig, 'style', 'checkbox', 'units', units, 'position', [afX+460 afY-5 20 22], 'value', ud.af.newPlot, ...
            'horizontalAlignment', 'left', 'callback', 'showIVHGui(''NEWFIGCLICKED'')');
        %Add plot button and tag.
        %uicontrol(hFig, 'style', 'pushbutton', 'units', units, 'position',[afX+640 afY+10 100 25], 'string', 'Plot',...
        %    'horizontalAlignment', 'left', 'callback', 'showIVHGui(''PLOT'')');

        uicontrol(hFig, 'style', 'pushbutton', 'units', units, 'position', [afX+640 afY + 25 100 20], 'string', 'Plot Cumulative', 'horizontalAlignment', 'left', 'callback', 'showIVHGui(''PLOT'',''CUMU'')');
        uicontrol(hFig, 'style', 'pushbutton', 'units', units, 'position', [afX+640 afY + 2 100 20], 'string', 'Plot Differential', 'horizontalAlignment', 'left', 'callback', 'showIVHGui(''PLOT'',''DIFF'')');


        %Set parameters for each row of IVHs
        ud.df.rowH = 20;
        ud.df.rowW = w - 20;

        %Calculate maxNum of rows that can be displayed.
        ud.df.nRows = floor((ud.df.H -40)/ ud.df.rowH) - 3;


        %Create row headers.
        uicontrol(hFig, 'style', 'text', 'units', units, 'position', [dfX+20  dfY+dfH-45-ud.df.rowH 100 15],...
            'string', 'Intensity Volume', 'horizontalAlignment', 'center');
        uicontrol(hFig, 'style', 'text', 'units', units, 'position', [dfX+140 dfY+dfH-45-ud.df.rowH 30 15],...
            'string', 'Vol', 'horizontalAlignment', 'center');
        uicontrol(hFig, 'style', 'text', 'units', units, 'position', [dfX+170 dfY+dfH-45-ud.df.rowH 30 15],...
            'string', 'Surf', 'horizontalAlignment', 'center');
        uicontrol(hFig, 'style', 'text', 'units', units, 'position', [dfX+200 dfY+dfH-45-ud.df.rowH 30 15],...
            'string', 'Avg', 'horizontalAlignment', 'center');
        uicontrol(hFig, 'style', 'text', 'units', units, 'position', [dfX+230 dfY+dfH-45-ud.df.rowH 30 15],...
            'string', 'Abs', 'horizontalAlignment', 'center');
        uicontrol(hFig, 'style', 'text', 'units', units, 'position', [dfX+270 dfY+dfH-45-ud.df.rowH 100 15],...
            'string', 'Computed', 'horizontalAlignment', 'center');
        uicontrol(hFig, 'style', 'text', 'units', units, 'position', [dfX+dfW-58 dfY+dfH-45-ud.df.rowH 30 15],...
            'string', 'Delete', 'horizontalAlignment', 'center');

        fieldW = [100 80 80 95];

        uicontrol(hFig, 'style', 'text', 'units', units, 'position', [dfX+340+10 dfY+dfH-45-ud.df.rowH fieldW(1) 15],...
            'string', 'Scan Type', 'horizontalAlignment', 'center');
        uicontrol(hFig, 'style', 'text', 'units', units, 'position', [dfX+340+(sum(fieldW(1))) dfY+dfH-45-ud.df.rowH fieldW(2) 15],...
            'string', 'Scan Index', 'horizontalAlignment', 'center');
        uicontrol(hFig, 'style', 'text', 'units', units, 'position', [dfX+340+(sum(fieldW(1:2))) dfY+dfH-45-ud.df.rowH fieldW(3) 15],...
            'string', 'Structure Index', 'horizontalAlignment', 'center');
        uicontrol(hFig, 'style', 'text', 'units', units, 'position', [dfX+340+(sum(fieldW(1:3))) dfY+dfH-45-ud.df.rowH fieldW(4) 15],...
            'string', 'dateOf IVH', 'horizontalAlignment', 'center');

        ud.df.handles.volMaster   = uicontrol(hFig, 'style', 'checkbox', 'units', units, 'position', [dfX+150 dfY+dfH-45-ud.df.rowH - ud.df.rowH 20 15],...
            'horizontalAlignment', 'center', 'visible', 'on', 'userdata', 1, 'callback', 'showIVHGui(''VOLMASTER'')');
        ud.df.handles.surfMaster  = uicontrol(hFig, 'style', 'checkbox', 'units', units, 'position', [dfX+180 dfY+dfH-45-ud.df.rowH - ud.df.rowH 20 15],...
            'horizontalAlignment', 'center', 'visible', 'on', 'userdata', 1, 'callback', 'showIVHGui(''SURFMASTER'')');
        ud.df.handles.avgMaster   = uicontrol(hFig, 'style', 'checkbox', 'units', units, 'position', [dfX+210 dfY+dfH-45-ud.df.rowH - ud.df.rowH 20 15],...
            'horizontalAlignment', 'center', 'visible', 'on', 'userdata', 1, 'callback', 'showIVHGui(''AVGMASTER'')');
        ud.df.handles.absMaster   = uicontrol(hFig, 'style', 'radiobutton', 'units', units, 'position', [dfX+240 dfY+dfH-45-ud.df.rowH - ud.df.rowH 20 15],...
            'horizontalAlignment', 'center', 'visible', 'on', 'userdata', 1, 'callback', 'showIVHGui(''ABSMASTER'')');
        ud.df.handles.delMaster   = uicontrol(hFig, 'style', 'pushbutton', 'units', units, 'position', [dfX+dfW-58-25/2 dfY+dfH-45-ud.df.rowH-1-ud.df.rowH 25*2 19],...
            'string', 'DelAll', 'horizontalAlignment', 'center', 'visible', 'on', 'userdata', 1, 'callback', 'showIVHGui(''DELMASTER'')');

        %Create rows and make them invisible.
        for i = 1:ud.df.nRows
            if i/2 == floor(i/2)
                bgColor = frameColor;
            else
                bgColor = [.9 .9 .9];
            end
            ud.df.handles.bgTxt(i) = uicontrol(hFig, 'style', 'text', 'units', units, 'position', [20 dfY+dfH-50-ud.df.rowH - ud.df.rowH*(i+1)-2 ud.df.rowW-20 ud.df.rowH],...
                'string', '', 'horizontalAlignment', 'center', 'visible', 'off', 'userdata', i, 'backgroundcolor', bgColor);

            ud.df.handles.ind(i)   = uicontrol(hFig, 'style', 'text', 'units', units, 'position', [dfX+5 dfY+dfH-50-ud.df.rowH - ud.df.rowH*(i+1) 20 15], ...
                'string', [num2str(i) '.'], 'horizontalAlignment', 'center', 'visible', 'off', 'userdata', i);
            ud.df.handles.name(i)  = uicontrol(hFig, 'style', 'text', 'units', units, 'position', [dfX+35 dfY+dfH-50-ud.df.rowH - ud.df.rowH*(i+1) 100 15],...
                'string', 'Brain', 'horizontalAlignment', 'Left', 'visible', 'off', 'userdata', i);
            ud.df.handles.vol(i)   = uicontrol(hFig, 'style', 'checkbox', 'units', units, 'position', [dfX+150 dfY+dfH-50-ud.df.rowH - ud.df.rowH*(i+1) 20 15],...
                'horizontalAlignment', 'center', 'visible', 'off', 'userdata', i, 'callback', 'showIVHGui(''VOL'')');
            ud.df.handles.surf(i)  = uicontrol(hFig, 'style', 'checkbox', 'units', units, 'position', [dfX+180 dfY+dfH-50-ud.df.rowH - ud.df.rowH*(i+1) 20 15],...
                'horizontalAlignment', 'center', 'visible', 'off', 'userdata', i, 'callback', 'showIVHGui(''SURF'')');
            ud.df.handles.avg(i)   = uicontrol(hFig, 'style', 'checkbox', 'units', units, 'position', [dfX+210 dfY+dfH-50-ud.df.rowH - ud.df.rowH*(i+1) 20 15],...
                'horizontalAlignment', 'center', 'visible', 'off', 'userdata', i, 'callback', 'showIVHGui(''AVG'')');

            ud.df.handles.abs(i)   = uicontrol(hFig, 'style', 'radiobutton', 'units', units, 'position', [dfX+240 dfY+dfH-50-ud.df.rowH - ud.df.rowH*(i+1) 20 15],...
                'horizontalAlignment', 'center', 'visible', 'off', 'userdata', i, 'callback', 'showIVHGui(''ABS'')');
            ud.df.handles.comp(i)  = uicontrol(hFig, 'style', 'text', 'units', units, 'position', [dfX+300 dfY+dfH-50-ud.df.rowH - ud.df.rowH*(i+1) 30 15],...
                'string', 'Yes', 'horizontalAlignment', 'center', 'visible', 'off', 'userdata', i);
            ud.df.handles.del(i)   = uicontrol(hFig, 'style', 'pushbutton', 'units', units, 'position', [dfX+dfW-58 dfY+dfH-50-ud.df.rowH-1 - ud.df.rowH*(i+1) 25 19],...
                'string', '-', 'horizontalAlignment', 'center', 'visible', 'off', 'userdata', i, 'callback', 'showIVHGui(''DELIVH'')');

            ud.df.handles.Styp(i)  = uicontrol(hFig, 'style', 'text', 'units', units, 'position', [dfX+250+(fieldW(1)+10) dfY+dfH-50-ud.df.rowH - ud.df.rowH*(i+1) fieldW(2) 15],...
                'string', 'fd', 'horizontalAlignment', 'center', 'visible', 'off', 'userdata', i);
            ud.df.handles.scanInd(i)  = uicontrol(hFig, 'style', 'text', 'units', units, 'position', [dfX+260+(sum(fieldW(1:2))) dfY+dfH-50-ud.df.rowH - ud.df.rowH*(i+1) fieldW(3) 15],...
                'string', '1', 'horizontalAlignment', 'center', 'visible', 'off', 'userdata', i);
            ud.df.handles.strInd(i)  = uicontrol(hFig, 'style', 'text', 'units', units, 'position', [dfX+260+(sum(fieldW(1:3))) dfY+dfH-50-ud.df.rowH - ud.df.rowH*(i+1) fieldW(3) 15],...
                'string', '1', 'horizontalAlignment', 'center', 'visible', 'off', 'userdata', i);
            ud.df.handles.date(i)  = uicontrol(hFig, 'style', 'text', 'units', units, 'position', [dfX+250+(sum(fieldW(1:4))) dfY+dfH-50-ud.df.rowH - ud.df.rowH*(i+1) fieldW(4) 15],...
                'string', date, 'horizontalAlignment', 'center', 'visible', 'off', 'userdata', i);
        end

        nIVH = length(planC{indexS.IVH});
        ud.state.vol  = zeros(1,nIVH);
        ud.state.surf = zeros(1,nIVH);
        ud.state.avg  = zeros(1,nIVH);
        ud.state.abs  = zeros(1,nIVH);


        %Create scrollbar on right side. Inactive to start.
        ud.df.handles.scroll = uicontrol(hFig, 'style', 'slider', 'units', units, 'position', [dfX-1+dfW-15 dfY 20 dfH-30], 'enable', 'off', 'callback', 'showIVHGui(''SLIDER'')');

        %Set range of currently displayed IVHs.
        ud.df.range = 1:min(i, nIVH);
        set(hFig, 'userdata', ud);
        drawnow;

        set(get(hFig, 'children'), 'units', 'normalized');
        %Check for stale IVHs... later examine scanSig field.
        %         [isStale, planC] = findStaleIVHs(planC);
        showIVHGui('REFRESH');

    case 'SCANPICKED'
        % Does nothing

    case 'ADDIVH'

        %Add a new IVH to planC{indexS.IVH}, refresh.
        ud = get(hFig, 'userdata');
        strNum = get(gcbo,'value') - 1;
        if strNum == 0
            return;
        end
        scanIndex = get(findobj('Tag','scanSelectTag'),'value');
        strName = planC{indexS.structures}(strNum).structureName;

        %Update IVH fields in planC
        nIVH = length(planC{indexS.IVH});
        planC{indexS.IVH}(nIVH+1).structureName = strName;
        planC{indexS.IVH}(nIVH+1).assocStrUID=planC{indexS.structures}(strNum).strUID;
        planC{indexS.IVH}(nIVH+1).IVHUID = createUID('IVH');
        planC{indexS.IVH}(nIVH+1).scanIndex = scanIndex;
        planC{indexS.IVH}(nIVH+1).assocScanUID = planC{indexS.scan}(scanIndex).scanUID;
        planC{indexS.IVH}(nIVH+1).dateOfIVH = date;
        planC{indexS.IVH}(nIVH+1).scanType = planC{indexS.scan}(scanIndex).scanInfo(1).imageType;

        % Update the User data
        ud.state.vol(nIVH+1) = get(ud.df.handles.volMaster, 'value');
        ud.state.surf(nIVH+1) = get(ud.df.handles.surfMaster, 'value');
        ud.state.avg (nIVH+1) = get(ud.df.handles.avgMaster, 'value');
        ud.state.abs(nIVH+1) = get(ud.df.handles.absMaster, 'value');

        set(gcbo, 'value', 1);

        nRows = ud.df.nRows;
        nIVH = length(planC{indexS.IVH});
        ud.df.range = max(1, nIVH-nRows+1):nIVH;

        set(hFig, 'userdata', ud);

        showIVHGui('REFRESH');

    case 'GRIDCLICKED'
        ud = get(hFig, 'userdata');
        val = get(gcbo, 'value');
        ud.af.grid = val;
        set(hFig, 'userdata', ud);

    case 'NEWFIGCLICKED'
        ud = get(hFig, 'userdata');
        val = get(gcbo, 'value');
        ud.af.newPlot = val;
        set(hFig, 'userdata', ud);

    case 'PLOT'
        ud = get(hFig, 'userdata');
        cum_diff_string = varargin{1};
        plotIVH(ud.state.surf, ud.state.vol, ud.state.avg, ud.state.abs, ud.af.newPlot, ud.af.grid, cum_diff_string);
        showIVHGui('REFRESH');

    case 'VOLMASTER'
        onOrOff = get(gcbo, 'value');
        ud = get(hFig, 'userdata');
        ud.state.vol = ones(1,length(ud.state.vol))*onOrOff;
        set(hFig, 'userdata', ud);
        showIVHGui('REFRESH');


    case 'SURFMASTER'
        onOrOff = get(gcbo, 'value');
        ud = get(hFig, 'userdata');
        ud.state.surf = ones(1,length(ud.state.surf))*onOrOff;
        set(hFig, 'userdata', ud);
        showIVHGui('REFRESH');

    case 'AVGMASTER'
        onOrOff = get(gcbo, 'value');
        ud = get(hFig, 'userdata');
        ud.state.avg = ones(1,length(ud.state.avg))* onOrOff;
        set(hFig, 'userdata', ud);
        showIVHGui('REFRESH');

    case 'ABSMASTER'
        onOrOff = get(gcbo, 'value');
        ud = get(hFig, 'userdata');
        ud.state.abs = ones(1,length(ud.state.abs))*onOrOff;
        set(hFig, 'userdata', ud);
        showIVHGui('REFRESH');

    case 'DELMASTER'
        % Check before deleting all IVH
        ansQdlg = questdlg('Do you want to permanently delete all IVH','IVH Master Delete','Yes','No','No');
        if ismember(ansQdlg,{'No',''})
            return;
        end

        ud = get(hFig, 'userdata');
        if ~isempty(planC{indexS.IVH})
            planC{indexS.IVH}(1:end) = [];
            ud.state.vol (1:end) = [];
            ud.state.surf(1:end) = [];
            ud.state.avg (1:end) = [];
            ud.state.abs (1:end) = [];
        end

        nRows = ud.df.nRows;
        nIVH  = length(planC{indexS.IVH});
        if nIVH < nRows
            ud.df.range = 1:nIVH;
        elseif max(ud.df.range) > nIVH
            ud.df.range = max(1, nIVH-nRows+1):nIVH;
        end

        set(hFig, 'userdata', ud);
        showIVHGui('REFRESH');

    case  'VOL'
        %Vol has been checked.  Set internal struct, refresh.
        ud = get(hFig, 'userdata');
        ind = get(gcbo, 'userdata');
        indIVH = ud.df.range(ind);
        val = get(gcbo, 'value');
        ud.state.vol(indIVH) = val;
        set(hFig, 'userdata', ud);
        showIVHGui('REFRESH');

    case 'SURF'
        %Surf has been checked.  Set internal struct, refresh.
        ud = get(hFig, 'userdata');
        ind = get(gcbo, 'userdata');
        indIVH = ud.df.range(ind);
        val = get(gcbo, 'value');
        ud.state.surf(indIVH) = val;
        set(hFig, 'userdata', ud);
        showIVHGui('REFRESH');

    case 'AVG'
        %Surf has been checked.  Set internal struct, refresh.
        ud = get(hFig, 'userdata');
        ind = get(gcbo, 'userdata');
        indIVH = ud.df.range(ind);
        val = get(gcbo, 'value');
        ud.state.avg(indIVH) = val;
        set(hFig, 'userdata', ud);
        showIVHGui('REFRESH');

    case 'ABS'
        %Absolute dose has been checked.  Set internal struct, refresh.
        ud = get(hFig, 'userdata');
        ind = get(gcbo, 'userdata');
        indIVH = ud.df.range(ind);
        val = get(gcbo, 'value');
        ud.state.abs(indIVH) = val;
        set(hFig, 'userdata', ud);
        showIVHGui('REFRESH');

    case 'DELIVH'
        %Delete a IVH from planC{indexS.IVH}, refresh.
        ud = get(hFig, 'userdata');
        ind = get(gcbo, 'userdata');
        indIVH = ud.df.range(ind);
        planC{indexS.IVH}(indIVH) = [];
        ud.state.vol(indIVH) = [];
        ud.state.surf(indIVH) = [];
        ud.state.avg(indIVH)  = [];
        ud.state.abs(indIVH) = [];

        nRows = ud.df.nRows;
        nIVH  = length(planC{indexS.IVH});
        if nIVH < nRows
            ud.df.range = 1:nIVH;
        elseif max(ud.df.range) > nIVH
            ud.df.range = max(1, nIVH-nRows+1):nIVH;
        end

        set(hFig, 'userdata', ud);
        showIVHGui('REFRESH');

    case 'SLIDER'
        %Slider was clicked, move ud.df.range.
        ud = get(hFig, 'userdata');
        val = round(get(gcbo, 'value'));

        nRows = ud.df.nRows;
        nDVH  = length(planC{indexS.DVH});

        lastDVH = nDVH - val;
        ud.df.range = max(1, lastDVH-nRows+1):lastDVH;
        set(hFig, 'userdata', ud);
        showIVHGui('REFRESH');

    case 'REFRESH'
        ud = get(hFig, 'userdata');

        %Total number of IVHs
        nIVH = length(planC{indexS.IVH});

        %Number of visible IVHs.
        nvIVH = length(ud.df.range);

        if nIVH > ud.df.nRows
            set(ud.df.handles.scroll, 'min', 0, 'max', nIVH-nvIVH, 'value', nIVH-nvIVH+1-min(ud.df.range), 'enable', 'on',...
                'sliderstep', [1/(nIVH-nvIVH), nvIVH/(nIVH-nvIVH)]);
        else
            set(ud.df.handles.scroll, 'enable', 'off');
        end

        %         %Excessively slow to be done every refresh...
        %         [isStale, planC] = findStaleIVHs(planC);

        for i = 1:min(ud.df.nRows, nvIVH)
            %Which IVH is in spot i?
            indIVH = ud.df.range(i);

            %Is IVH calculated?
            if ~isempty(planC{indexS.IVH}(indIVH).IVHMatrix)
                comp = 'Yes';
            else
                comp = 'No';
            end

            try
                strName = planC{indexS.IVH}(indIVH).structureName;
            catch
                strName = 'Unknown';
            end

            if isempty(planC{indexS.IVH}(indIVH).scanIndex)
                dshActive = 'off';
            else
                dshActive = 'on';
            end

            scanInd = num2str(getAssociatedScan(planC{indexS.IVH}(indIVH).assocScanUID));
            strInd  = num2str(getAssociatedStr(planC{indexS.IVH}(indIVH).assocStrUID));
            scanType = planC{indexS.IVH}(indIVH).scanType;

            scanIndexTextColor = [0 0 0];
            scanIndexTooltip = '';
            scanFontWeight = 'normal';

            if isempty(scanInd)
                scanIndexTooltip = 'Source scan was modified/deleted, or IVH calculated outside of CERR.';
                scanInd = 'N-A';
                scanIndexTextColor = [1 0 0];
                scanFontWeight = 'Bold';
            end

            strIndexTextColor = [0 0 0];
            strIndexTooltip = '';
            strFontWeight = 'normal';

            if isempty(strInd)
                strInd = 'N-A';
                strIndexTooltip = 'Source structure was modified/deleted, or IVH calculated outside of CERR.';
                strIndexTextColor = [1 0 0];
                strFontWeight = 'Bold';
            end

            %Get color for this structure.
            structNum = getStructNum(strName,planC,indexS);
            if structNum ~= 0
                colorNum = structNum;
                BGColor = planC{indexS.structures}(colorNum).structureColor;
            else
                colorNum = indIVH;
                BGColor = getColor(colorNum, stateS.optS.colorOrder, 'loop');
            end            
            FGColor = setCERRLabelColor(colorNum);

            barColor = get(ud.df.handles.bgTxt(i), 'backgroundcolor');

            %Refresh fields.
            set(ud.df.handles.bgTxt(i), 'visible', 'on', 'backgroundColor', barColor)
            set(ud.df.handles.ind(i) , 'visible', 'on', 'backgroundColor', barColor, 'string', [num2str(indIVH) '.'])
            set(ud.df.handles.name(i), 'visible', 'on', 'string', strName, 'backgroundColor', BGColor, 'foregroundColor', FGColor);
            set(ud.df.handles.vol(i) , 'visible', 'on', 'value', ud.state.vol(indIVH), 'backgroundColor', barColor);
            set(ud.df.handles.surf(i), 'visible', 'on', 'value', ud.state.surf(indIVH), 'backgroundColor', barColor, 'enable', dshActive);
            set(ud.df.handles.avg(i),  'visible', 'on', 'value', ud.state.avg(indIVH), 'backgroundColor', barColor);
            set(ud.df.handles.abs(i) , 'visible', 'on', 'value', ud.state.abs(indIVH), 'backgroundColor', barColor)
            set(ud.df.handles.comp(i), 'visible', 'on', 'string', comp, 'backgroundColor', barColor)
            set(ud.df.handles.Styp(i), 'visible', 'on', 'string', scanType, 'backgroundColor', barColor);
            set(ud.df.handles.scanInd(i), 'visible', 'on', 'string',  scanInd, 'backgroundColor', barColor, 'foregroundcolor',...
                scanIndexTextColor,'tooltipstring', scanIndexTooltip,'FontWeight',scanFontWeight);
            set(ud.df.handles.strInd(i), 'visible', 'on', 'string',  strInd, 'backgroundColor', barColor, 'foregroundcolor',...
                strIndexTextColor,'tooltipstring', strIndexTooltip,'FontWeight',strFontWeight);
            set(ud.df.handles.date(i), 'visible', 'on', 'string',  planC{indexS.IVH}(indIVH).dateOfIVH, 'backgroundColor', barColor);
            set(ud.df.handles.del(i) , 'visible', 'on', 'backgroundColor', barColor);
        end
        for i = min(ud.df.nRows, nvIVH)+1:ud.df.nRows
            set(ud.df.handles.bgTxt(i), 'visible', 'off')
            set(ud.df.handles.ind(i) , 'visible', 'off');
            set(ud.df.handles.name(i), 'visible', 'off');
            set(ud.df.handles.vol(i) , 'visible', 'off');
            set(ud.df.handles.surf(i), 'visible', 'off');
            set(ud.df.handles.avg(i) , 'visible', 'off');
            set(ud.df.handles.abs(i) , 'visible', 'off') ;
            set(ud.df.handles.comp(i), 'visible', 'off');
            set(ud.df.handles.Styp(i), 'visible', 'off');
            set(ud.df.handles.scanInd(i), 'visible', 'off');
            set(ud.df.handles.strInd(i), 'visible', 'off');
            set(ud.df.handles.date(i), 'visible', 'off');
            set(ud.df.handles.del(i) , 'visible', 'off');
        end
        drawnow
end
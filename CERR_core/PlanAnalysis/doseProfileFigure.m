function doseProfileFigure(command, varargin)
%"doseProfileFigure"
%   Given a start point and end point (startPt, endPt) as [x,y,z]
%   coordinates, create a figure containing a plot doses along the line
%   connecting startPt to endPt.  This figure has controls to activate
%   plots of any or all existing CT scans or doses along the same line, but
%   defaults to the dose passed in initialDoseV and initialScanV.
%
%JRA 1/11/05
%
%Usage:
%   function doseProfileFigure('init', initialDoseV, initialScanV);
%   function doseProfileFigure('new_points', startPt, endPt);
%   function doseProfileFigure('refresh');
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

persistent drawing;

initialDoseV = [];
initialScanV = [];

if isnumeric(command) & length(command) == 3
    startPt = command;
    endPt = varargin{1};
    command = 'init';
elseif isstr(command) & strcmpi(command, 'init')
    startPt = [];
    endPt = [];
    if nargin > 2
        initialDoseV = varargin{1};
        initialScanV = varargin{2};
    end
elseif isstr(command)
else
    error('Invalid call to doseProfileFigure. Help doseProfileFigure for details.');
end


switch upper(command)
    case 'INIT'
        stateS.doseDiffScale = 'Abs';
        drawing = 0;
        oldFigs = findobj('tag', 'CERR_DoseLineProfile');
        delete(oldFigs);

        units = 'pixels';
        screenSize = get(0,'ScreenSize');
        % APA: Commented
        % w = 500; h = 500;
        % APA: Commented
        w = 510; h = 650;

        %Initial size of figure in pixels. Figure scales fairly well.
        hFig = figure('name', 'Dose Line Profile', 'units', units, 'position',[(screenSize(3)-w) 35 w h], 'MenuBar', 'none', 'NumberTitle', 'off', 'resize', 'off', 'Tag', 'CERR_DoseLineProfile', 'DoubleBuffer', 'on', 'DeleteFcn', 'doseProfileFigure(''CLOSE'')');
        stateS.handle.doseProfileFigure = hFig;

        nDoses = length(planC{indexS.dose});
        nScans = length(planC{indexS.scan});
        
        nScans = min(nScans,20); % 20 scans max allowed. Add pagination in future.

        %Calculate how many rows are required for checkboxes.
        nRows = max(ceil(nDoses/2), ceil(nScans/2));
        yStart = (nRows+1)*20;
        yFrameSize = 30+nRows*20;

        rowSpacing = 20;
        colSpacing = 110;
        hDoseFrame = uicontrol(hFig, 'units', units, 'style', 'frame', 'position', [10 10 235 yFrameSize]);
        hScanFrame = uicontrol(hFig, 'units', units, 'style', 'frame', 'position', [255 10 235 yFrameSize]);
        uicontrol(hFig, 'style', 'text', 'units', units, 'position', [10 yFrameSize-10 50 20], 'string', 'Doses', 'fontweight', 'bold');
        uicontrol(hFig, 'style', 'text', 'units', units, 'position', [255 yFrameSize-10 50 20], 'string', 'Scans', 'fontweight', 'bold');

        %Create dose uicontrols.
        for i=1:2*nRows
            col = floor((i-1)/nRows);
            doseUI(i) = uicontrol(hFig, 'units', units, 'position', [20+col*colSpacing yStart-(i-1-col*nRows)*rowSpacing 100 20], 'style', 'checkbox', 'string', '', 'visible', 'off', 'Callback', 'doseProfileFigure(''DOSE_CHECK'')', 'userdata', i);
        end

        %Create scan uicontrols.
        for i=1:2*nRows
            col = floor((i-1)/nRows);
            scanUI(i) = uicontrol(hFig, 'units', units, 'position', [265+col*colSpacing yStart-(i-1-col*nRows)*rowSpacing 100 20], 'style', 'checkbox', 'string', '', 'visible', 'off', 'Callback', 'doseProfileFigure(''SCAN_CHECK'')', 'userdata', i);
        end

        %Populate both.
        colors = stateS.optS.colorOrder;

        outString = cell(nDoses+1,1);

        outString{1} = 'Pick Reference Dose';

        for i=1:nDoses
            if ismember(i, initialDoseV);
                chkval = 1;
            else
                chkval = 0;
            end

            outString{i+1} = planC{indexS.dose}(i).fractionGroupID;
            color = getColor(i, colors, 'loop');
            if ~isLocal(planC{indexS.dose}(i).doseArray)
                doseString = [num2str(i) '. ' planC{indexS.dose}(i).fractionGroupID,'(R)'];
            else
                doseString = [num2str(i) '. ' planC{indexS.dose}(i).fractionGroupID];
            end
            set(doseUI(i), 'string', doseString, 'BackgroundColor', color, 'visible', 'on', 'value', chkval);
        end

        for i=1:nScans
            if ismember(i, initialScanV);
                chkval = 1;
            else
                chkval = 0;
            end

            color = getColor(i+nDoses, colors, 'loop');
            if ~isLocal(planC{indexS.scan}(i).scanArray)
                scanString = [num2str(i) '. ' planC{indexS.scan}(i).scanType,'(R)'];
            else
                scanString = [num2str(i) '. ' planC{indexS.scan}(i).scanType];
            end
            set(scanUI(i), 'string', scanString, 'BackgroundColor', color, 'visible', 'on', 'value', chkval);
        end

        %Store UI handles and other info for later use.
        ud.doseUI = doseUI;
        ud.baseDose = [];
        ud.scanUI = scanUI;
        ud.nDoses = nDoses;
        ud.nScans = nScans;
        ud.startPt = startPt;
        ud.endPt = endPt;

        % APA: Commented
        %         %Create axes.
        %         ud.doseaxis = axes('units', 'pixels', 'position', [50 yStart+100 400 h-yStart-150], 'parent', hFig, 'tickdir', 'out');
        %         xlabel('Distance along line');
        %         ylabel('Dose Value');
        %         ud.scanaxis = axes('units', 'pixels', 'position', [50 yStart+100 400 h-yStart-150], 'parent', hFig, 'tickdir', 'out', 'Color','none','YAxisLocation','right', 'xtick', []);
        %         ylabel('Scan Value');
        % APA: Commented ends

        % APA: try
        %Create axes.
        % ud.doseaxis = axes('units', 'pixels', 'position', [50 yStart+100+170 400 h-yStart-330], 'parent', hFig, 'tickdir', 'out','fontSize',8);
        ud.doseaxis = axes('units', 'pixels', 'position', [50 yStart+270+25 400 h-yStart-300], 'parent', hFig, 'tickdir', 'out','fontSize',8);
        % xlabel('\bfDistance along line','fontSize',10);
        xlabel({});
        ylabel('\bfDose Value','fontSize',10);
        % ud.scanaxis = axes('units', 'pixels', 'position', [50 yStart+100+170 400 h-yStart-330], 'parent', hFig, 'tickdir', 'out', 'Color','none','YAxisLocation','right', 'xtick', [],'fontSize',8);
        ud.scanaxis = axes('units', 'pixels', 'position', [50 yStart+270+25 400 h-yStart-300], 'parent', hFig, 'tickdir', 'out', 'Color','none','YAxisLocation','right', 'xtick', [],'fontSize',8);
        ylabel('\bfScan Value','fontSize',10);

        % APA: try ends

        % DK Radio button for selecting absolute or normalized scale
        clrBg = get(hFig,'color');

        radioToolTip = 'Choose Absolute(ABS) or Normalized (NOR) Scale for Dose Difference';
        h = uibuttongroup('parent',hFig,'units', 'pixels', 'visible','off','Position',[60 yStart+240 100 25]);
        u0 = uicontrol('Style','Radio','String','Abs',...
            'pos',[5 5 40 15],'parent',h,'HandleVisibility','off');
        u1 = uicontrol('Style','Radio','String','Rel',...
            'pos',[50 5 40 15],'parent',h,'HandleVisibility','off');
        set(h,'SelectionChangeFcn',@d_ct_profRadio);
        set(h,'SelectedObject',u0);  % No selection
        set(h,'Visible','on')


        % DK Drop down list to select the primary dose
        uicontrol('parent',hFig,'Style','Text','Units','Pixels','Position',[170 yStart+230 120 30],...
            'String','Select Base Dose','Background',clrBg);

        refDoseToolTip = 'Select the reference/Base Dose from which all doses will be subtracted';

        uicontrol('parent',hFig,'Style','popupmenu', 'Units','Pixels','Position',[300 yStart+220 100 40],'Tag','refDoseSelect',...
            'callback', 'doseProfileFigure(''selectrefDose'')','String',outString,'TooltipString',refDoseToolTip);

        % APA: Create  difference axis
        % ud.diffaxis = axes('units', 'pixels', 'position', [50 yStart+90 400 yStart+100+5], 'parent', hFig, 'tickdir', 'out','fontSize',8);
        ud.diffaxis = axes('units', 'pixels', 'position', [50 yStart+100 400 120], 'parent', hFig, 'tickdir', 'out','fontSize',8);
        xlabel('\bfDistance along line','fontSize',10);
        ylabel('\bfDifference','fontSize',10);
        ud.htext = [];

        % APA: Create  slider axis
        ud.slideraxis = axes('units', 'pixels', 'position', [40 yStart+220 420 15], 'parent', hFig,'visible','off');
        %         udS.xL = patch([0.025 0 0], [0.5 0 1], 'w', 'edgecolor', 'k', 'buttondownfcn', 'doseProfileFigure(''RANGERCLICKED'', ''xL'')', 'userdata', ud.slideraxis, 'parent', ud.slideraxis, 'erasemode', 'xor');
        %         udS.xR = patch([0.975 1 1], [0.5 0 1], 'w', 'edgecolor', 'k', 'buttondownfcn', 'doseProfileFigure(''RANGERCLICKED'', ''xR'')', 'userdata', ud.slideraxis, 'parent', ud.slideraxis, 'erasemode', 'xor');
        udS.xL = patch([0.025 0.025 0], [0 1 1], 'w', 'edgecolor', 'k', 'buttondownfcn', 'doseProfileFigure(''RANGERCLICKED'', ''xL'')', 'userdata', ud.slideraxis, 'parent', ud.slideraxis);
        udS.xR = patch([0.975 0.975 1], [0 1 1], 'w', 'edgecolor', 'k', 'buttondownfcn', 'doseProfileFigure(''RANGERCLICKED'', ''xR'')', 'userdata', ud.slideraxis, 'parent', ud.slideraxis);

        % Display initial text on difference axis
        grid(ud.diffaxis,'off')
        set(ud.diffaxis,'xLim',[0 1]);
        set(ud.diffaxis,'yLim',[0 1]);
        htextInit = text(0.1,0.5,'Select More than one dose to display difference','parent', ud.diffaxis,'HorizontalAlignment','left','FontWeight','bold');
        ud.htextInit = htextInit;
        set(hFig, 'userdata',ud);

        %Save userdata.
        set(hFig, 'userdata', ud);
        set(ud.slideraxis, 'userdata', udS);

    case 'SELECTREFDOSE'

        hFig = findobj('tag', 'CERR_DoseLineProfile');

        ud = get(hFig, 'userdata');

        doseUI  = ud.doseUI;

        value = get(findobj('Tag','refDoseSelect'),'value')-1;

        if value ~=0
            ud.baseDose = value;
            set(doseUI(ud.baseDose), 'FontWeight','bold');
        end

        set(hFig,'Userdata',ud);

    case 'RANGERCLICKED'
        hFig = findobj('tag', 'CERR_DoseLineProfile');
        ud    = get(hFig, 'userdata');
        udS   = get(ud.slideraxis, 'userdata');

        %Suspend figure while motion is going on, restore later.
        udS.UISTATE = uisuspend(hFig);

        %Determine which triangle is clicked.
        switch upper(varargin{1})
            case 'XL'
                udS.handle.movingObject = udS.xL;
                RangeMax = get(udS.xR, 'xData');
                udS.motionbounds = [0.025 RangeMax(1)];
            case 'XR'
                udS.handle.movingObject = udS.xR;
                RangeMin = get(udS.xL, 'xData');
                udS.motionbounds = [RangeMin(1) 0.975];
        end
        %Prepare object/figure for motion.
        %set(udS.handle.movingObject, 'erasemode', 'xor');
        set(hFig, 'windowbuttonmotionfcn', 'doseProfileFigure(''INDICATORMOVING'')')
        set(hFig, 'windowbuttonupfcn', 'doseProfileFigure(''MOTIONDONE'');')
        set(ud.slideraxis, 'userdata', udS);

    case 'INDICATORMOVING'
        hFig = findobj('tag', 'CERR_DoseLineProfile');
        ud    = get(hFig, 'userdata');
        hAxis = ud.slideraxis;
        udS   = get(ud.slideraxis, 'userdata');
        hObj  = udS.handle.movingObject;
        xData = get(hObj, 'xData');
        hAxis = ud.slideraxis;
        cp = get(hAxis, 'currentpoint');
        mB = udS.motionbounds;
        if cp(2,1) > udS.motionbounds(2)
            cp(2,1) = udS.motionbounds(2);
        elseif cp(2,1) < udS.motionbounds(1)
            cp(2,1) = udS.motionbounds(1);
        end
        delta = cp(2,1) - xData(1);
        %Move both the object and text string to new position.
        set(hObj, 'xData', xData+delta);
        doseProfileFigure('refresh');

    case 'MOTIONDONE'
        hFig = findobj('tag', 'CERR_DoseLineProfile');
        ud    = get(hFig, 'userdata');
        udS   = get(ud.slideraxis, 'userdata');

        %Restore the figure to pre-motion state.
        uirestore(udS.UISTATE);

        %Match position of arrow with rounded text value.
        %         hObj  = udS.handle.movingObject;
        %         xData = get(hObj, 'xData');
        %         cP    = str2num(get(ud.associatedText, 'string'));
        %         delta = cP - xData(1);
        %         set(hObj, 'xData', xData+delta);

        %set(udS.handle.movingObject, 'erasemode', 'xor');
        doseProfileFigure('refresh');


    case 'SCAN_CHECK'
        %Scan has been checked/unchecked.
        doseProfileFigure('refresh');

    case 'DOSE_CHECK'
        %Dose has been checked/unchecked.
        hFig = findobj('tag', 'CERR_DoseLineProfile');
        if isempty(hFig)
            return;
        end
        ud = get(hFig, 'userdata');
        nDoses  = ud.nDoses;
        doseUI  = ud.doseUI;
        delete(ud.htext)
        drawDoses = [];
        for i=1:nDoses
            drawDoses(i) = get(doseUI(i), 'value');
        end

        if isempty(ud.baseDose)
            %wy warndlg('Select Base Dose');
        end
        drawDoses = find(drawDoses);

        set(doseUI, 'FontWeight','normal');

        if ~ismember(drawDoses,ud.baseDose)
            set(doseUI(ud.baseDose), 'FontWeight','bold');
        end
        ud.htext = [];
        set(doseUI(ud.baseDose), 'FontWeight','bold');
        set(hFig, 'userdata',ud);
        doseProfileFigure('refresh');

    case 'NEW_POINTS'
        %New points specified for the profile line.
        hFig = findobj('tag', 'CERR_DoseLineProfile');
        ud = get(hFig, 'userdata');
        ud.startPt = varargin{1};
        ud.endPt = varargin{2};
        set(hFig, 'userdata', ud);

    case 'REFRESH'
        %Make sure only the most recent calls are drawn.
        global CERR_doseProfileLastCallTime;
        thisCallTime = now;
        if isempty(CERR_doseProfileLastCallTime)
            CERR_doseProfileLastCallTime = thisCallTime;
        else
            if thisCallTime > CERR_doseProfileLastCallTime
                CERR_doseProfileLastCallTime = thisCallTime;
            end
        end
        clear CERR_doseProfileLastCallTime;

        %Make dose profile figure the foreground.
        hFig = findobj('tag', 'CERR_DoseLineProfile');
        if isempty(hFig)
            return;
        end
        ud = get(hFig, 'userdata');
        udS   = get(ud.slideraxis, 'userdata');
        xDataL = get(udS.xL,'xData');
        x1 = xDataL(1);
        xDataR = get(udS.xR,'xData');
        x2 = xDataR(1);

        delete(ud.htext)
        ud.htext = [];

        figure(hFig);

        delete(findobj(hFig, 'Tag', 'CERR_DOSEPROFILE_PLOT'));

        nSamples = stateS.optS.numDoseProfileSamples;
        ptsDel = 1:nSamples;
        ptsL = nSamples/0.95*(x1-0.025);
        ptsR = nSamples/0.95*(x2-0.025);
        ptsDel = unique([1:floor(ptsL) ceil(ptsR+1e-6):nSamples]);

        %Get UD stored variables.
        doseUI  = ud.doseUI;
        baseDose = ud.baseDose;
        scanUI  = ud.scanUI;
        nDoses  = ud.nDoses;
        nScans  = ud.nScans;
        startPt = ud.startPt;
        endPt   = ud.endPt;

        if isempty(startPt) | isempty(endPt)
            return;
        end

        colors = stateS.optS.colorOrder;

        drawDoses = [];
        for i=1:nDoses
            drawDoses(i) = get(doseUI(i), 'value');
        end

        drawScans = [];
        for i=1:nScans
            drawScans(i) = get(scanUI(i), 'value');
        end

        drawDoses = find(drawDoses);
        drawScans = find(drawScans);

        %Get x,y,z coords of samples and distance from first pt.
        xV = linspace(startPt(1), endPt(1), nSamples);
        yV = linspace(startPt(2), endPt(2), nSamples);
        zV = linspace(startPt(3), endPt(3), nSamples);
        distV = sqrt(sepsq(startPt', [xV;yV;zV]));

        for i=1:length(drawDoses)
            set(ud.doseaxis, 'nextplot', 'add', 'tickdir', 'out');
            doseNum = drawDoses(i);
            transM = getTransM('dose', doseNum, planC);
            if ~isempty(transM)
                [xV1, yV1, zV1] = applyTransM(inv(transM), xV, yV, zV);
            else
                xV1 = xV; yV1 = yV; zV1 = zV;
            end
            dV{i} = getDoseAt(doseNum, xV1, yV1, zV1, planC);
            dV{i}(ptsDel) = NaN;
        end

        for i=1:length(drawScans)
            set(ud.scanaxis, 'nextplot', 'add', 'tickdir', 'out');
            scanNum = drawScans(i);
            transM = getTransM('scan', scanNum, planC);
            if ~isempty(transM)
                [xV1, yV1, zV1] = applyTransM(inv(transM), xV, yV, zV);
            else
                xV1 = xV; yV1 = yV; zV1 = zV;
            end
            sV{i} = getScanAt(scanNum, xV1, yV1, zV1, planC);
            sV{i}(ptsDel) = NaN;
        end

        global CERR_doseProfileLastCallTime
        if isequal(CERR_doseProfileLastCallTime, thisCallTime)
            for i=1:length(drawDoses)
                doseNum = drawDoses(i);
                plot(distV, dV{i}, 'parent', ud.doseaxis, 'color', getColor(doseNum, colors, 'loop'), 'Tag', 'CERR_DOSEPROFILE_PLOT','linewidth',2);
            end
            axis(ud.doseaxis,'tight')
            for i=1:length(drawScans)
                scanNum = drawScans(i);
                plot(distV, sV{i}, 'parent', ud.scanaxis, 'color', getColor(scanNum+nDoses, colors, 'loop'), 'Tag', 'CERR_DOSEPROFILE_PLOT','linewidth',2);
            end
            axis(ud.scanaxis,'tight')

            if exist('dV') & length(dV)>1 & ~isempty(ud.baseDose)
                delete(ud.htextInit)
                ud.htextInit = [];
                set(ud.diffaxis,'XTickLabelMode','auto','YTickLabelMode','auto')
                set(ud.diffaxis,'nextplot','add')
                otherDoses = drawDoses;
                baseDoseInd = find(otherDoses==baseDose);
                otherDosesInd = 1:length(otherDoses);
                otherDosesInd(baseDoseInd) = [];
                otherDoses(baseDoseInd) = [];

                for i=1:length(otherDosesInd)
                    ddV{i} = dV{otherDosesInd(i)}-dV{baseDoseInd};
                    if max(ddV{i})== 0
                        nddV{i} = ddV{i};
                    else
                        nddV{i} = ddV{i}/max(dV{baseDoseInd});
                    end
                end

                for i=1:length(ddV)
                    ddoseNum = otherDoses(i);
                    if strcmpi(stateS.doseDiffScale, 'Abs')
                        plot(distV, ddV{i}, 'parent', ud.diffaxis, 'color', getColor(ddoseNum, colors, 'loop'), 'Tag', 'CERR_DOSEPROFILE_PLOT','linewidth',2);
                    elseif strcmpi(stateS.doseDiffScale, 'Rel')
                        plot(distV, nddV{i}, 'parent', ud.diffaxis, 'color', getColor(ddoseNum, colors, 'loop'), 'Tag', 'CERR_DOSEPROFILE_PLOT','linewidth',2);
                    end

                end
                axis(ud.diffaxis,'tight')
                grid(ud.diffaxis,'on')
                ax = axis(ud.diffaxis);
                %text1 = get(doseUI(baseDose),'String');
                %dispText = [text1,' - other doses'];
                dispText = ['Dose - Ref'];
                htext = text(ax(2)-(ax(2)-ax(1))*0.03,ax(4)-(ax(4)-ax(3))*0.1,dispText,'parent', ud.diffaxis,'HorizontalAlignment','right','FontWeight','bold');
                ud.htext = htext;
                set(hFig, 'userdata',ud);
                xlabel(ud.diffaxis,'\bfDistance along line','fontSize',10);
                ylabel(ud.diffaxis,'\bfDifference','fontSize',10);
            else
                grid(ud.diffaxis,'off')
                set(ud.diffaxis,'xLim',[0 1]);
                set(ud.diffaxis,'yLim',[0 1]);
                set(ud.diffaxis,'XTickLabelMode','manual','YTickLabelMode','manual','XTickLabel',[],'YTickLabel',[]);
                delete(ud.htextInit)
                htextInit = text(0.1,0.5,'Select More than one dose to display difference','parent', ud.diffaxis,'HorizontalAlignment','left','FontWeight','bold');
                ud.htextInit = htextInit;
                ud.htext =[];
                set(hFig, 'userdata',ud);
            end

        end

    case 'CLOSE'
        if stateS.doseProfileState
            sliceCallBack('TOGGLEDOSEPROFILE');
        end
end
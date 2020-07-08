function DVHRobustnessGUI(command,varargin)
%function DVHRobustnessGUI(command,varargin)
%
% APA, 04/05/09
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

global planC stateS
indexS = planC{end};

if nargin==0
    command = 'INIT';
end

switch upper(command)

    case 'INIT'

        % define margin constraints
        leftMarginWidth = 300;
        topMarginHeight = 50;
        stateS.leftMarginWidth = leftMarginWidth;
        stateS.topMarginHeight = topMarginHeight;

        str1 = ['Plan Robustness Analysis'];
        position = [5 40 800 600];

        defaultColor = [0.8 0.9 0.9];

        if isempty(findobj('tag','robustDVHFig'))
            
            % initialize main GUI figure
            hFig = figure('tag','robustDVHFig','name',str1,'numbertitle','off','position',position,...
                'CloseRequestFcn', 'DVHRobustnessGUI(''closeRequest'')','menubar','none','resize','off','color',defaultColor);
        else
            figure(findobj('tag','robustDVHFig'))
            return
        end
        %stateS.hFig = hFig;

        figureWidth = position(3); figureHeight = position(4);
        posTop = figureHeight-topMarginHeight;

        % create title handles
        handle(1) = uicontrol(hFig,'tag','titleFrame','units','pixels','Position',[150 figureHeight-topMarginHeight+5 500 40 ],'Style','frame','backgroundColor',defaultColor);
        handle(2) = uicontrol(hFig,'tag','title','units','pixels','Position',[151 figureHeight-topMarginHeight+10 498 30 ], 'String','Plan Robustness Analysis using DVHs','Style','text', 'fontSize',10,'FontWeight','Bold','HorizontalAlignment','center','backgroundColor',defaultColor);
        handle(3) = uicontrol(hFig,'tag','titleFrame','units','pixels','Position',[leftMarginWidth+8 250 1 figureHeight-topMarginHeight-260 ],'Style','frame','backgroundColor',defaultColor);

        % create Dose and structure handles
        inputH(1) = uicontrol(hFig,'tag','doseStructTitle','units','pixels','Position',[20 posTop-40 150 20], 'String','DOSE & STRUCTURE','Style','text', 'fontSize',9.5,'FontWeight','Bold','BackgroundColor',defaultColor,'HorizontalAlignment','left');
        prefix = 'Select a dose.';
        doseList = {prefix, planC{indexS.dose}.fractionGroupID};
        prefix = 'Select a structure.';
        structList = {prefix, planC{indexS.structures}.structureName};
        inputH(2) = uicontrol(hFig,'tag','doseStatic','units','pixels','Position',[20 posTop-70 120 20], 'String','Select Dose','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','right');
        inputH(3) = uicontrol(hFig,'tag','doseSelect','units','pixels','Position',[150 posTop-70 120 20], 'String',doseList,'Style','popup', 'fontSize',9,'FontWeight','normal','BackgroundColor',[1 1 1],'HorizontalAlignment','left');
        inputH(4) = uicontrol(hFig,'tag','structStatic','units','pixels','Position',[20 posTop-100 120 20], 'String','Select Structure','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','right');
        inputH(5) = uicontrol(hFig,'tag','structSelect','units','pixels','Position',[150 posTop-100 120 20], 'String',structList,'Style','popup', 'fontSize',9,'FontWeight','normal','BackgroundColor',[1 1 1],'HorizontalAlignment','left');

        inputH(6) = uicontrol(hFig,'tag','simulationParamsTitle','units','pixels','Position',[20 posTop-140 180 20], 'String','SIMULATION PARAMETERS','Style','text', 'fontSize',9.5,'FontWeight','Bold','BackgroundColor',defaultColor,'HorizontalAlignment','left');
        inputH(7) = uicontrol(hFig,'tag','doseFxStatic','units','pixels','Position',[20 posTop-170 120 20], 'String','No. of Dose-Fractions','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','right');
        inputH(8) = uicontrol(hFig,'tag','doseFxEdit','units','pixels','Position',[150 posTop-170 120 20], 'String','','Style','edit', 'fontSize',9,'FontWeight','normal','BackgroundColor',[1 1 1],'HorizontalAlignment','left');
        inputH(9) = uicontrol(hFig,'tag','numTrialStatic','units','pixels','Position',[20 posTop-200 120 20], 'String','No. of Trials','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','right');
        inputH(10) = uicontrol(hFig,'tag','numTrialEdit','units','pixels','Position',[150 posTop-200 120 20], 'String','','Style','edit', 'fontSize',9,'FontWeight','normal','BackgroundColor',[1 1 1],'HorizontalAlignment','left');

        inputH(11) = uicontrol(hFig,'tag','shiftStatic','units','pixels','Position',[20 posTop-240 70 30], 'String','Systematic Shift (cm/deg)','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','left');
        %uicontrol(hFig,'units','pixels','Position',[90 posTop-245 30 20], 'String','(cm)','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','left');
        inputH(12) = uicontrol(hFig,'tag','xShiftSysEdit','units','pixels','Position',[100 posTop-230 30 20], 'String','','Style','edit', 'fontSize',8,'FontWeight','normal','BackgroundColor',[1 1 1],'HorizontalAlignment','center');
        uicontrol(hFig,'units','pixels','Position',[100 posTop-250 25 20], 'String','x-dir','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','center');
        inputH(13) = uicontrol(hFig,'tag','yShiftSysEdit','units','pixels','Position',[135 posTop-230 30 20], 'String','','Style','edit', 'fontSize',8,'FontWeight','normal','BackgroundColor',[1 1 1],'HorizontalAlignment','center');
        uicontrol(hFig,'units','pixels','Position',[135 posTop-250 25 20], 'String','y-dir','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','center');
        inputH(14) = uicontrol(hFig,'tag','zShiftSysEdit','units','pixels','Position',[170 posTop-230 30 20], 'String','','Style','edit', 'fontSize',8,'FontWeight','normal','BackgroundColor',[1 1 1],'HorizontalAlignment','center');
        uicontrol(hFig,'units','pixels','Position',[170 posTop-250 25 20], 'String','z-dir','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','center');
        inputH(15) = uicontrol(hFig,'tag','xRotSysEdit','units','pixels','Position',[205 posTop-230 30 20], 'String','0','Style','edit', 'fontSize',8,'FontWeight','normal','BackgroundColor',[1 1 1],'HorizontalAlignment','center','enable','off');
        uicontrol(hFig,'units','pixels','Position',[205 posTop-250 25 20], 'String','x-rot','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','center');
        inputH(16) = uicontrol(hFig,'tag','yRotSysEdit','units','pixels','Position',[240 posTop-230 30 20], 'String','0','Style','edit', 'fontSize',8,'FontWeight','normal','BackgroundColor',[1 1 1],'HorizontalAlignment','center','enable','off');
        uicontrol(hFig,'units','pixels','Position',[240 posTop-250 25 20], 'String','y-rot','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','center');
        inputH(17) = uicontrol(hFig,'tag','zRotSysEdit','units','pixels','Position',[275 posTop-230 30 20], 'String','0','Style','edit', 'fontSize',8,'FontWeight','normal','BackgroundColor',[1 1 1],'HorizontalAlignment','center','enable','off');
        uicontrol(hFig,'units','pixels','Position',[275 posTop-250 25 20], 'String','z-rot','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','center');
        
        inputH(18) = uicontrol(hFig,'tag','shiftStatic','units','pixels','Position',[20 posTop-280 70 30], 'String','Random Shift (cm/deg)','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','left');
        %uicontrol(hFig,'units','pixels','Position',[90 posTop-245 30 20], 'String','(cm)','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','left');
        inputH(19) = uicontrol(hFig,'tag','xShiftRndEdit','units','pixels','Position',[100 posTop-270 30 20], 'String','','Style','edit', 'fontSize',8,'FontWeight','normal','BackgroundColor',[1 1 1],'HorizontalAlignment','center');
        uicontrol(hFig,'units','pixels','Position',[100 posTop-290 25 20], 'String','x-dir','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','center');
        inputH(20) = uicontrol(hFig,'tag','yShiftRndEdit','units','pixels','Position',[135 posTop-270 30 20], 'String','','Style','edit', 'fontSize',8,'FontWeight','normal','BackgroundColor',[1 1 1],'HorizontalAlignment','center');
        uicontrol(hFig,'units','pixels','Position',[135 posTop-290 25 20], 'String','y-dir','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','center');
        inputH(21) = uicontrol(hFig,'tag','zShiftRndEdit','units','pixels','Position',[170 posTop-270 30 20], 'String','','Style','edit', 'fontSize',8,'FontWeight','normal','BackgroundColor',[1 1 1],'HorizontalAlignment','center');
        uicontrol(hFig,'units','pixels','Position',[170 posTop-290 25 20], 'String','z-dir','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','center');
        inputH(22) = uicontrol(hFig,'tag','xRotRndEdit','units','pixels','Position',[205 posTop-270 30 20], 'String','0','Style','edit', 'fontSize',8,'FontWeight','normal','BackgroundColor',[1 1 1],'HorizontalAlignment','center','enable','off');
        uicontrol(hFig,'units','pixels','Position',[205 posTop-290 25 20], 'String','x-rot','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','center');
        inputH(23) = uicontrol(hFig,'tag','yRotRndEdit','units','pixels','Position',[240 posTop-270 30 20], 'String','0','Style','edit', 'fontSize',8,'FontWeight','normal','BackgroundColor',[1 1 1],'HorizontalAlignment','center','enable','off');
        uicontrol(hFig,'units','pixels','Position',[240 posTop-290 25 20], 'String','y-rot','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','center');
        inputH(24) = uicontrol(hFig,'tag','zRotRndEdit','units','pixels','Position',[275 posTop-270 30 20], 'String','0','Style','edit', 'fontSize',8,'FontWeight','normal','BackgroundColor',[1 1 1],'HorizontalAlignment','center','enable','off');
        uicontrol(hFig,'units','pixels','Position',[275 posTop-290 25 20], 'String','z-rot','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','center');

        
        %Create Dose-Stats handles
        uicontrol(hFig,'tag','titleFrame','units','pixels','Position',[20 figureHeight-topMarginHeight-525 760 200 ],'Style','frame','backgroundColor',defaultColor);
        dvhStatH(1) = uicontrol(hFig,'tag','dvhStatsTitle','units','pixels','Position',[25 posTop-350 150 20], 'String','DVH Robustness Stats','Style','text', 'fontSize',9.5,'FontWeight','Bold','BackgroundColor',defaultColor,'HorizontalAlignment','left');
        dvhStatH(2) = uicontrol(hFig,'tag','dvhSelect','units','pixels','Position',[25 posTop-375 140 20], 'String',{'None'},'Style','popup', 'fontSize',9,'FontWeight','normal','BackgroundColor',[1 1 1],'HorizontalAlignment','left','callback', 'DVHRobustnessGUI(''PLOT_DVH'')');
        
        dvhStatH(3) = uicontrol(hFig,'tag','numTrials','units','pixels','Position',[25 posTop-440 200 20], 'String','numTrials','Style','text', 'fontSize',9,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','left');        
        dvhStatH(4) = uicontrol(hFig,'tag','numFractions','units','pixels','Position',[25 posTop-465 200 20], 'String','numFractions','Style','text', 'fontSize',9,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','left');
        dvhStatH(5) = uicontrol(hFig,'tag','xyzShift','units','pixels','Position',[25 posTop-515 700 20], 'String','Shifts','Style','text', 'fontSize',9,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','left');
        
        dvhStatH(6) = uicontrol(hFig,'tag','sigmaStatic','units','pixels','Position',[250 posTop-355 50 20], 'String','Bounds:','Style','text', 'fontSize',9,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','left');
        dvhStatH(7) = uicontrol(hFig,'tag','sigmaSelect','units','pixels','Position',[300 posTop-350 80 20], 'String',{'Select Confidence Bounds','1-Sigma','2-Sigma','3-Sigma'},'Style','popup', 'fontSize',9,'FontWeight','normal','BackgroundColor',[1 1 1],'HorizontalAlignment','left','callback', 'DVHRobustnessGUI(''PLOT_DVH'')');
        dvhStatH(8) = uicontrol(hFig,'tag','LB','units','pixels','Position',[450 posTop-360 66 25], 'String','Lower Bound','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','center');
        dvhStatH(9) = uicontrol(hFig,'tag','Mean','units','pixels','Position',[530 posTop-360 65 25], 'String','Mean','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','center');
        dvhStatH(10) = uicontrol(hFig,'tag','UB','units','pixels','Position',[610 posTop-360 65 25], 'String','Upper Bound','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','center');
        dvhStatH(11) = uicontrol(hFig,'tag','Obs','units','pixels','Position',[690 posTop-360 65 25], 'String','Observed','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','center');

        
        alternateColor = [0.9 0.9 0.9];
        
        dvhStatH(12) = uicontrol(hFig,'tag','bgColorTxt','units','pixels','Position',[250 posTop-385 460 25], 'String','','Style','text', 'fontSize',9,'FontWeight','normal','BackgroundColor',alternateColor,'HorizontalAlignment','left');        
        dvhStatH(13) = uicontrol(hFig,'tag','meanDoseStatic','units','pixels','Position',[250 posTop-385 100 25], 'String','Mean Dose:','Style','text', 'fontSize',9,'FontWeight','normal','BackgroundColor',alternateColor,'HorizontalAlignment','left');        
        dvhStatH(14) = uicontrol(hFig,'tag','meanDoseLBTxt','units','pixels','Position',[450 posTop-385 60 25], 'String','lb','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',alternateColor,'HorizontalAlignment','center');
        dvhStatH(15) = uicontrol(hFig,'tag','meanDoseMeanTxt','units','pixels','Position',[530 posTop-385 60 25], 'String','mean','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',alternateColor,'HorizontalAlignment','center');
        dvhStatH(16) = uicontrol(hFig,'tag','meanDoseUBTxt','units','pixels','Position',[610 posTop-385 60 25], 'String','ub','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',alternateColor,'HorizontalAlignment','center');
        dvhStatH(17) = uicontrol(hFig,'tag','meanDoseObserTxt','units','pixels','Position',[690 posTop-385 60 25], 'String','observed','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',alternateColor,'HorizontalAlignment','center');
        
        dvhStatH(18) = uicontrol(hFig,'tag','minDoseStatic','units','pixels','Position',[250 posTop-415 100 25], 'String','Min Dose:','Style','text', 'fontSize',9,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','left');        
        dvhStatH(19) = uicontrol(hFig,'tag','minDoseLBTxt','units','pixels','Position',[450 posTop-415 60 25], 'String','lb','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','center');
        dvhStatH(20) = uicontrol(hFig,'tag','minDoseMeanTxt','units','pixels','Position',[530 posTop-415 60 25], 'String','mean','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','center');
        dvhStatH(21) = uicontrol(hFig,'tag','minDoseUBTxt','units','pixels','Position',[610 posTop-415 60 25], 'String','ub','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','center');
        dvhStatH(22) = uicontrol(hFig,'tag','minDoseObserTxt','units','pixels','Position',[690 posTop-415 60 25], 'String','observed','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','center');

        dvhStatH(23) = uicontrol(hFig,'tag','bgColorTxt','units','pixels','Position',[250 posTop-445 460 25], 'String','','Style','text', 'fontSize',9,'FontWeight','normal','BackgroundColor',alternateColor,'HorizontalAlignment','left');        
        dvhStatH(24) = uicontrol(hFig,'tag','maxDoseStatic','units','pixels','Position',[250 posTop-445 100 25], 'String','Max Dose:','Style','text', 'fontSize',9,'FontWeight','normal','BackgroundColor',alternateColor,'HorizontalAlignment','left');        
        dvhStatH(25) = uicontrol(hFig,'tag','maxDoseLBTxt','units','pixels','Position',[450 posTop-445 60 25], 'String','lb','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',alternateColor,'HorizontalAlignment','center');
        dvhStatH(26) = uicontrol(hFig,'tag','maxDoseMeanTxt','units','pixels','Position',[530 posTop-445 60 25], 'String','mean','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',alternateColor,'HorizontalAlignment','center');
        dvhStatH(27) = uicontrol(hFig,'tag','maxDoseUBTxt','units','pixels','Position',[610 posTop-445 60 25], 'String','ub','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',alternateColor,'HorizontalAlignment','center');
        dvhStatH(28) = uicontrol(hFig,'tag','maxDoseObserTxt','units','pixels','Position',[690 posTop-445 60 25], 'String','observed','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',alternateColor,'HorizontalAlignment','center');
        
        dvhStatH(29) = uicontrol(hFig,'tag','volAbovDoseStatic','units','pixels','Position',[250 posTop-475 60 25], 'String','Vol. above','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','left');        
        dvhStatH(30) = uicontrol(hFig,'tag','volAbovDoseEdit','units','pixels','Position',[310 posTop-467 50 20], 'String','','Style','edit', 'fontSize',8,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','left','callback', 'DVHRobustnessGUI(''DOSEVAL'')');
        dvhStatH(31) = uicontrol(hFig,'tag','GyStatic','units','pixels','Position',[370 posTop-475 20 25], 'String','Gy','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','left');        
        dvhStatH(32) = uicontrol(hFig,'tag','volAbovDoseLBTxt','units','pixels','Position',[450 posTop-475 60 25], 'String','','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','center');
        dvhStatH(33) = uicontrol(hFig,'tag','volAbovDoseMeanTxt','units','pixels','Position',[530 posTop-475 60 25], 'String','','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','center');
        dvhStatH(34) = uicontrol(hFig,'tag','volAbovDoseUBTxt','units','pixels','Position',[610 posTop-475 60 25], 'String','','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','center');
        dvhStatH(35) = uicontrol(hFig,'tag','volAbovDoseObserTxt','units','pixels','Position',[690 posTop-475 60 25], 'String','','Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',defaultColor,'HorizontalAlignment','center');
        
        %Visible?
        dvhStatH(36) = uicontrol(hFig, 'tag','showPlot', 'style', 'checkbox', 'position', [25 posTop-410 80 20], 'string', 'Show Plot', 'horizontalAlignment', 'center','BackgroundColor',defaultColor, 'callback', 'DVHRobustnessGUI(''TOGGLE_VISIBILITY'')');

        %control to display legend in new figure
        dvhStatH(37) = uicontrol(hFig, 'tag','showLegend', 'style', 'checkbox', 'position', [110 posTop-410 100 20], 'string', 'Legend', 'horizontalAlignment', 'center','BackgroundColor',defaultColor, 'callback', 'DVHRobustnessGUI(''LEGENDCALL'')');
        
        %Define DVH-plot Axis
        plotH(1) = axes('parent',hFig,'tag','dvhAxis','tickdir', 'out','nextplot', 'add','units','pixels','Position',[leftMarginWidth+70 posTop*2/4-00 figureWidth-leftMarginWidth-100 posTop*0.9/2], 'color',defaultColor,'YAxisLocation','left','fontSize',8,'visible','off');        
        
        yLim = get(plotH(1), 'yLim');
        dvhStatH(38) = line([0 0], [yLim(1) yLim(2)], 'tag','motionLine','color', 'blue', 'parent', plotH(1), 'hittest', 'off','visible','off');

        submitH(1) = uicontrol(hFig,'tag','SubmitPush','units','pixels','Position',[20 posTop-315 160 25], 'String','Compute DVH Robustness','Style','push', 'fontSize',9,'FontWeight','normal','BackgroundColor',[1 1 1],'HorizontalAlignment','center','callback','DVHRobustnessGUI(''COMPUTE_DVH'')');
        %submitH(2) = uicontrol(hFig,'tag','SubmitPush','units','pixels','Position',[160 posTop-290 130 25], 'String','Clear computed DVHs','Style','push', 'fontSize',8,'FontWeight','normal','BackgroundColor',[1 1 1],'HorizontalAlignment','center','callback','DVHRobustnessGUI(''CLEAR'')');
        
        DVHInitS = struct('dosesV','',...
            'meanDoseV','',...
            'stdDoseV','',...
            'volsV','',...
            'binWidth','',...
            'doseNum','',...
            'structNum','',...
            'numFractions','',...
            'numTrials','',...
            'xShift','',...
            'yShift','',...
            'zShift','',...
            'handles','');
        
        DVHInitS(1) = [];
        
        ud.DVH = DVHInitS;     
        ud.handle.inputH = inputH;
        ud.handle.DVHStatH = dvhStatH;
        set(ud.handle.DVHStatH(3:end),'visible','off')
        
        ud.currentDVHS.hLB = [];
        ud.currentDVHS.hUB = [];
        ud.currentDVHS.hObserved = [];
        ud.currentDVHS.hPatch = [];
        
        set(hFig,'userdata',ud);
        
       
    case 'COMPUTE_DVH'
        
        hFig = findobj('tag','robustDVHFig');
        ud = get(hFig,'userdata');
        
        doseNum         = get(findobj(ud.handle.inputH,'tag','doseSelect'),'value')-1;
        structNum       = get(findobj(ud.handle.inputH,'tag','structSelect'),'value')-1;
        numFractions    = str2num(get(findobj(ud.handle.inputH,'tag','doseFxEdit'),'string'));
        numTrials       = str2num(get(findobj(ud.handle.inputH,'tag','numTrialEdit'),'string'));
        
        XdispSys_Std    = str2num(get(findobj(ud.handle.inputH,'tag','xShiftSysEdit'),'string'));
        YdispSys_Std    = str2num(get(findobj(ud.handle.inputH,'tag','yShiftSysEdit'),'string'));
        ZdispSys_Std    = str2num(get(findobj(ud.handle.inputH,'tag','zShiftSysEdit'),'string'));
        XrotSys_Std     = str2num(get(findobj(ud.handle.inputH,'tag','xRotSysEdit'),'string'));
        YrotSys_Std     = str2num(get(findobj(ud.handle.inputH,'tag','yRotSysEdit'),'string'));
        ZrotSys_Std     = str2num(get(findobj(ud.handle.inputH,'tag','zRotSysEdit'),'string'));
        
        XdispRnd_Std    = str2num(get(findobj(ud.handle.inputH,'tag','xShiftRndEdit'),'string'));
        YdispRnd_Std    = str2num(get(findobj(ud.handle.inputH,'tag','yShiftRndEdit'),'string'));
        ZdispRnd_Std    = str2num(get(findobj(ud.handle.inputH,'tag','zShiftRndEdit'),'string'));
        XrotRnd_Std     = str2num(get(findobj(ud.handle.inputH,'tag','xRotRndEdit'),'string'));
        YrotRnd_Std     = str2num(get(findobj(ud.handle.inputH,'tag','yRotRndEdit'),'string'));
        ZrotRnd_Std     = str2num(get(findobj(ud.handle.inputH,'tag','zRotRndEdit'),'string'));        
        
        [dosesV, meanDoseV, stdDoseV, volsV, binWidth, doseBins, volsHist, volsHistStdV] = getRobustDVH(doseNum,structNum,numFractions,numTrials,XdispSys_Std,YdispSys_Std,ZdispSys_Std,XrotSys_Std,YrotSys_Std,ZrotSys_Std,XdispRnd_Std,YdispRnd_Std,ZdispRnd_Std,XrotRnd_Std,YrotRnd_Std,ZrotRnd_Std,planC);
        
        hFig = findobj('tag','robustDVHFig');
        ud = get(hFig,'userdata');

        numDVH = length(ud.DVH);
        ud.DVH(numDVH+1).doseNum        = doseNum;
        ud.DVH(numDVH+1).structNum      = structNum;
        ud.DVH(numDVH+1).numFractions   = numFractions;
        ud.DVH(numDVH+1).numTrials      = numTrials;
        ud.DVH(numDVH+1).xShift         = [XdispSys_Std, XdispRnd_Std, XrotSys_Std, XdispRnd_Std];
        ud.DVH(numDVH+1).yShift         = [YdispSys_Std, YdispRnd_Std, YrotSys_Std, YdispRnd_Std];
        ud.DVH(numDVH+1).zShift         = [ZdispSys_Std, ZdispRnd_Std, ZrotSys_Std, YdispRnd_Std];
        
        ud.DVH(numDVH+1).dosesV         = dosesV;
        ud.DVH(numDVH+1).meanDoseV      = meanDoseV;
        ud.DVH(numDVH+1).stdDoseV       = stdDoseV;
        ud.DVH(numDVH+1).volsV          = volsV;
        ud.DVH(numDVH+1).binWidth       = binWidth;
        ud.DVH(numDVH+1).doseBins       = doseBins;
        ud.DVH(numDVH+1).volsHist       = volsHist;
        ud.DVH(numDVH+1).volsHistStdV   = volsHistStdV;

        hDVH_num = findobj(ud.handle.DVHStatH,'tag','dvhSelect');        
        DVHstrC = {'None'};
        for i=1:numDVH+1
            DVHstrC{i+1} = [planC{indexS.structures}(ud.DVH(i).structNum).structureName,' (', planC{indexS.dose}(ud.DVH(i).doseNum).fractionGroupID,')'];
        end
        set(hDVH_num,'string',DVHstrC)
        set(hDVH_num,'value',numDVH+2)
        set(hFig,'userdata',ud)
        
        DVHRobustnessGUI('PLOT_DVH')       
        
        
    case 'PLOT_DVH'

        hFig = findobj('tag','robustDVHFig');
        
        %Get Robust DVH structure to plot
        ud = get(hFig,'userdata');
        hAxis = findobj('tag','dvhAxis');
        
        hDVH_num = findobj(ud.handle.DVHStatH,'tag','dvhSelect');
        DVHnum = get(hDVH_num,'value') - 1;

        if DVHnum == 0           
            try
                delete(ud.currentDVHS.hHighlight)
                set(ud.handle.DVHStatH(3:end),'visible','off')
            end
            ud.currentDVHS.hLB = [];
            ud.currentDVHS.hUB = [];
            ud.currentDVHS.hObserved = [];
            ud.currentDVHS.hPatch = [];
            ud.currentDVHS.hMean = [];
            ud.currentDVHS.hHighlight = [];
            for i=1:length(ud.DVH)
                set(ud.DVH(i).handles,'visible','off')
            end
            set(hAxis,'visible','off')
            set(hAxis, 'buttonDownFcn', '');  
            set(hFig,'userdata',ud);
            return;            
        end
        set(ud.handle.DVHStatH(3:end),'visible','on')
        
        set(hAxis, 'buttonDownFcn', 'DVHRobustnessGUI(''CLICKINPLOT'')');
        
        DVHs = ud.DVH(DVHnum);
        
        %Delete old handles
        try, delete(DVHs.handles), end
        DVHs.handles = [];
        
        dosesV = DVHs.dosesV;
        meanDoseV = DVHs.meanDoseV;
        stdDoseV = DVHs.stdDoseV;
        volsV = DVHs.volsV;
        binWidth = DVHs.binWidth;
        doseBins = DVHs.doseBins;
        volsHist = DVHs.volsHist;
        volsHistStdV = DVHs.volsHistStdV;
        
        %Display Simulation Parameters
        hTrial      = findobj(ud.handle.DVHStatH,'tag','numTrials');
        set(hTrial,'string',['No. of Trials = ',num2str(DVHs.numTrials)])
        hFraction   = findobj(ud.handle.DVHStatH,'tag','numFractions');
        set(hFraction,'string',['No. of Tx Fractions = ',num2str(DVHs.numFractions)])
        hShift      = findobj(ud.handle.DVHStatH,'tag','xyzShift');
        set(hShift,'string',['Shift (x,y,z) = (',num2str(DVHs.xShift),', ',num2str(DVHs.yShift),', ',num2str(DVHs.zShift),')'])
        
        sigmaH = findobj(ud.handle.DVHStatH,'tag','sigmaSelect');
        sigma = get(sigmaH,'value');  
        sigma = sigma - 1;
        
        %Structure color
        colorV = planC{indexS.structures}(DVHs.structNum).structureColor;
        
        axis(hAxis,'auto')        
        
        %Plot Mean
        doseBinsMeanV = doseBins{1};
        volsHistMeanV = volsHist{1};
        for iTrilal = 2:length(volsHist)
            volsHistMeanV = volsHistMeanV + volsHist{iTrilal};
        end
        volsHistMeanV = volsHistMeanV/length(volsHist);
        cumVolsMeanV  = cumsum(volsHistMeanV);
        cumVolsMean2V = cumVolsMeanV(end) - cumVolsMeanV;  %cumVolsV is the cumulative volume lt that corresponding dose
              
        hMean = plot([0 doseBinsMeanV], [1 cumVolsMean2V/cumVolsMeanV(end)],'LineStyle','--','color',colorV,'parent',hAxis);
        xMeanVals = [0, doseBinsMeanV];
        yMeanVals = [1, cumVolsMean2V/cumVolsMeanV(end)];
        [xMeanVals, aInd] = unique(xMeanVals);
        yMeanVals = yMeanVals(aInd);
        ud.currentDVHS.xMeanVals = xMeanVals;
        ud.currentDVHS.yMeanVals = yMeanVals;
        ud.currentDVHS.hMean = hMean;
        DVHs.handles = [DVHs.handles hMean];

        %Plot Mean-stdxSigma
        doseBinsMinV = doseBinsMeanV;
        volsHistMinV = max(0,volsHistMeanV - sigma*volsHistStdV);
        cumVolsMinV  = cumsum(volsHistMinV);
        cumVolsMin2V = cumVolsMinV(end) - cumVolsMinV;  %cumVolsV is the cumulative volume lt that corresponding dose
        hLB = [];
        xLBVals = [0, doseBinsMinV];
        yLBVals = [1, cumVolsMin2V/cumVolsMinV(end)];
        [xLBVals, aInd] = unique(xLBVals);
        yLBVals = yLBVals(aInd);
        ud.currentDVHS.xLBVals = xLBVals;
        ud.currentDVHS.yLBVals = yLBVals;
        ud.currentDVHS.hLB = hLB;
        DVHs.handles = [DVHs.handles hLB];

        %Plot Mean+stdxSigma
        %[doseBinsMaxV, volsHistMaxV] = doseHist(meanDoseV + sigma*stdDoseV, volsV, binWidth);
        doseBinsMaxV = doseBinsMeanV;
        volsHistMaxV = max(0,volsHistMeanV + sigma*volsHistStdV);
        cumVolsMaxV  = cumsum(volsHistMaxV);
        cumVolsMax2V = cumVolsMaxV(end) - cumVolsMaxV;  %cumVolsV is the cumulative volume lt that corresponding dose
        %try, delete(ud.currentDVHS.hUB), end
        %hUB = plot(hAxis,[0 doseBinsMaxV], [1 cumVolsMax2V/cumVolsMaxV(end)],'LineStyle','--','color',colorV,'parent',hAxis);
        hUB = [];
        xUBVals = [0, doseBinsMaxV];
        yUBVals = [1, cumVolsMax2V/cumVolsMaxV(end)];
        [xUBVals, aInd] = unique(xUBVals);
        yUBVals = yUBVals(aInd);
        ud.currentDVHS.xUBVals = xUBVals;
        ud.currentDVHS.yUBVals = yUBVals;
        ud.currentDVHS.hUB = hUB;
        DVHs.handles = [DVHs.handles hUB];

        if sigma > 0
            %try, delete(ud.currentDVHS.hPatch), end
            hPatch = patch([0 doseBinsMaxV fliplr(doseBinsMinV)], [1 cumVolsMax2V/cumVolsMaxV(end) fliplr(cumVolsMin2V)/cumVolsMinV(end)],colorV,'EdgeColor','None','faceAlpha',0.2,'parent',hAxis);
            ud.currentDVHS.hPatch = hPatch;
            DVHs.handles = [DVHs.handles hPatch];
        else
            try, delete(ud.currentDVHS.hPatch); end
            ud.currentDVHS.hPatch = [];
        end

        %Plot Current DVH
        [doseBinsObsV, volsHistObsV] = doseHist(dosesV, volsV, binWidth);
        cumVolsV  = cumsum(volsHistObsV);
        cumVols2V = cumVolsV(end) - cumVolsV;  %cumVolsV is the cumulative volume lt that corresponding dose
        %try, delete(ud.currentDVHS.hObserved), end
        hObserved = plot(hAxis,[0 doseBinsObsV], [1 cumVols2V/cumVolsV(end)],'LineWidth',2,'color',colorV,'parent',hAxis);
        xObsVals = [0, doseBinsObsV];
        yObsVals = [1, cumVols2V/cumVolsV(end)];
        [xObsVals, aInd] = unique(xObsVals);
        yObsVals = yObsVals(aInd);
        ud.currentDVHS.xObsVals = xObsVals;
        ud.currentDVHS.yObsVals = yObsVals;
        ud.currentDVHS.hObserved = hObserved;
        DVHs.handles = [DVHs.handles hObserved];

        try, delete(ud.currentDVHS.hHighlight), end
        highlightColorV = setCERRLabelColor(DVHs.structNum);
        hHighlight = plot(hAxis,[0 doseBinsObsV], [1 cumVols2V/cumVolsV(end)],'LineWidth',1,'color',highlightColorV,'LineStyle',':','parent',hAxis);
        ud.currentDVHS.hHighlight = hHighlight;

        ud.DVH(DVHnum) = DVHs;

        xlabel(hAxis,'Dose')
        ylabel(hAxis,'Fractional volume')
        set(hAxis,'visible','on')
        grid(hAxis,'on')
        axis(hAxis,'tight')
        set([ud.currentDVHS.hLB ud.currentDVHS.hMean ud.currentDVHS.hUB ud.currentDVHS.hObserved ud.currentDVHS.hPatch],'hittest','off')


        set(hFig,'userdata',ud)

        %Display Observed and Lower & Upper bounds

        %Observed
        meanObsD = sum(doseBinsObsV.*volsHistObsV)/sum(volsHistObsV);
        ind      = max(find([volsHistObsV~=0]));
        maxObsD  = doseBinsObsV(ind);
        ind      = min(find([volsHistObsV~=0]));
        minObsD  = doseBinsObsV(ind);
        hmeanObsD = findobj(ud.handle.DVHStatH,'tag','meanDoseObserTxt');
        set(hmeanObsD,'string',num2str(meanObsD))
        hmaxObsD  = findobj(ud.handle.DVHStatH,'tag','maxDoseObserTxt');
        set(hmaxObsD,'string',num2str(maxObsD))
        hminObsD  = findobj(ud.handle.DVHStatH,'tag','minDoseObserTxt');
        set(hminObsD,'string',num2str(minObsD))
        
        %Mean
        [doseBinsMeanV, volsHistMeanV] = doseHist(max(0,meanDoseV), volsV, binWidth);
        meanMeanD  = sum(doseBinsMeanV.*volsHistMeanV)/sum(volsHistMeanV);        
        ind      = max(find([volsHistMeanV~=0]));
        maxMeanD   = doseBinsMeanV(ind);
        ind      = min(find([volsHistMeanV~=0]));
        minMeanD   = doseBinsMeanV(ind);
        hmeanMeanD = findobj(ud.handle.DVHStatH,'tag','meanDoseMeanTxt');
        set(hmeanMeanD,'string',num2str(meanMeanD))
        hmaxMeanD  = findobj(ud.handle.DVHStatH,'tag','maxDoseMeanTxt');
        set(hmaxMeanD,'string',num2str(maxMeanD))
        hminMeanD  = findobj(ud.handle.DVHStatH,'tag','minDoseMeanTxt');
        set(hminMeanD,'string',num2str(minMeanD))
        
        %Lower Bound
        [doseBinsMinV, volsHistMinV] = doseHist(max(0,meanDoseV - sigma*stdDoseV), volsV, binWidth);
        meanLBD  = sum(doseBinsMinV.*volsHistMinV)/sum(volsHistMinV);        
        ind      = max(find([volsHistMinV~=0]));
        maxLBD   = doseBinsMinV(ind);
        ind      = min(find([volsHistMinV~=0]));
        minLBD   = doseBinsMinV(ind);
        hmeanLBD = findobj(ud.handle.DVHStatH,'tag','meanDoseLBTxt');
        set(hmeanLBD,'string',num2str(meanLBD))
        hmaxLBD  = findobj(ud.handle.DVHStatH,'tag','maxDoseLBTxt');
        set(hmaxLBD,'string',num2str(maxLBD))
        hminLBD  = findobj(ud.handle.DVHStatH,'tag','minDoseLBTxt');
        set(hminLBD,'string',num2str(minLBD))
        
        %Upper Bound
        [doseBinsMaxV, volsHistMaxV] = doseHist(max(0,meanDoseV + sigma*stdDoseV), volsV, binWidth);
        meanUBD = sum(doseBinsMaxV.*volsHistMaxV)/sum(volsHistMaxV);        
        ind      = max(find([volsHistMaxV~=0]));
        maxUBD  = doseBinsMaxV(ind);
        ind      = min(find([volsHistMaxV~=0]));
        minUBD  = doseBinsMaxV(ind);
        hmeanUBD = findobj(ud.handle.DVHStatH,'tag','meanDoseUBTxt');
        set(hmeanUBD,'string',num2str(meanUBD))
        hmaxUBD  = findobj(ud.handle.DVHStatH,'tag','maxDoseUBTxt');
        set(hmaxUBD,'string',num2str(maxUBD))
        hminUBD  = findobj(ud.handle.DVHStatH,'tag','minDoseUBTxt');
        set(hminUBD,'string',num2str(minUBD))
        
        %Grab the handle for Show Plot checkbox and set it to checked.
        hShowPlot = findobj(ud.handle.DVHStatH,'tag','showPlot');
        set(hShowPlot,'value',1)
        
        %Populate Dose above volume
        hvolEdit = findobj(ud.handle.DVHStatH,'tag','volAbovDoseEdit');
        dose = str2double(get(hvolEdit, 'string'));
        ud = get(hFig, 'userdata');
        hAxis = findobj('tag','dvhAxis');        
        xLim = get(hAxis, 'xLim');              
        if dose < xLim(1)
            dose = xLim(1);    
        elseif dose > xLim(2)
            dose = xLim(2);
        end            
       
        obserVol = interp1(ud.currentDVHS.xObsVals, ud.currentDVHS.yObsVals, dose);
        if isnan(obserVol)
            obserVol = 0;
        end
        meanVol = interp1(ud.currentDVHS.xMeanVals, ud.currentDVHS.yMeanVals, dose);
        if isnan(meanVol)
            meanVol = 0;
        end
        LBVol = interp1(ud.currentDVHS.xLBVals, ud.currentDVHS.yLBVals, dose);
        if isnan(LBVol)
            LBVol = 0;
        end
        UBVol = interp1(ud.currentDVHS.xUBVals, ud.currentDVHS.yUBVals, dose);
        if isnan(UBVol)
            UBVol = 0;
        end
        if LBVol > UBVol
            tmp   = LBVol;
            LBVol = UBVol;
            UBVol = tmp;
        end
        
        hvolObser = findobj(ud.handle.DVHStatH,'tag','volAbovDoseObserTxt');
        set(hvolObser,'string',num2str(obserVol))
        hvolLBD  = findobj(ud.handle.DVHStatH,'tag','volAbovDoseLBTxt');
        set(hvolLBD,'string',num2str(LBVol))
        hvolUBD  = findobj(ud.handle.DVHStatH,'tag','volAbovDoseUBTxt');
        set(hvolUBD,'string',num2str(UBVol))        
        hvolMeanD  = findobj(ud.handle.DVHStatH,'tag','volAbovDoseMeanTxt');
        set(hvolMeanD,'string',num2str(meanVol))       
        
    
    case 'TOGGLE_VISIBILITY'
        hFig = findobj('tag','robustDVHFig');
        
        %Get Robust DVH structure to plot
        ud = get(hFig,'userdata');
        
        hDVH_num = findobj(ud.handle.DVHStatH,'tag','dvhSelect');
        DVHnum = get(hDVH_num,'value') - 1;

        value = get(gcbo,'value');
        DVHs = ud.DVH(DVHnum);
        if value
            set(DVHs.handles,'visible','on')
        else
            set(DVHs.handles,'visible','off')
            set(ud.currentDVHS.hHighlight,'visible','off')
        end
        
        
    case 'PLOTMOTION'
    %A DVH is selected, the plot has been clicked and motion is occuring. Update guide line/fields.            
        hFig = findobj('tag','robustDVHFig');
        hAxis = findobj('tag','dvhAxis');
        ud = get(hFig, 'userdata');
        cP = get(hAxis, 'currentpoint');
        dose = cP(1,1); 
        xLim = get(hAxis, 'xLim');              
        if dose < xLim(1)
            dose = xLim(1);    
        elseif dose > xLim(2)
            dose = xLim(2);
        end            
        observVol = interp1(ud.currentDVHS.xObsVals, ud.currentDVHS.yObsVals, dose);
        if isnan(observVol)
            observVol = 0;
        end
        meanVol = interp1(ud.currentDVHS.xMeanVals, ud.currentDVHS.yMeanVals, dose);
        if isnan(meanVol)
            meanVol = 0;
        end        
        lbVol = interp1(ud.currentDVHS.xLBVals, ud.currentDVHS.yLBVals, dose);
        if isnan(lbVol)
            lbVol = 0;
        end        
        ubVol = interp1(ud.currentDVHS.xUBVals, ud.currentDVHS.yUBVals, dose);
        if isnan(ubVol)
            ubVol = 0;
        end

        hvolObser = findobj(ud.handle.DVHStatH,'tag','volAbovDoseObserTxt');
        set(hvolObser,'string',num2str(observVol))
        hvolLBD  = findobj(ud.handle.DVHStatH,'tag','volAbovDoseLBTxt');
        set(hvolLBD,'string',num2str(lbVol))
        hvolUBD  = findobj(ud.handle.DVHStatH,'tag','volAbovDoseUBTxt');
        set(hvolUBD,'string',num2str(ubVol))
        hDose = findobj(ud.handle.DVHStatH,'tag','volAbovDoseEdit');
        set(hDose,'string',num2str(dose))        
        hvolMeanD  = findobj(ud.handle.DVHStatH,'tag','volAbovDoseMeanTxt');
        set(hvolMeanD,'string',num2str(meanVol))       
        hMotionLine = findobj(ud.handle.DVHStatH,'tag','motionLine');        
        set(hMotionLine, 'xdata', [dose dose], 'visible', 'on');

        
        
    case 'CLICKINPLOT'
    %A DVH is selected and the plot has been clicked, update guide line/fields.    
        hFig = findobj('tag','robustDVHFig');
        hAxis = findobj('tag','dvhAxis');
        ud = get(hFig, 'userdata');
        set(hFig, 'WindowButtonUpFcn', 'DVHRobustnessGUI(''UNCLICKINPLOT'')');
        set(hFig, 'WindowButtonMotionFcn', 'DVHRobustnessGUI(''PLOTMOTION'')');
        cP = get(hAxis, 'currentpoint');
        %Interpolate Vol, display.
        dose = cP(1,1); 
        xLim = get(hAxis, 'xLim');              
        if dose < xLim(1)
            dose = xLim(1);    
        elseif dose > xLim(2)
            dose = xLim(2);
        end            
        observVol = interp1(ud.currentDVHS.xObsVals, ud.currentDVHS.yObsVals, dose);
        if isnan(observVol)
            observVol = 0;
        end
        meanVol = interp1(ud.currentDVHS.xMeanVals, ud.currentDVHS.yMeanVals, dose);
        if isnan(meanVol)
            meanVol = 0;
        end        
        lbVol = interp1(ud.currentDVHS.xLBVals, ud.currentDVHS.yLBVals, dose);
        if isnan(lbVol)
            lbVol = 0;
        end        
        ubVol = interp1(ud.currentDVHS.xUBVals, ud.currentDVHS.yUBVals, dose);
        if isnan(ubVol)
            ubVol = 0;
        end

        hvolObser = findobj(ud.handle.DVHStatH,'tag','volAbovDoseObserTxt');
        set(hvolObser,'string',num2str(observVol))
        hvolLBD  = findobj(ud.handle.DVHStatH,'tag','volAbovDoseLBTxt');
        set(hvolLBD,'string',num2str(lbVol))
        hvolUBD  = findobj(ud.handle.DVHStatH,'tag','volAbovDoseUBTxt');
        set(hvolUBD,'string',num2str(ubVol))
        hDose = findobj(ud.handle.DVHStatH,'tag','volAbovDoseEdit');
        set(hDose,'string',num2str(dose))        
        hvolMeanD  = findobj(ud.handle.DVHStatH,'tag','volAbovDoseMeanTxt');
        set(hvolMeanD,'string',num2str(meanVol))               
        hMotionLine = findobj(ud.handle.DVHStatH,'tag','motionLine');        
        set(hMotionLine, 'xdata', [dose dose], 'visible', 'on');

        
    case 'UNCLICKINPLOT'
        hFig = findobj('tag','robustDVHFig');
        ud = get(hFig, 'userdata');
        set(hFig, 'WindowButtonMotionFcn', '');        
        set(hFig, 'WindowButtonUpFcn', '');        
        set(hFig, 'userdata', ud);
        
    case 'DOSEVAL'
    %A value has been entered into the doseVal field.
        hFig = get(gcbo, 'parent');
        dose = str2double(get(gcbo, 'string'));
        ud = get(hFig, 'userdata');
        hAxis = findobj('tag','dvhAxis');        
        xLim = get(hAxis, 'xLim');              
        if dose < xLim(1)
            dose = xLim(1);    
        elseif dose > xLim(2)
            dose = xLim(2);
        end            
       
        obserVol = interp1(ud.currentDVHS.xObsVals, ud.currentDVHS.yObsVals, dose);
        if isnan(obserVol)
            obserVol = 0;
        end
        LBVol = interp1(ud.currentDVHS.xLBVals, ud.currentDVHS.yLBVals, dose);
        if isnan(LBVol)
            LBVol = 0;
        end
        UBVol = interp1(ud.currentDVHS.xUBVals, ud.currentDVHS.yUBVals, dose);
        if isnan(UBVol)
            UBVol = 0;
        end
        
        hvolObser = findobj(ud.handle.DVHStatH,'tag','volAbovDoseObserTxt');
        set(hvolObser,'string',num2str(obserVol))
        hvolLBD  = findobj(ud.handle.DVHStatH,'tag','volAbovDoseLBTxt');
        set(hvolLBD,'string',num2str(LBVol))
        hvolUBD  = findobj(ud.handle.DVHStatH,'tag','volAbovDoseUBTxt');
        set(hvolUBD,'string',num2str(UBVol))
        hMotionLine = findobj(ud.handle.DVHStatH,'tag','motionLine');        
        set(hMotionLine, 'xdata', [dose dose], 'visible', 'on');
        
        
    case 'LEGENDCALL'
        
        %executes when "Show Legend" is toggled on or off
        hFig = findobj('tag','robustDVHFig');
        ud = get(hFig,'userdata');
        
        value = get(gcbo,'value');
        hLegend = findobj('tag','DVH_Legend');
        close(hLegend)
        if value == 0
            return;
        end
        hFig = get(gcbo, 'parent');        
        ud = get(hFig, 'userdata');
        hLegend = figure('tag','DVH_Legend','name','DVH Legend','numberTitle','off','menubar','Figure','color','w');
        position = get(hLegend,'position');
        figColor = get(hLegend,'color');
        axisLegend = axes('units', 'normalized', 'Position', [0 0 1 1], 'color', figColor, 'ytick',[],'xtick',[], 'box', 'off', 'parent', hLegend,'nextPlot','add','units','normalized','visible','off');
        numLines = length(ud.DVH);
        dy = 0.8/numLines;
        position(3) = 400;
        position(4) = (numLines+1)*30;
        set(hLegend,'position',position)

        for i = 1:numLines
            Color = planC{indexS.structures}(ud.DVH(i).structNum).structureColor;
            line([0.05 0.15],[0.8-(i-1)*dy 0.8-(i-1)*dy],'LineStyle','-','LineWidth',2,'Color',Color,'parent',axisLegend)
            txt = ['Struct = ',planC{indexS.structures}(ud.DVH(i).structNum).structureName,', Dose Fract = ',planC{indexS.dose}(ud.DVH(i).doseNum).fractionGroupID];
            text(0.18,0.8-(i-1)*dy,txt)
        end
        axis(axisLegend,[0 1 0 1])

    case 'CLOSEREQUEST'

        closereq


end

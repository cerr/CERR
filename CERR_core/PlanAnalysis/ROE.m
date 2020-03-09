function ROE(command,varargin)
%  GUI for outcomes modeling (TCP, NTCP)
%  This tool uses JSONlab toolbox v1.2, an open-source JSON/UBJSON encoder and decoder
%  for MATLAB and Octave.
%  See : http://www.mathworks.com/matlabcentral/fileexchange/33381-jsonlab--a-toolbox-to-encode-decode-json-files
% =======================================================================================================================
% APA, 05/10/2016
% AI , 05/24/2016  Added dose scaling
% AI , 07/28/2016  Added ability to modify model parameters
% AI , 09/13/2016  Added TCP axis
% AI , 02/17/17    Added popup to edit structure/plan inputs
% AI , 02/20/17    Added model selection by protocol
% AI , 04/24/17    Added plot focus-switching, changed name to ROE
% AI , 05/23/17    Default plan selection
% AI , 11/13/17    Modified to handle multiple structures
% AI , 11/24/17    Modified to display clinical criteria/limits
% AI , 02/05/18    Added option to change no. fractions
% AI , 03/27/18    Added option to switch between TCP/BED axes
% AI,  06/14/18    Added TCP/BED readout, fixed bug with tooltip frxSiz display
% AI,  09/04/18    Modified plot to show NTCP vs. TCP/BED
% AI,  10/24/18    Added 4 plot modes : NTCP vs. BED, NTCP vs. TCP, NTCP/TCP vs frx size, NTCP/TCP vs nfrx
% -------------------------------------------------------------------------
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
% =========================================================================================================================

% Globals
global planC stateS

%Default command
if nargin==0
    command = 'INIT';
end

%Check for loaded plan
if isempty(planC)
    if  ~strcmpi(command,'closerequest')
        msgbox('Please load valid plan to begin','Error!');
        return
    end
end

indexS = planC{end};
binWidth = .05;


% Get GUI fig handle
hFig = findobj('Tag','ROEFig');

switch upper(command)
    
    case 'INIT'
        %Initialize main GUI figure
        
        % Define GUI size, margins, position, color & title
        leftMarginWidth = 360;
        topMarginHeight = 60;
        stateS.leftMarginWidth = leftMarginWidth;
        stateS.topMarginHeight = topMarginHeight;
        screenSizeV = get( 0, 'Screensize' );
        GUIWidth = 1200;
        GUIHeight = 750;
        shift = 10;
        position = [(screenSizeV(3)-GUIWidth)/2,(screenSizeV(4)-GUIHeight)/2,GUIWidth,GUIHeight];
        str1 = 'ROE';
        defaultColor = [0.8 0.9 0.9];
        figColor = [.6 .75 .75];
        
        if isempty(findobj('tag','ROEFig'))
            
            % initialize main GUI figure
            hFig = figure('tag','ROEFig','name',str1,...
                'numbertitle','off','position',position,...
                'CloseRequestFcn', 'ROE(''closeRequest'')',...
                'menubar','none','resize','off','color',figColor);
        else
            figure(findobj('tag','ROEFig'))
            return
        end
        
        
        %Create title handles
        posTop = GUIHeight-topMarginHeight;
        titleH(1) = uicontrol(hFig,'tag','titleFrame','units','pixels',...
            'Position',[shift posTop-shift/2 GUIWidth-2*shift 0.08*GUIHeight ],'Style',...
            'frame','backgroundColor',defaultColor);
        titleH(2) = uicontrol(hFig,'tag','title','units','pixels',...
            'Position',[.3*GUIHeight+1 posTop+1 .6*GUIWidth 3*shift ],...
            'String','ROE: Radiotherapy Outcomes Estimator','Style','text', 'fontSize',12,...
            'FontWeight','Bold','HorizontalAlignment','center',...
            'backgroundColor',defaultColor);
        
        ud.handle.title = titleH;
        set(hFig,'userdata',ud);
        ROE('refresh',hFig);
        figure(hFig);
        
        
        
    case 'REFRESH'
        
        if isempty(hFig)
            return
        end
        
        % Get GUI size, margins
        leftMarginWidth = stateS.leftMarginWidth;
        topMarginHeight = stateS.topMarginHeight;
        pos = get(hFig,'Position');
        GUIWidth = pos(3);
        GUIHeight = pos(4);
        shift = 10;
        defaultColor = [0.8 0.9 0.9];
        posTop = GUIHeight-topMarginHeight;
        
        %% Push button for protocol selection
        inputH(1) = uicontrol(hFig,'tag','titleFrame','units','pixels',...
            'Position',[shift shift leftMarginWidth+.12*GUIWidth GUIHeight-topMarginHeight-2*shift ],...
            'Style','frame','backgroundColor',defaultColor);
        inputH(2) = uicontrol(hFig,'tag','modelTitle','units','pixels',...
            'Position',[2*shift posTop-.16*GUIHeight .16*GUIWidth 2*shift], 'String','','Style','text',...
            'fontSize',9, 'fontWeight', 'Bold', 'BackgroundColor',defaultColor,...
            'HorizontalAlignment','left');
        inputH(3) = uicontrol(hFig,'tag','modelFileSelect','units','pixels',...
            'Position',[2*shift posTop-.1*GUIHeight .16*GUIWidth 3*shift], 'String',...
            'Select protocol','Style','push', 'fontSize',10,...
            'FontWeight','normal','BackgroundColor',defaultColor,...
            'HorizontalAlignment','right','callback',...
            'ROE(''LOAD_MODELS'')');
        
        %% Pop-up menus to select structures & dose plans
        tablePosV = [.22*GUIWidth-2.5*shift posTop-.1*GUIHeight .22*GUIWidth 2.4*shift];
        colWidth = tablePosV(3)/2-1;
        inputH(4) = uitable(hFig,'Tag','strSel','Position',tablePosV-[0 2.5*shift 0 0],'Enable','Off',...
            'cellEditCallback',@editParams,'ColumnName',[],'RowName',[],'Visible','Off',...
            'backgroundColor',defaultColor,'columnEditable',[true,true],'Data',...
            {'Select structure','List of structures'},'ColumnWidth',{colWidth,colWidth},'FontSize',10);
        inputH(5) = uitable(hFig,'Tag','doseSel','Position',tablePosV,'Enable','Off',...
            'cellEditCallback',@editParams,'ColumnName',[],'RowName',[],'Visible','Off',...
            'backgroundColor',defaultColor,'columnEditable',[true,true],'Data',...
            {'Select dose plan','List of plans'},'ColumnWidth',{colWidth,colWidth},'FontSize',10);
        
        %% Tables to display & edit model parameters
        inputH(6) = uicontrol(hFig,'units','pixels','Visible','Off','fontSize',10,...
            'Position',tablePosV + [0 -.1*GUIHeight 0 0 ],'String','Model parameters','Style','text',...
            'FontWeight','Bold','HorizontalAlignment','Left','backgroundColor',defaultColor); %Title: Model parameters
        inputH(7) = uicontrol(hFig,'units','pixels','Visible','Off','String','',...
            'Position',tablePosV + [0 -.15*GUIHeight 0 0 ],'FontSize',10,'Style','text',...
            'FontWeight','Bold','HorizontalAlignment','Left','backgroundColor',defaultColor,...
            'foregroundColor',[.6 0 0]); %Model name display
        inputH(8) = uitable(hFig,'Tag','fieldEdit','Position',tablePosV + [0 -.75*GUIHeight 0 8*shift],'Enable','Off',...
            'cellEditCallback',@editParams,'ColumnName',{'Fields','Values'},'FontSize',10,...
            'RowName',[],'Visible','Off','backgroundColor',defaultColor,...
            'ColumnWidth',{round(tablePosV(3)/2),round(tablePosV(3)/2)},...
            'columnEditable',[false,true],'backgroundcolor',[1 1 1]); %Parameter tables
        
        %% Push-buttons to save, plot, display style
        inputH(9) = uicontrol(hFig,'units','pixels','Tag','saveJson','Position',[.36*GUIWidth 1.5*shift .06*GUIWidth 3*shift],'backgroundColor',defaultColor,...
            'String','Save','Style','Push', 'fontSize',10,'FontWeight','normal','Enable','Off','Callback','ROE(''SAVE_MODELS'' )'); %Save
        inputH(10) = uicontrol(hFig,'units','pixels','Tag','plotButton','Position',[.29*GUIWidth 1.5*shift .06*GUIWidth 3*shift],'backgroundColor',defaultColor,...
            'String','Plot','Style','Push', 'fontSize',10,'FontWeight','normal','Enable','Off','Callback','ROE(''PLOT_MODELS'' )'); %plot
        inputH(11) = uicontrol(hFig,'units','pixels','Tag','switchPlot','Position',[.18*GUIWidth .1*shift .1*GUIWidth 4*shift],'backgroundColor',[1 1 1],...
            'String',{'--Display mode--','NTCP v.BED','NTCP v.TCP','Scale fraction size', 'Scale no. fractions' },'Style','popup', 'fontSize',10,'FontWeight','normal','Enable','On','Callback',@setPlotMode);
        
        %% Plot axes
        
        %Draw frame
        plotH(1) = axes('parent',hFig,'units','pixels','Position',...
            [leftMarginWidth+.14*GUIWidth shift GUIWidth-leftMarginWidth-.15*GUIWidth...
            GUIHeight-topMarginHeight-2*shift ],'color',defaultColor,'ytick',[],...
            'xtick',[],'box','on');
        
        %Axes
        %NTCP vs TCP/BED
        plotH(2) = axes('parent',hFig,'tag','modelsAxis','tickdir', 'out',...
            'nextplot','add','units','pixels','Position',...
            [leftMarginWidth+.19*GUIWidth .16*GUIHeight .73*GUIWidth-leftMarginWidth,...
            GUIHeight-topMarginHeight-0.2*GUIHeight],'color',[1 1 1],...
            'XAxisLocation','bottom','YAxisLocation','left','xlim',[50 51],'ylim',[0 1],...
            'fontSize',9,'fontWeight','bold','box','on','visible','off');
        
        %NTCP vs. scaled frx size
        plotH(3) = axes('parent',hFig,'tag','modelsAxis','tickdir', 'out',...
            'nextplot','add','units','pixels','Position',get(plotH(2),'Position'),'color',[1 1 1],...
            'XAxisLocation','bottom','YAxisLocation','left','xlim',[.5 1.5],'ylim',[0 1],...
            'fontSize',9,'fontWeight','bold','box','on','visible','off');
        %TCP/BED vs. scaled frx size
        plotH(4) = axes('parent',hFig,'tag','modelsAxis2','tickdir', 'out',...
            'nextplot','add','units','pixels','Position',get(plotH(2),'Position'),...
            'color','none','XAxisLocation','bottom','YAxisLocation','right',...
            'xlim',[.5 1.5],'ylim',[0 1],'xtick',[],'fontSize',9,'fontWeight',...
            'bold','box','on','visible','off');
        
        
        %NTCP vs. scaled nfrx
        plotH(5) = axes('parent',hFig,'tag','modelsAxis','tickdir', 'out',...
            'nextplot','add','units','pixels','Position',get(plotH(2),'Position'),...
            'color',[1 1 1],'XAxisLocation','bottom','YAxisLocation','left','ylim',[0 1],...
            'fontSize',9,'fontWeight','bold','box','on','visible','off');
        %TCP/BED vs. scaled nfrx
        plotH(6) = axes('parent',hFig,'tag','modelsAxis2','tickdir', 'out',...
            'nextplot','add','units','pixels','Position',get(plotH(2),'Position'),...
            'color','none','XAxisLocation','bottom','YAxisLocation','right',...
            'ylim',[0 1],'xtick',[],'fontSize',9,'fontWeight',...
            'bold','box','on','visible','off');
        
        
        %Sliders
        %scale frx size
        plotH(7) = uicontrol('parent',hFig,'units','pixels','Position',...
            [leftMarginWidth+.18*GUIWidth 5*shift .75*GUIWidth-leftMarginWidth 1.8*shift],...
            'Style','Slider','Visible','Off','Tag','Scale','Min',0.5,'Max',1.5,'Value',1,...
            'SliderStep',[1/(99-1),1/(99-1)]);
        addlistener(plotH(7),'ContinuousValueChange',@scaleDose);
        %scale nfrx
        plotH(8) = uicontrol('parent',hFig,'units','pixels','Position',...
            [leftMarginWidth+.18*GUIWidth 5*shift .75*GUIWidth-leftMarginWidth 1.8*shift],...
            'Style','Slider','Visible','Off','Tag','Scale','Min',-15,'Max',15,'Value',0,...
            'SliderStep',[1/30 1/30]);
        addlistener(plotH(8),'ContinuousValueChange',@scaleDose);
        
        
        %Push-button for constraints panel
        plotH(9) = uicontrol('parent',hFig,'units','pixels','Position',...
            [GUIWidth-17*shift 1.5*shift 15*shift 3*shift],...
            'Style','push','Enable','On','String','View constraints',...
            'backgroundColor',[192 205 230]./255,'fontSize',10,...
            'Callback',{@critPanel,'INIT'});
        
        %Input scale
        plotH(10) = uicontrol('parent',hFig,'units','pixels','Position',...
            [GUIWidth-6*shift 5*shift 3*shift 2*shift],...
            'Style','edit','Enable','Off','fontSize',10,'Callback',@enterScale);
        plotH(11) = uicontrol('parent',hFig,'units','pixels','Position',...
            [GUIWidth-8*shift 7*shift 6*shift 3*shift],'backgroundColor',defaultColor,...
            'Style','Text','Visible','Off','fontSize',8,'Callback',@enterScale);
        
        %Turn off datacursor mode
        cursorMode = datacursormode(hFig);
        cursorMode.removeAllDataCursors;
        set(cursorMode, 'Enable','Off');
        
        %% Store handles
        ud.handle.inputH = inputH;
        ud.handle.modelsAxis = plotH;
        set(hFig,'userdata',ud);
        
        
    case 'LOAD_MODELS'
        ROE('REFRESH');
        ud = get(hFig,'userdata');
        
        %Get paths to JSON files
        optS = opts4Exe('CERRoptions.json'); 
        %NOTE: Define path to .json files for protocols, models & clinical criteria in CERROptions.json
        %optS.ROEProtocolPath = 'your/path/to/protocols';
        %optS.ROEModelPath = 'your/path/to/models';
        %optS.ROECriteriaPath = 'your/path/to/criteria';
        
        protocolPath = eval(optS.ROEProtocolPath);
        modelPath = eval(optS.ROEModelPath);
        criteriaPath = eval(optS.ROECriteriaPath);

        % List available protocols for user selection
        [protocolListC,protocolIdx,ok] = listFiles(protocolPath,'Multiple');
        if ~ok
            return
        end
        
        % Load models associated with selected protocol(s)
        root = uitreenode('v0', 'Protocols', 'Protocols', [], false);      %Create root node (for tree display)
        for p = 1:numel(protocolIdx)                                       %Cycle through selected protocols
            [~,protocol] = fileparts(protocolListC{protocolIdx(p)});
            protocolInfoS = loadjson(fullfile(protocolPath,protocolListC{protocolIdx(p)}),'ShowProgress',1);
            %Load .json for protocol
            modelListC = fields(protocolInfoS.models);                     %Get list of relevant models
            numModels = numel(modelListC);
            protocolS(p).modelFiles = [];
            uProt = uitreenode('v0',protocol,protocolInfoS.name,[],false); %Create nodes for protocols
            for m = 1:numModels
                protocolS(p).protocol = protocolInfoS.name;
                modelFPath = fullfile(modelPath,protocolInfoS.models.(modelListC{m}).modelFile);
                %Get path to .json for model
                protocolS(p).model{m} = loadjson(modelFPath,'ShowProgress',1);
                %Load model parameters from .json file
                protocolS(p).modelFiles = [protocolS(p).modelFiles,modelFPath];
                modelName = protocolS(p).model{m}.name;
                uProt.add(uitreenode('v0', modelName,modelName, [], true));%Create nodes for models
            end
            protocolS(p).numFractions = protocolInfoS.numFractions;
            protocolS(p).totalDose = protocolInfoS.totalDose;
            root.add(uProt);                                               %Add protocol to tree
            
            %Load associated clinical criteria/guidelines
            if isfield(protocolInfoS,'criteriaFile')
                critFile = fullfile(criteriaPath,protocolInfoS.criteriaFile);
                critS = loadjson(critFile,'ShowProgress',0);
                protocolS(p).constraints = critS;
            end
        end
        
        %Create tree to list models by protocol
        shift = 10;
        pos = get(hFig,'Position');
        GUIWidth = pos(3);
        GUIHeight = pos(4);
        mtree = uitree('v0', 'Root', root, 'SelectionChangeFcn',@getParams);
        set(mtree,'Position',[2*shift 5*shift .16*GUIWidth .68*GUIHeight],...
            'Visible',false);
        drawnow;
        set(ud.handle.inputH(2),'string','Protocols & Models'); %Tree title
        
        %Store protocol & model parameters from JSON files to GUI userdata
        ud.Protocols = protocolS;
        ud.modelTree = mtree;
        
        set(hFig,'userdata',ud);
        ROE('LIST_MODELS');
        
        
    case 'PLOT_MODELS'
        
        %% Get plot mode
        ud = get(hFig,'userdata');
        if ~isfield(ud,'plotMode') || isempty(ud.plotMode) || isequal(ud.plotMode,0)
            msgbox('Please select display mode','Plot models');
            return
        else
            plotMode = ud.plotMode;
        end
        
        %% Clear previous plots
        ROE('CLEAR_PLOT',hFig);
        
        ud = get(hFig,'userdata');
        if ~isfield(ud,'planNum') || isempty(ud.planNum) || ud.planNum==0
            msgbox('Please select valid dose plan','Selection required');
            return
        end
        indexS = planC{end};
        
        %% Initialize plot handles
        if ~isfield(ud,'NTCPCurve')
            ud.NTCPCurve = [];
        end
        if ~isfield(ud,'TCPCurve')
            ud.TCPCurve = [];
        end
        if ~isfield(ud,'BEDCurve')
            ud.BEDCurve = [];
        end
        if ~isfield(ud,'cMarker')
            ud.cMarker = [];
        end
        if ~isfield(ud,'gMarker')
            ud.gMarker = [];
        end
        
        %% Define color order, foreground protocol
        colorOrderM = [0 229 238;123 104 238;255 131 250;0 238 118;218 165 32;...
            196	196	196;0 139 0;28 134 238;238 223 204]/255;
        if ~isfield(ud,'foreground') || isempty(ud.foreground)
            ud.foreground = 1;
        end
        
        %% Define loop variables
        protocolS = ud.Protocols;
        cScaleV = [];
        cValV = [];
        gScaleV = [];
        gValV = [];
        ntcp = 0;
        tcp = 0;
        bed = 0;
        jTot = 0;
        cCount = 0;
        gCount = 0;
        
        %% Mode-specific computations
        switch plotMode
            
            case {1,2} %NTCP vs BED/TCP
                
                maxDeltaFrx = round(max([protocolS.numFractions])/2);
                nfrxScaleV = linspace(-maxDeltaFrx,maxDeltaFrx,99);
                
                hNTCPAxis = ud.handle.modelsAxis(2);
                hNTCPAxis.Visible = 'On';
                grid(hNTCPAxis,'On');
                
                tcpM = nan(numel(protocolS),length(nfrxScaleV));
                %Compute BED/TCP
                for p = 1:numel(protocolS)
                    
                    modelC = protocolS(p).model;
                    
                    %Ensure reqd structures are selected 
                    strSelC = cellfun(@(x)x.strNum , modelC,'un',0);
                    noSelV = find([strSelC{:}]==0);
                    
                    if any(noSelV)
                       modList = cellfun(@(x)x.name , modelC,'un',0);
                       modList = strjoin(modList(noSelV),',');  
                       msgbox(['Please select structures required for models ' modList],'Selection required');
                       return
                    end
                    
                    modTypeC = cellfun(@(x)(x.type),modelC,'un',0);
                    xIndx = find(strcmp(modTypeC,'BED') | strcmp(modTypeC,'TCP')); %Identify TCP/BED models
                    
                    %Scale planned dose array
                    plnNum = ud.planNum;
                    numFrxProtocol = protocolS(p).numFractions;
                    protDose = protocolS(p).totalDose;
                    dpfProtocol = protDose/numFrxProtocol;
                    prescribedDose = planC{indexS.dose}(plnNum).prescribedDose;
                    dA = getDoseArray(plnNum,planC);
                    dAscale = protDose/prescribedDose;
                    dAscaled = dA * dAscale;
                    planC{indexS.dose}(plnNum).doseArray = dAscaled;
                    
                    %Compute BED/TCP
                    
                    %Create parameter dictionary
                    paramS = [modelC{xIndx}.parameters];
                    structNumV = modelC{xIndx}.strNum;
                    %-No. of fractions
                    paramS.numFractions.val = numFrxProtocol;
                    %-fraction size
                    paramS.frxSize.val = dpfProtocol;
                    %-alpha/beta
                    abRatio = modelC{xIndx}.abRatio;
                    paramS.abRatio.val = abRatio;
                    
                    %Get DVH
                    if isfield(modelC{xIndx},'dv')
                        storedDVc = modelC{xIndx}.dv;
                        doseBinsC = storedDVc{1} ;
                        volHistC = storedDVc{2};
                    else
                        doseBinsC = cell(1,numel(structNumV));
                        volHistC = cell(1,numel(structNumV));
                        strC = modelC{xIndx}.parameters.structures;
                        strFlag = 0;
                        if isstruct(strC)
                            strFlag = 1;
                            strC = fieldnames(strC);
                        end
                        for nStr = 1:numel(structNumV)
                            if strFlag
                                strS = modelC{xIndx}.parameters.structures.(strC{nStr});
                            else
                                strS = [];
                            end
                            %---------------temp : update reqd ------------
                            if isfield(strS,'dDIL')
                                doseBinsC{nStr} = strS.dDIL.val;
                                volHistC{nStr} = [];
                            else
                                [dosesV,volsV] = getDVH(structNumV(nStr),plnNum,planC);
                                [doseBinsC{nStr},volHistC{nStr}] = doseHist(dosesV,volsV,binWidth);
                            end
                            %----------------end temp --------------
                        end
                        modelC{xIndx}.dv = {doseBinsC,volHistC};
                    end
                    
                    xScaleV = nfrxScaleV(nfrxScaleV+numFrxProtocol>=1);
                    
                    for n = 1 : numel(xScaleV)
                        
                        %Scale dose bins
                        newNumFrx = xScaleV(n)+numFrxProtocol;
                        scale = newNumFrx/numFrxProtocol;
                        scaledDoseBinsC = cellfun(@(x) x*scale,doseBinsC,'un',0);
                        
                        
                        %Apply fractionation correction as required
                        correctedScaledDoseC = frxCorrect(modelC{xIndx},structNumV,newNumFrx,scaledDoseBinsC);
                        
                        %Update nFrx parameter
                        paramS.numFractions.val = newNumFrx;
                        
                        %Compute TCP/BED
                        if numel(structNumV)==1
                            tcpM(p,n) = feval(modelC{xIndx}.function,paramS,correctedScaledDoseC{1},volHistC{1});
                        else
                            tcpM(p,n) = feval(modelC{xIndx}.function,paramS,correctedScaledDoseC,volHistC);
                        end
                        
                        %--------------TEMP (Addded to display dose metrics & TCP/NTCP at scale = 1 for testing)-----------%
                        if n==numel(xScaleV)
                            %Get corrected dose at scale == 1
                            paramS.frxSize.val = dpfProtocol;
                            testDoseC = frxCorrect(modelC{xIndx},structNumV,numFrxProtocol,doseBinsC);
                            %Display mean dose, EUD, GTD(if applicable)
                            outType = modelC{xIndx}.type;
                            testMeanDose = calc_meanDose(testDoseC{1},volHistC{1});
                            if isfield(paramS,'n')
                                temp_a = 1/paramS.n.val;
                                testEUD = calc_EUD(testDoseC{1},volHistC{1},temp_a);
                                fprintf(['\n---------------------------------------\n',...
                                    'Protocol:%d, Model:\nMean Dose = %f\n%s = %f\n'],p,testEUD);
                            end
                            if strcmp(modelC{xIndx}.name,'Lung TCP')
                                additionalParamS = paramS.gTD.params;
                                for fn = fieldnames(additionalParamS)'
                                    paramS.(fn{1}) = additionalParamS.(fn{1});
                                end
                                testGTD = calc_gTD(testDoseC{1},volHistC{1},paramS);
                                fprintf(['\n---------------------------------------\n',...
                                    'GTD  = %f'],testGTD);
                            end
                            %Display TCP/BED
                            if numel(testDoseC)>1
                                testOut = feval(modelC{xIndx}.function,paramS,testDoseC,volHistC);
                            else
                                testOut = feval(modelC{xIndx}.function,paramS,testDoseC{1},volHistC{1});
                            end
                            fprintf(['\n---------------------------------------\n',...
                                'Protocol:%d, Model:\nMean Dose = %f\n%s = %f\n'],p,testMeanDose,outType,testOut);
                        end
                        %---------------------------------END TEMP-----------------------------------%
                    end
                    planC{indexS.dose}(plnNum).doseArray = dA;
                end
                protocolS(p).model = modelC;
                hSlider = ud.handle.modelsAxis(8); %Invisible; just for readout at scale=1
                
            case 3 %vs. scaled frx size
                
                hNTCPAxis = ud.handle.modelsAxis(3);
                hNTCPAxis.Visible = 'On';
                grid(hNTCPAxis,'On');
                hTCPAxis = ud.handle.modelsAxis(4);
                hTCPAxis.Visible = 'On';
                
                typesC = cellfun(@(x) x.type,protocolS(1).model,'un',0);
                if any(strcmpi(typesC,'BED'))
                    set(hTCPAxis,'yLim',[0 200]);
                    ylabel(hTCPAxis,'BED (Gy)');
                else
                    ylabel(hTCPAxis,'TCP');
                end
                
                hSlider = ud.handle.modelsAxis(7);
                xlab = 'Dose scale factor';
                
                numModelC = arrayfun(@(x)numel(x.model),protocolS,'un',0);
                numModelsV = [numModelC{:}];
                
                xScaleV = linspace(0.5,1.5,99);
                
            case 4 %vs. scaled nfrx
                
                
                hNTCPAxis = ud.handle.modelsAxis(5);
                hNTCPAxis.Visible = 'On';
                grid(hNTCPAxis,'On');
                hTCPAxis = ud.handle.modelsAxis(6);
                hTCPAxis.Visible = 'On';
                
                typesC = cellfun(@(x) x.type,protocolS(1).model,'un',0);
                if any(strcmpi(typesC,'BED'))
                    set(hTCPAxis,'yLim',[0 200]);
                    ylabel(hTCPAxis,'BED (Gy)');
                else
                    ylabel(hTCPAxis,'TCP');
                end
                
                hSlider = ud.handle.modelsAxis(8);
                xlab = 'Change in no. of fractions';
                
                numModelC = arrayfun(@(x)numel(x.model),protocolS,'un',0);
                numModelsV = [numModelC{:}];
                
                maxDeltaFrx = round(max([protocolS.numFractions])/2); %rounded
                nfrxScaleV = linspace(-maxDeltaFrx,maxDeltaFrx,99);
        end
        
        
        %% Plot model-based predictions
        hWait = waitbar(0,'Generating plots...');
        for p = 1:numel(protocolS)
            
            %Check inputs
            %1. Check that valid model file was passed
            modelC = protocolS(p).model;
            if isempty(modelC)
                msgbox('Please select model files','Plot models');
                close(hWait);
                return
            end
            %2. Check for valid structure & dose plan
            isStr = cellfun(@(x)any(~isfield(x,'strNum') | isempty(x.strNum) | x.strNum==0),modelC,'un',0);
            err = find([isStr{:}]);
            if ~isempty(err)
                msgbox(sprintf('Please select structure:\n protocol: %d\tmodels: %d',p,err),'Plot model');
                close(hWait);
                return
            end
            isPlan = isfield(ud,'planNum') && ~isempty(ud.planNum);
            if ~isPlan
                msgbox(sprintf('Please select valid dose plan.'),'Plot model');
                close(hWait);
                return
            end
            
            %Check for existing handles to criteria
            if ~isfield(protocolS(p),'criteria')
                protocolS(p).criteria = [];
            end
            if ~isfield(protocolS(p),'guidelines')
                protocolS(p).guidelines = [];
            end
            
            %Set plot transparency
            if p == ud.foreground
                plotColorM = [colorOrderM,ones(size(colorOrderM,1),1)];
                lineStyle = '-';
            else
                alpha = 0.5;
                %gray = repmat([.5 .5 .5],size(colorOrderM,1),1);
                plotColorM = [colorOrderM,repmat(alpha,size(colorOrderM,1),1)];
                lineStyleC = {'--',':','-.'};
                lineStyle = lineStyleC{p};
            end
            
            %Scale planned dose array
            plnNum = ud.planNum;
            numFrxProtocol = protocolS(p).numFractions;
            protDose = protocolS(p).totalDose;
            dpfProtocol = protDose/numFrxProtocol;
            prescribedDose = planC{indexS.dose}(plnNum).prescribedDose;
            dA = getDoseArray(plnNum,planC);
            dAscale = protDose/prescribedDose;
            dAscaled = dA * dAscale;
            planC{indexS.dose}(plnNum).doseArray = dAscaled;
            
            % Plot model-based predictions
            availableStructsC = {planC{indexS.structures}.structureName};
            if plotMode==1 || plotMode==2
                modTypeC = cellfun(@(x)(x.type),modelC,'un',0);
                modIdxV = find(strcmp(modTypeC,'NTCP'));
                numModels = length(modIdxV);
                numModelsV(p) = numModels;
            else
                numModels = numModelsV(p);
                modIdxV = 1:numModels;
            end
            
            for j = 1:numModels
                
                %Create parameter dictionary
                paramS = [modelC{modIdxV(j)}.parameters];
                structNumV = modelC{modIdxV(j)}.strNum;
                %Copy relevant fields from protocol file
                %-No. of fractions
                paramS.numFractions.val = numFrxProtocol;
                %-fraction size
                paramS.frxSize.val = dpfProtocol;
                %-alpha/beta
                abRatio = modelC{modIdxV(j)}.abRatio;
                paramS.abRatio.val = abRatio;
                
                %Scale dose bins
                if isfield(modelC{modIdxV(j)},'dv')
                    storedDVc = modelC{modIdxV(j)}.dv;
                    doseBinsC = storedDVc{1} ;
                    volHistC = storedDVc{2};
                else
                    doseBinsC = cell(1,numel(structNumV));
                    volHistC = cell(1,numel(structNumV));
                    for nStr = 1:numel(structNumV)
                        [dosesV,volsV] = getDVH(structNumV(nStr),plnNum,planC);
                        [doseBinsC{nStr},volHistC{nStr}] = doseHist(dosesV,volsV,binWidth);
                    end
                    modelC{modIdxV(j)}.dv = {doseBinsC,volHistC};
                end
                
                if plotMode==3 %vs. scaled frx size
                    scaledCPv = xScaleV * 0;
                    for n = 1 : numel(xScaleV)
                        
                        %Scale dose bins
                        scale = xScaleV(n);
                        scaledDoseBinsC = cellfun(@(x) x*scale,doseBinsC,'un',0);
                        %Apply fractionation correction as required
                        correctedScaledDoseC = frxCorrect(modelC{modIdxV(j)},structNumV,numFrxProtocol,scaledDoseBinsC);
                        
                        %Correct frxSize parameter
                        paramS.frxSize.val = scale*dpfProtocol;
                        
                        %Compute TCP/NTCP
                        if numel(structNumV)==1
                            scaledCPv(n) = feval(modelC{modIdxV(j)}.function,paramS,correctedScaledDoseC{1},volHistC{1});
                        else
                            scaledCPv(n) = feval(modelC{modIdxV(j)}.function,paramS,correctedScaledDoseC,volHistC);
                        end
                        
                        %--------------TEMP (Addded to display dose metrics & TCP/NTCP at scale = 1 for testing)-----------%
                        if n==numel(xScaleV)
                            %Get corrected dose at scale == 1
                            paramS.frxSize.val = dpfProtocol;
                            testDoseC = frxCorrect(modelC{modIdxV(j)},structNumV,numFrxProtocol,doseBinsC);
                            %Display mean dose, EUD, GTD(if applicable)
                            outType = modelC{modIdxV(j)}.type;
                            testMeanDose = calc_meanDose(testDoseC{1},volHistC{1});
                            if isfield(paramS,'n')
                                temp_a = 1/paramS.n.val;
                                testEUD = calc_EUD(testDoseC{1},volHistC{1},temp_a);
                                fprintf(['\n---------------------------------------\n',...
                                    'Protocol:%d, Model:%d\nMean Dose = %f\n%s = %f\n'],p,modIdxV(j),testEUD);
                            end
                            if strcmp(modelC{modIdxV(j)}.name,'Lung TCP')
                                additionalParamS = paramS.structures.GTV.gTD.params;
                                for fn = fieldnames(additionalParamS)'
                                    paramS.(fn{1}) = additionalParamS.(fn{1});
                                end
                                testGTD = calc_gTD(testDoseC{1},volHistC{1},paramS);
                                fprintf(['\n---------------------------------------\n',...
                                    'GTD  = %f'],testGTD);
                            end
                            %Display TCP/NTCP
                            if numel(testDoseC)>1
                                testOut = feval(modelC{modIdxV(j)}.function,paramS,testDoseC,volHistC);
                            else
                                testOut = feval(modelC{modIdxV(j)}.function,paramS,testDoseC{1},volHistC{1});
                            end
                            fprintf(['\n---------------------------------------\n',...
                                'Protocol:%d, Model:%d\nMean Dose = %f\n%s = %f\n'],p,modIdxV(j),testMeanDose,outType,testOut);
                        end
                        %---------------------------------END TEMP-----------------------------------%
                    end
                    set(hSlider,'Value',1);
                    set(hSlider,'Visible','On');
                    ud.handle.modelsAxis(7) = hSlider;
                    
                else %Scale by no. fractions (plot modes : 1,2,4)
                    
                    xScaleV = nfrxScaleV(nfrxScaleV+numFrxProtocol>=1);
                    scaledCPv = xScaleV * 0;
                    for n = 1 : numel(xScaleV)
                        
                        %Scale dose bins
                        newNumFrx = xScaleV(n)+numFrxProtocol;
                        scale = newNumFrx/numFrxProtocol;
                        scaledDoseBinsC = cellfun(@(x) x*scale,doseBinsC,'un',0);
                        
                        %Apply fractionation correction as required
                        correctedScaledDoseC = frxCorrect(modelC{j},structNumV,newNumFrx,scaledDoseBinsC);
                        
                        %Correct nFrx parameter
                        paramS.numFractions.val = newNumFrx;
                        
                        %% Compute TCP/NTCP
                        if numel(structNumV)==1
                            scaledCPv(n) = feval(modelC{j}.function,paramS,correctedScaledDoseC{1},volHistC{1});
                        else
                            scaledCPv(n) = feval(modelC{j}.function,paramS,correctedScaledDoseC,volHistC);
                        end
                        
                        %--------------TEMP (Addded to display dose metrics & TCP/NTCP at scale = 1 for testing)-----------%
                        if n==numel(nfrxScaleV)
                            %Get corrected dose at scale == 1
                            paramS.numFractions.val = numFrxProtocol;
                            testDoseC = frxCorrect(modelC{j},structNumV,numFrxProtocol,doseBinsC);
                            %Display mean dose, EUD, GTD(if applicable)
                            outType = modelC{j}.type;
                            if isfield(paramS,'n')
                                temp_a = 1/paramS.n.val;
                                testEUD = calc_EUD(testDoseC{1},volHistC{1},temp_a);
                            end
                            testMeanDose = calc_meanDose(testDoseC{1},volHistC{1});
                            if strcmp(modelC{j}.name,'Lung TCP')
                                additionalParamS = paramS.gTD.params;
                                for fn = fieldnames(additionalParamS)'
                                    paramS.(fn{1}) = additionalParamS.(fn{1});
                                end
                                testGTD = calc_gTD(testDoseC{1},volHistC{1},paramS);
                                fprintf(['\n---------------------------------------\n',...
                                    'GTD  = %f'],testGTD);
                            end
                            %Display TCP/NTCP
                            if numel(testDoseC)>1
                                testOut = feval(modelC{j}.function,paramS,testDoseC,volHistC);
                            else
                                testOut = feval(modelC{j}.function,paramS,testDoseC{1},volHistC{1});
                            end
                            fprintf(['\n---------------------------------------\n',...
                                'Protocol:%d, Model:%d\nMean dose = %f\n%s = %f\n'],p,j,testMeanDose,outType,testOut);
                        end
                        %---------------------------------END TEMP-----------------------------------%
                    end
                    step = 2*maxDeltaFrx;
                    set(hSlider,'Min',-maxDeltaFrx,'Max',maxDeltaFrx,'SliderStep',[1/step,1/step]);
                    set(hSlider,'Value',0);
                    set(hSlider,'Visible','On');
                    ud.handle.modelsAxis(8) = hSlider;
                end
                
                %% Plot NTCP vs.TCP/BED
                %Set plot color
                colorIdx = mod(j,size(plotColorM,1))+1;
                %Display curves
                if plotMode==1 || plotMode ==2
                    if strcmp(modelC{j}.type,'NTCP')
                        ntcp = ntcp + 1;
                        xLmt = get(hNTCPAxis,'xlim');
                        set(hNTCPAxis,'xlim',[min(xLmt(1),tcpM(p,1)), max(xLmt(2),tcpM(p,end))]);
                        tcpV = tcpM(p,:);
                        ud.NTCPCurve = [ud.NTCPCurve plot(hNTCPAxis,tcpV(~isnan(tcpV)),scaledCPv,'linewidth',3,...
                            'Color',plotColorM(colorIdx,:),'lineStyle',lineStyle)];
                        
                        ud.NTCPCurve(ntcp).DisplayName = [ud.Protocols(p).protocol,': ',modelC{modIdxV(j)}.name];
                        hCurr = hNTCPAxis;
                    end

                else %plotModes 3&4
                    
                    if plotMode == 4
                        set(hNTCPAxis,'xLim',[-maxDeltaFrx,maxDeltaFrx]);
                        set(hTCPAxis,'xLim',[-maxDeltaFrx,maxDeltaFrx]);
                    end
                    
                    if strcmp(modelC{j}.type,'NTCP')
                        ntcp = ntcp + 1;
                        ud.NTCPCurve = [ud.NTCPCurve plot(hNTCPAxis,xScaleV,scaledCPv,'linewidth',3,...
                            'Color',plotColorM(colorIdx,:),'lineStyle',lineStyle)];
                        ud.NTCPCurve(ntcp).DisplayName = [ud.Protocols(p).protocol,': ',modelC{j}.name];
                        hCurr = hNTCPAxis;
                    elseif strcmp(modelC{j}.type,'TCP')
                        tcp = tcp + 1;
                        ud.TCPCurve = [ud.TCPCurve plot(hTCPAxis,xScaleV,scaledCPv,'linewidth',3,...
                            'Color',plotColorM(colorIdx,:),'lineStyle',lineStyle)];
                        ud.TCPCurve(tcp).DisplayName = [ud.Protocols(p).protocol,': ',modelC{j}.name];
                        hCurr = hTCPAxis;
                    elseif strcmp(modelC{j}.type,'BED')
                        bed = bed + 1;
                        ud.BEDCurve = [ud.BEDCurve plot(hTCPAxis,xScaleV,scaledCPv,'linewidth',3,...
                            'Color',plotColorM(colorIdx,:),'lineStyle',lineStyle)];
                        ud.BEDCurve(bed).DisplayName = [ud.Protocols(p).protocol,': ',modelC{j}.name];
                        hCurr = hTCPAxis;
                    end
                end
                
                jTot = jTot+1; %No. of models displayed
                waitbar(j/sum(numModelsV));
            end
            %% Store model parameters
            protocolS(p).model = modelC;
            
            
            %% Plot criteria & guidelines
            if plotMode==3 %vs. scaled frx size
                cgScaleV = xScaleV;
            else
                nFrxV = xScaleV + numFrxProtocol;
                cgScaleV = nFrxV./numFrxProtocol;
            end
            
            if isfield(protocolS(p),'constraints')
                critS = protocolS(p).constraints;
                nFrxProtocol = protocolS(p).numFractions;
                structC = fieldnames(critS.structures);
                %Loop over structures
                for m = 1:numel(structC)
                    cStr = find(strcmpi(structC{m}, availableStructsC));
                    if ~isempty(cStr)              %If structure is available in plan
                        %Extract criteria
                        strCritS = critS.structures.(structC{m}).criteria;
                        criteriaC = fieldnames(strCritS);
                        %Get alpha/beta ratio
                        abRatio = critS.structures.(structC{m}).abRatio;
                        %Get DVH
                        [doseV,volsV] = getDVH(cStr,plnNum,planC);
                        [doseBinV,volHistV] = doseHist(doseV, volsV, binWidth);
                        %------------ Loop over criteria ----------------------
                        for n = 1:length(criteriaC)
                            
                            %Idenitfy NTCP limits
                            if strcmp(strCritS.(criteriaC{n}).function,'ntcp')
                                
                                %Get NTCP over entire scale
                                strC = cellfun(@(x) x.strNum,modelC,'un',0);
                                cIdx = find([strC{:}]==cStr);
                                if p == 1
                                    cProtocolStart(p) = 0;
                                else
                                    prevC = cellfun(@(x) x.type,ud.Protocols(p-1).model,'un',0);
                                    prevIdxV = strcmpi('ntcp',prevC);
                                    cProtocolStart(p) = sum(prevIdxV);
                                end
                                xV = ud.NTCPCurve(cProtocolStart(p)+cIdx).XData;
                                
                                
                                %Identify where limit is exceeded
                                ntcpV = ud.NTCPCurve(cProtocolStart(p)+cIdx).YData;
                                cCount = cCount + 1;
                                exceedIdxV = ntcpV >= strCritS.(criteriaC{n}).limit;
                                if ~any(exceedIdxV)
                                    cValV(cCount) = inf;
                                    cScaleV(cCount) = inf;
                                    cXv(cCount) = inf;
                                else
                                    exceedIdxV = find(exceedIdxV,1,'first');
                                    cValV(cCount) = ntcpV(exceedIdxV);
                                    cScaleV(cCount) = cgScaleV(exceedIdxV);
                                    ind = cgScaleV == cScaleV(cCount);
                                    cXv(cCount) = xV(ind);
                                    if p==ud.foreground
                                        ud.cMarker = [ud.cMarker,plot(hNTCPAxis,cXv(cCount),...
                                            cValV(cCount),'o','MarkerSize',8,'MarkerFaceColor',...
                                            'r','MarkerEdgeColor','k')];
                                    else
                                        addMarker = scatter(hNTCPAxis,cXv(cCount),...
                                            cValV(cCount),60,'MarkerFaceColor','r',...
                                            'MarkerEdgeColor','k');
                                        addMarker.MarkerFaceAlpha = .3;
                                        addMarker.MarkerEdgeAlpha = .3;
                                        ud.cMarker = [ud.cMarker,addMarker];
                                    end
                                end
                            else
                                
                                if p == 1
                                    cProtocolStart(p) = 0;
                                else
                                    prevC = cellfun(@(x) x.type,ud.Protocols(p-1).model,'un',0);
                                    prevIdxV = strcmpi('ntcp',prevC);
                                    cProtocolStart(p) = sum(prevIdxV);
                                end
                                xV = ud.NTCPCurve(cProtocolStart(p)+1).XData;
                                
                                %Idenitfy dose/volume limits
                                cCount = cCount + 1;
                                %nFrx = planC{indexS.dose}(plnNum).numFractions;
                                [cScaleV(cCount),cValV(cCount)] = calc_Limit(doseBinV,volHistV,strCritS.(criteriaC{n}),...
                                    nFrxProtocol,critS.numFrx,abRatio,cgScaleV);
                                
                            end
                            %Display line indicating clinical criteria/guidelines
                            if isinf(cScaleV(cCount))
                                cXv(cCount) = inf;
                                x = [cXv(cCount) cXv(cCount)];
                            else
                                ind = cgScaleV == cScaleV(cCount);
                                cXv(cCount) = xV(ind);
                                x = [cXv(cCount) cXv(cCount)];
                            end
                            y = [0 1];
                            %Set criteria line transparency
                            if p==ud.foreground
                                critLineH = line(hNTCPAxis,x,y,'LineWidth',1,...
                                    'Color',[1 0 0],'LineStyle','--','Tag','criteria',...
                                    'Visible','Off');
                            else
                                critLineH = line(hNTCPAxis,x,y,'LineWidth',2,...
                                    'Color',[1 0 0 alpha],'LineStyle',':','Tag','criteria',...
                                    'Visible','Off');
                            end
                            critLineUdS.protocol = p;
                            critLineUdS.structure = structC{m};
                            critLineUdS.label = criteriaC{n};
                            critLineUdS.limit = strCritS.(criteriaC{n}).limit;
                            critLineUdS.scale = cScaleV(cCount);
                            critLineUdS.val = cValV(cCount);
                            set(critLineH,'userdata',critLineUdS);
                            protocolS(p).criteria = [protocolS(p).criteria,critLineH];
                            
                        end
                        
                        %------------ Loop over guidelines --------------------
                        %Extract guidelines
                        if isfield(critS.structures.(structC{m}),'guidelines')
                            strGuideS = critS.structures.(structC{m}).guidelines;
                            guidelinesC = fieldnames(strGuideS);
                            
                            for n = 1:length(guidelinesC)
                                
                                %Idenitfy NTCP limits
                                if strcmp(strGuideS.(guidelinesC{n}).function,'ntcp')
                                    
                                    %Get NTCP over range of scale factors
                                    strC = cellfun(@(x) x.strNum,modelC,'un',0);
                                    gIdx = find([strC{:}]==cStr);
                                    
                                    if p == 1
                                        gProtocolStart(p) = 0;
                                    else
                                        prevC = cellfun(@(x) x.type,ud.Protocols(p-1).model,'un',0);
                                        prevIdxV = strcmpi('ntcp',prevC);
                                        gProtocolStart(p) = sum(prevIdxV);
                                    end
                                    xV = ud.NTCPCurve(gProtocolStart(p)+gIdx).XData;
                                    
                                    %Identify where guideline is exceeded
                                    ntcpV = ud.NTCPCurve(gProtocolStart(p)+gIdx).YData;
                                    exceedIdxV = ntcpV >= strGuideS.(guidelinesC{n}).limit;
                                    gCount = gCount + 1;
                                    if ~any(exceedIdxV)
                                        gValV(gCount) = inf;
                                        gScaleV(gCount) = inf;
                                        gXv(gCount) = inf;
                                    else
                                        exceedIdxV = find(exceedIdxV,1,'first');
                                        gValV(gCount) = ntcpV(exceedIdxV);
                                        gScaleV(gCount) = cgScaleV(exceedIdxV);
                                        ind =  cgScaleV == gScaleV(gCount);
                                        gXv(gCount) = xV(ind);
                                        clr = [239 197 57]./255;
                                        if p==ud.foreground
                                            ud.gMarker = [ud.cMarker,plot(hNTCPAxis,gXv(gCount),...
                                                gValV(gCount),'o','MarkerSize',8,'MarkerFaceColor',...
                                                clr,'MarkerEdgeColor','k')];
                                        else
                                            addMarker = scatter(hNTCPAxis,gXv(gCount),...
                                                gValV(gCount),60,'MarkerFaceColor',clr,...
                                                'MarkerEdgeColor','k');
                                            addMarker.MarkerFaceAlpha = .3;
                                            addMarker.MarkerEdgeAlpha = .3;
                                            ud.gMarker = [ud.cMarker,addMarker];
                                        end
                                    end
                                else
                                    if p == 1
                                        gProtocolStart(p) = 0;
                                    else
                                        prevC = cellfun(@(x) x.type,ud.Protocols(p-1).model,'un',0);
                                        prevIdxV = strcmpi('ntcp',prevC);
                                        gProtocolStart(p) = sum(prevIdxV);
                                    end
                                    xV = ud.NTCPCurve(gProtocolStart(p)+1).XData;
                                    %Idenitfy dose/volume limits
                                    gCount = gCount + 1;
                                    %nFrx = planC{indexS.dose}(plnNum).numFractions;
                                    [gScaleV(gCount),gValV(gCount)] = calc_Limit(doseBinV,volHistV,strGuideS.(guidelinesC{n}),...
                                        nFrxProtocol,critS.numFrx,abRatio,cgScaleV);
                                end
                                
                                %Display line indicating clinical criteria/guidelines
                                if isinf(gScaleV(gCount))
                                    gXv(gCount) = inf;
                                else
                                    ind = cgScaleV == gScaleV(gCount);
                                    gXv(gCount) = xV(ind);
                                end
                                x = [gXv(gCount) gXv(gCount)];
                                y = [0 1];
                                if p==ud.foreground
                                    guideLineH = line(hNTCPAxis,x,y,'LineWidth',2,...
                                        'Color',[239 197 57]/255,'LineStyle','--',...
                                        'Tag','guidelines','Visible','Off');
                                else
                                    guideLineH = line(hNTCPAxis,x,y,'LineWidth',2,...
                                        'Color',[239 197 57]/255,'LineStyle',':',...
                                        'Tag','guidelines','Visible','Off');
                                end
                                guideLineUdS.protocol = p;
                                guideLineUdS.structure = structC{m};
                                guideLineUdS.label = guidelinesC{n};
                                guideLineUdS.limit = strGuideS.(guidelinesC{n}).limit;
                                guideLineUdS.scale = gScaleV(gCount);
                                guideLineUdS.val = gValV(gCount);
                                set(guideLineH,'userdata',guideLineUdS);
                                protocolS(p).guidelines = [protocolS(p).guidelines,guideLineH];
                                
                            end
                        end
                        
                    end
                end
            end
            
            planC{indexS.dose}(plnNum).doseArray = dA;
        end
        
        close(hWait);
        
        %Add plot labels
        ylabel(hNTCPAxis,'NTCP');
        if plotMode == 1 || plotMode == 2
            if max(get(hNTCPAxis,'xlim'))>1
                xlabel(hNTCPAxis,'BED (Gy)');
            else
                xlabel(hNTCPAxis,'TCP');
            end
        else
            xlabel(hNTCPAxis,xlab);
        end
        
        %Add legend
        NTCPLegendC = arrayfun(@(x)x.DisplayName,ud.NTCPCurve,'un',0);
        
        constraintS = protocolS(ud.foreground);
        if isfield(constraintS,'criteria') && ~isempty(constraintS.criteria)
            
            if isempty(ud.BEDCurve)
                if isfield(constraintS,'guidelines') && ~isempty(constraintS.guidelines)
                    hax = [ud.NTCPCurve,constraintS.criteria(end),constraintS.guidelines(end)];
                    key = [NTCPLegendC,'Clinical criteria','Clinical guidelines'];
                else
                    hax = [ud.NTCPCurve,constraintS.criteria(end)];
                    key = [NTCPLegendC,'Clinical criteria'];
                end
            else
                if isfield(constraintS,'guidelines') && ~isempty(constraintS.guidelines)
                    BEDlegendC = arrayfun(@(x)x.DisplayName,ud.BEDCurve,'un',0);
                    hax = [ud.NTCPCurve,ud.BEDCurve,constraintS.criteria(end),constraintS.guidelines(end)];
                    key = [NTCPLegendC,BEDlegendC,'Clinical criteria','Clinical guidelines'];
                else
                    BEDlegendC = arrayfun(@(x)x.DisplayName,ud.BEDCurve,'un',0);
                    hax = [ud.NTCPCurve,ud.BEDCurve,constraintS.criteria(end)];
                    key = [NTCPLegendC,BEDlegendC,'Clinical criteria'];
                end
            end
            legend(hax,key,'Location','northwest','Color','none','FontName',...
                'Arial','FontWeight','normal','FontSize',11,'AutoUpdate','off');
            
        else
            legend(ud.NTCPCurve,NTCPLegendC,...
                'Location','northwest','Color','none','FontName','Arial',...
                'FontWeight','normal','FontSize',11,'AutoUpdate','off');
        end
        
        %Store userdata
        ud.Protocols = protocolS;
        set(hFig,'userdata',ud);
        
        %Display current dose/probability
        scaleDose(hSlider);
        
        %Enable user-entered scale entry
        set(ud.handle.modelsAxis(10),'enable','On');
        
        %Get datacursor mode
        if ~isempty([protocolS.criteria])
            cursorMode = datacursormode(hFig);
            set(cursorMode,'Enable','On');
            
            %Display first clinical criterion/guideline that is violated
            for p = 1:numel(ud.Protocols)
                
                hcFirst =[];
                hgFirst = [];
                
                if p==1
                    i1 = 1;
                    j1 = 1;
                else
                    i1 = length([protocolS(1:p-1).criteria])+1;
                    j1 = length([protocolS(1:p-1).guidelines])+1;
                end
                
                if ~isempty([protocolS(p).criteria])
                    i2 = length([protocolS(p).criteria]);
                    firstcViolation = cXv(i1:i1+i2-1) == min(cXv(i1:i1+i2-1));
                    %firstcViolation = find(firstcViolation) + i1;
                    critH = [protocolS(p).criteria];
                    hcFirst = critH(firstcViolation);
                end
                
                if ~isempty([protocolS(p).guidelines])
                    j2 = length([protocolS(p).guidelines]);
                    firstgViolation = gXv(j1:j1+j2-1)==min(gXv(j1:j1+j2-1));
                    %firstgViolation = find(firstgViolation) + i1;
                    guidH = [protocolS(p).guidelines];
                    hgFirst = guidH(firstgViolation);
                end
                
                if isempty(hcFirst) && isempty(hgFirst)
                    %Skip
                elseif(~isempty(hcFirst) && isempty(hgFirst)) || hcFirst(1).XData(1)<= hgFirst(1).XData(1)
                    %firstcViolation = [false(1:i1-1),firstcViolation];
                    dttag = 'criteria';
                    dispSelCriteria([],[],dttag,firstcViolation,p);
                    hDatatip = cursorMode.createDatatip(hcFirst(1));
                    hDatatip.Marker = '^';
                    hDatatip.MarkerSize=7;
                    set(hDatatip,'Visible','On','OrientationMode','Manual',...
                        'UpdateFcn',@expandDataTip,'Tag',dttag);
                else
                    %firstgViolation = [false(1:j1-1),firstgViolation];
                    dttag = 'guidelines';
                    dispSelCriteria([],[],dttag,firstgViolation,p);
                    hDatatip = cursorMode.createDatatip(hgFirst(1));
                    hDatatip.Marker = '^';
                    hDatatip.MarkerSize=7;
                    set(hDatatip,'Visible','On','OrientationMode','Manual',...
                        'UpdateFcn',@expandDataTip,'Tag',dttag);
                end
                
            end
            
            %Set datacursor update function
            set(cursorMode, 'Enable','On','SnapToDataVertex','off',...
                'UpdateFcn',@expandDataTip);
            
        end
        
        
    case 'CLEAR_PLOT'
        ud = get(hFig,'userdata');
        %Clear data/plots from any previously loaded models/plans/structures
        ud.NTCPCurve = [];
        ud.TCPCurve = [];
        ud.BEDCurve = [];
        protocolS = ud.Protocols;
        for p = 1:numel(protocolS)
            protocolS(p).criteria = [];
            protocolS(p).guidelines = [];
            % TEMP: Fix by checking prev/curr plot mode differnt instead
            for m = 1:length(protocolS(p).model)
                if isfield(protocolS(p).model{m},'dv')
                    protocolS(p).model{m} = rmfield(protocolS(p).model{m},'dv');
                end
            end
        end
        ud.Protocols = protocolS;
        for ax = 2:6
            cla(ud.handle.modelsAxis(ax));
            legend(ud.handle.modelsAxis(ax),'off')
            set(ud.handle.modelsAxis(ax),'Visible','Off');
        end
        
        %Clear text readouts
        if isfield(ud,'scaleDisp')
            ud = rmfield(ud,'scaleDisp');
        end
        if isfield(ud,'y1Disp')
            ud = rmfield(ud,'y1Disp');
        end
        if isfield(ud,'y2Disp')
            ud = rmfield(ud,'y2Disp');
        end
        
        %Clear user-input scale factor/no. frx
        set(ud.handle.modelsAxis(10),'String','')
        
        %Turn off datacursor mode
        cursorMode = datacursormode(hFig);
        cursorMode.removeAllDataCursors;
        set(cursorMode, 'Enable','Off');
        
        %turn slider display off
        set(ud.handle.modelsAxis(7),'Visible','Off');
        set(ud.handle.modelsAxis(8),'Visible','Off');
        set(ud.handle.modelsAxis(10),'enable','Off');
        set(hFig,'userdata',ud);
        
    case 'LIST_MODELS'
        %Get selected protocols
        ud = get(hFig,'userdata');
        ud.handle.editModels = [];
        protocolS = ud.Protocols;
        
        %Check models for required fields ('function' and 'parameter')
        numProtocols = length(protocolS);
        for j = 1:numProtocols
            modelC = protocolS(j).model;
            numModels = length(modelC);
            
            for i = 1:numModels
                modelNameC = cell(1,numModels);
                fieldC = fieldnames(modelC{i});
                fnIdx = strcmpi(fieldC,'function');
                paramIdx = strcmpi(fieldC,'parameters');
                
                %Check for 'function' and 'parameter' fields
                if ~any(fnIdx) || isempty(modelC{i}.(fieldC{fnIdx}))
                    msgbox('Model file must include ''function'' attribute.','Model file error');
                    return
                end
                if ~any(paramIdx) || isempty(modelC{i}.(fieldC{paramIdx}))
                    msgbox('Model file must include ''parameters'' attribute.','Model file error');
                    return
                end
                
                %Check for 'structures' field
                strIdx = strcmpi(fieldnames(modelC{i}.parameters),'structures');
                if ~any(strIdx) || isempty(modelC{i}.parameters.structures)
                    msgbox('Model file must include ''parameters'' attribute.','Model file error');
                    return
                end
                
            end
        end
        
        set(ud.modelTree,'Visible',true);
        set(ud.handle.inputH(10),'Enable','On'); %Plot button on
        %set(ud.handle.inputH(12),'Enable','On'); %Allow x-axis selection
        %set(ud.handle.inputH(13),'Enable','On'); %Allow y-axis selection
        set(hFig,'userdata',ud);
        
    case 'SAVE_MODELS'
        ud = get(hFig,'userData');
        protocolS = ud.Protocols;
        
        %Save changes to model files
        for j = 1: numel(protocolS)
            modelC = protocolS(j).model;
            outFile = {protocolS(j).modelFiles};
            numModels = numel(outFile);
            %Create UID
            modelNamesC = cellfun(@(x) x.function,modelC,'un',0);
            dateTimeV = clock.';
            dateTimeC = arrayfun(@num2str,dateTimeV,'un',0);
            randC = arrayfun(@num2str,1000.*rand(1,numModels),'un',0);
            UIDC = strcat({'outcomeModels.'},modelNamesC,{'.'},dateTimeC(2),...
                dateTimeC(3),dateTimeC(1),{'.'},dateTimeC{4:6},{'.'},randC);
            modelC = arrayfun(@(i) setfield(modelC{i},'UID',UIDC{i}),1:length(modelC),'un',0);
            %Remove fields
            remC = {'plan','strNum','dosNum','dv','planNum'};
            for m = 1:numel(outFile)
                remIdx = ismember(remC,fieldnames(modelC{m}));
                modelC{m} = rmfield(modelC{m},remC(remIdx));
                fprintf('\nSaving changes to %s ...',outFile{m});
                savejson('',modelC{m},'filename',outFile{m});
            end
        end
        fprintf('\nSave complete.\n');
        
        set(ud.handle.inputH(9),'Enable','Off');  %Disable save
        set(hFig,'userdata',ud);
        
        
        
    case 'CLOSEREQUEST'
        
        closereq
        
end


%% -----------------------------------------------------------------------------------------

% Calculate scale factor at which criteria are first violated
    function [cScale, critVal] = calc_Limit(doseBinV,volHistV,critS,numFrxProtocol,critNumFrx,abRatio,scaleFactorV)
        cFunc =  critS.function;
        cLim = critS.limit;
        critVal = -inf;
        count = 0;
        s = 0;
        while critVal <= cLim && count<length(scaleFactorV)
            count = count + 1;
            %Scale dose bins
            s = scaleFactorV(count);
            scaledDoseBinsV = s*doseBinV;
            
            %Convert to standard no. fractions
            Na = numFrxProtocol;
            Nb = critNumFrx;
            a = Na;
            b = Na*Nb*abRatio;
            c = -scaledDoseBinsV.*(b + scaledDoseBinsV*Nb);
            correctedScaledDoseV = (-b + sqrt(b^2 - 4*a*c))/(2*a);
            
            if isfield(critS,'parameters')
                cParamS = critS.parameters;
                critVal = feval(cFunc,correctedScaledDoseV,volHistV,cParamS);
            else
                critVal = feval(cFunc,correctedScaledDoseV,volHistV);
            end
        end
        if s == max(scaleFactorV)
            cScale = inf;
            critVal = inf;
        else
            cScale = s;
        end
    end

%Panel to view constraints & select for display
    function critPanel(hObj,hEvt,command)
        
        % Get GUI fig handle
        hCritFig = findobj('Tag','critFig');
        
        
        if nargin==0
            command = 'INIT';
        end
        switch(upper(command))
            
            case 'INIT'
                %Figure postion, colour
                mainFigPosV = get(hFig,'Position');
                shift = 10;
                height = 350;
                width = 450;
                posV = [mainFigPosV(1)+mainFigPosV(3)+20, mainFigPosV(2),...
                    width, height];
                figColor = [.6 .75 .75];
                defaultColor = [0.8 0.9 0.9];
                
                %Get list of available constraints for display
                ud = get(hFig,'userdata');
                protS = ud.Protocols;
                currProtocol = ud.foreground;
                if isempty(protS(currProtocol).criteria) && isempty(protS(currProtocol).guidelines)
                    return
                end
                
                numCriteria = 0;
                numGuide = 0;
                %--criteria
                
                if ~isempty(protS(currProtocol).criteria)
                    criteriaS = [protS(currProtocol).criteria.UserData];
                    structsC = {criteriaS.structure};
                    limC = {criteriaS.label};
                    numCriteria = numel(protS(currProtocol).criteria);
                    typeC(1:numCriteria) = {'criteria'};
                else
                    structsC = {};
                    limC = {};
                    typeC = {};
                end
                %--guidelines
                if ~isempty(protS(currProtocol).guidelines)
                    guideS = [protS(currProtocol).guidelines.UserData];
                    strgC = {guideS.structure};
                    limgC = {guideS.label};
                    limgC = cellfun(@(x) strjoin({x,'(guideline)'}),limgC,'un',0);
                    numGuide = numel(protS(currProtocol).guidelines);
                    structsC = [strgC,structsC].';
                    limC = [limgC,limC].';
                    gtypeC(1:numGuide) = {'guidelines'};
                    typeC = [gtypeC,typeC];
                end
                
                if isempty(hCritFig)
                    %Initialize figure
                    hCritFig = figure('tag','critFig','name','Clinical constraints',...
                        'numbertitle','off','position',posV,...
                        'CloseRequestFcn', {@critPanel,'closeRequest'}',...
                        'menubar','none','resize','off','color',figColor);
                else
                    figure(hCritFig)
                    return
                end
                
                %Frames
                critPanelH(1) = uicontrol(hCritFig,'units','pixels',...
                    'Position',[shift shift width-2*shift height-2*shift ],'Style',...
                    'frame','backgroundColor',defaultColor);
                critPanelH(2) = uicontrol(hCritFig,'units','pixels',...
                    'Position',[shift shift width-2*shift height-9*shift ],'Style',...
                    'frame','backgroundColor',defaultColor);
                
                %View prev/next
                critPanelH(3) = uicontrol(hCritFig,'units','pixels',...
                    'Position',[width/4 height-8*shift,...
                    width/2 height/8],'Style', 'text','string','View previous / next',...
                    'FontSize',10,'FontWeight','Bold',...
                    'backgroundColor',defaultColor);
                critPanelH(4) = uicontrol(hCritFig,'units','pixels',...
                    'Position',[width/4 height-5.5*shift,...
                    4*shift 2*shift],'Style','push','string','<<','FontSize',...
                    10,'FontWeight','Bold','backgroundColor',defaultColor,...
                    'callback',{@critPanel,'prev'}');
                
                critPanelH(6) = uicontrol(hCritFig,'units','pixels',...
                    'Position',[width/2+7*shift height-5.5*shift,...
                    4*shift 2*shift],'Style','push','string','>>','FontSize',...
                    10,'FontWeight','Bold','backgroundColor',defaultColor,...
                    'callback',{@critPanel,'next'}');
                
                %Select to display
                critPanelH(7) = uicontrol(hCritFig,'units','pixels',...
                    'Position',[1.2*shift 19*shift,width/2 height/6],...
                    'Style', 'text','string','Select constraints to display',...
                    'FontSize',10,'FontWeight','Bold','backgroundColor',defaultColor);
                data(:,1) = num2cell(false(numCriteria+numGuide,1));
                data(:,2) = structsC(:);
                data(:,3) = limC(:);
                data = [{false},{'All'},{' '};{false},{'None'},{' '};data];
                tableWidth = width-6*shift;
                critPanelH(8) = uitable('columnFormat',{'logical','char','char'},...
                    'Data',data,'RowName',[],'ColumnName',...
                    {'Select','Structure','Constraint'},'ColumnEditable',[true,false,false],...
                    'BackgroundColor',[1,1,1],'Position',[3*shift 3*shift,tableWidth,...
                    height/2+shift],'ColumnWidth',{tableWidth/6,tableWidth/3,...
                    tableWidth/2},'CellEditCallback',@dispSelCriteria);
                set(critPanelH(8),'userdata',typeC);
                
                critUd.handles = critPanelH;
                set(hCritFig,'userdata',critUd);
                
            case 'NEXT'
                
                ud = get(hFig,'userdata');
                protS = ud.Protocols;
                
                for k = 1:length(protS)
                    currProtocol = k;
                    hCrit = protS(currProtocol).criteria;
                    hGuide = protS(currProtocol).guidelines;
                    dispStateC = [];
                    if ~isempty(hGuide)
                        dispStateC = {hGuide.Visible};
                    end
                    if ~isempty(hCrit)
                        dispStateC = [dispStateC,{hCrit.Visible}];
                    end
                    dispIdxV = strcmp(dispStateC,'on');
                    gNum = numel(hGuide);
                    cMode = datacursormode(hFig);
                    if sum(dispIdxV)~=1 || sum(dispIdxV)==0 %More than one constraint or none displayed
                        %Do nothing
                        return
                    else
                        %Get available limits
                        ud = get(hFig,'userdata');
                        limitsV = [ arrayfun(@(x) x.XData(1),hGuide),...
                            arrayfun(@(x) x.XData(1),hCrit)];
                        currentLimit = limitsV(dispIdxV);
                        [limitsV,limOrderV] = sort(limitsV);
                        next = find(limitsV > currentLimit,1,'first');
                        if isempty(next) || isinf(limitsV(next))
                            %Last limit displayed
                            %OR
                            %Next limit beyond max display scale
                            return
                        else
                            nextIdxV = find(limitsV==limitsV(next));
                            nextLimit = limOrderV(nextIdxV);
                            for l = 1:numel(nextLimit)
                                if nextLimit(l) <= gNum  %Guidelines
                                    dispSelCriteria([],[],'guidelines',nextLimit(l),currProtocol);
                                    hNext = hGuide(nextLimit(l));
                                    hData = cMode.createDatatip(hNext);
                                    set(hData,'Visible','On','OrientationMode','Manual',...
                                        'UpdateFcn',@expandDataTip,'Tag','guidelines');
                                else                 %Criteria
                                    dispSelCriteria([],[],'criteria',nextLimit(l)-gNum,currProtocol);
                                    hNext = hCrit(nextLimit(l)-gNum);
                                    hData = cMode.createDatatip(hNext);
                                    set(hData,'Visible','On','OrientationMode','Manual',...
                                        'UpdateFcn',@expandDataTip,'Tag','criteria');
                                end
                            end
                            
                        end
                    end
                end
                
            case 'PREV'
                
                ud = get(hFig,'userdata');
                protS = ud.Protocols;
                
                for k = 1:length(protS)
                    currProtocol = k;
                    hCrit = protS(currProtocol).criteria;
                    hGuide = protS(currProtocol).guidelines;
                    dispStateC = [];
                    if ~isempty(hGuide)
                        dispStateC = {hGuide.Visible};
                    end
                    if ~isempty(hCrit)
                        dispStateC = [dispStateC,{hCrit.Visible}];
                    end
                    dispIdxV = strcmp(dispStateC,'on');
                    gNum = numel(hGuide);
                    cMode = datacursormode(hFig);
                    if sum(dispIdxV)~=1 || sum(dispIdxV)==0 %More than one constraint or none displayed
                        %Do nothing
                        return
                    else
                        %Get available limits
                        ud = get(hFig,'userdata');
                        limitsV = [ arrayfun(@(x) x.XData(1),hGuide),...
                            arrayfun(@(x) x.XData(1),hCrit)];
                        currentLimit = limitsV(dispIdxV);
                        [limitsV,limOrderV] = sort(limitsV,'descend');
                        prev = find(limitsV < currentLimit,1,'first');
                        if isempty(prev) || isinf(limitsV(prev))
                            %First limit displayed
                            return
                        else
                            prvIdxV = find(limitsV==limitsV(prev));
                            prevLimit = limOrderV(prvIdxV);
                            for l = 1:numel(prevLimit)
                                if prevLimit(l) <= gNum  %Guidelines
                                    dispSelCriteria([],[],'guidelines',prevLimit(l),currProtocol);
                                    hNext = hGuide(prevLimit(l));
                                    hData = cMode.createDatatip(hNext);
                                    set(hData,'Visible','On','OrientationMode','Manual',...
                                        'UpdateFcn',@expandDataTip,'Tag','guidelines');
                                else                 %Criteria
                                    dispSelCriteria([],[],'criteria',prevLimit(l)-gNum,currProtocol);
                                    hNext = hCrit(prevLimit(l)-gNum);
                                    hData = cMode.createDatatip(hNext);
                                    set(hData,'Visible','On','OrientationMode','Manual',...
                                        'UpdateFcn',@expandDataTip,'Tag','criteria');
                                end
                            end
                            
                        end
                    end
                end
                
                
                
            case 'CLOSEREQUEST'
                closereq;
                
        end
    end

%Display selected limits
    function [selectedIdv,selTypeC] = dispSelCriteria(hObj,hEvt,varargin)
        
        cMode = datacursormode(hFig);
        cMode.removeAllDataCursors;
        
        if isempty(hEvt)  %Prog call
            
            %Get handles to constraints
            ud = get(hFig,'userdata');
            protS = ud.Protocols;
            type = varargin{1};
            idxV = varargin{2};
            pNum = varargin{3};
            
            %Turn off currently displayed limits
            hCrit = protS(pNum).criteria;
            hGuide = protS(pNum).guidelines;
            for k = 1:numel(hCrit)
                set(hCrit(k),'Visible','Off')
            end
            for k = 1:numel(hGuide)
                set(hGuide(k),'Visible','Off')
            end
            protS(pNum).criteria = hCrit;
            protS(pNum).guidelines = hGuide;
            
            
            %Turn on selected limit
            if strcmp(type,'criteria')
                hCrit = [protS(pNum).criteria];
                set(hCrit(idxV),'Visible','On');
                %numElements = [0,cumsum(arrayfun(@(x)numel(x.criteria),protS))];
                %for pNum = 1:numel(protS)
                %protS(pNum).criteria = hCrit(numElements(pNum)+1:numElements(pNum+1));
                %end
                protS(pNum).criteria = hCrit;
            else
                hGuide = [protS(pNum).guidelines];
                set(hGuide(idxV),'Visible','On');
                %numElements = [0,cumsum(arrayfun(@(x)numel(x.guidelines),protS))];
                %for pNum = 1:numel(protS)
                %protS(pNum).guidelines = hGuide(numElements(pNum)+1:numElements(pNum+1));
                %end
                protS(pNum).guidelines = hGuide;
            end
            
            ud.Protocols = protS;
            set(hFig,'userdata',ud);
            
        else %Checkbox selection
            
            %Get handles to constraints
            ud = get(hFig,'userdata');
            protS = ud.Protocols;
            
            %Get slelected constraint
            selectedIdv = hEvt.Indices(:,1);
            stateV = cell2mat(hObj.Data(selectedIdv,1));
            stateC = {'Off','On'};
            
            if selectedIdv==1  %'All'
                for pNum = 1:numel(protS)
                    hCrit = protS(pNum).criteria;
                    hGuide = protS(pNum).guidelines;
                    %Criteria
                    for k = 1:numel(hCrit)
                        set(hCrit(k),'Visible',stateC{stateV+1});
                    end
                    %Guidelines
                    for k = 1:numel(hGuide)
                        set(hGuide(k),'Visible',stateC{stateV+1});
                    end
                end
                
            elseif selectedIdv==2 %'None'
                if stateV == 1
                    %Criteria
                    for pNum = 1:numel(protS)
                        hCrit = protS(pNum).criteria;
                        hGuide = protS(pNum).guidelines;
                        for k = 1:numel(hCrit)
                            set(hCrit(k),'Visible','Off');
                        end
                        %Guidelines
                        for k = 1:numel(hGuide)
                            set(hGuide(k),'Visible','Off');
                        end
                    end
                end
                hObj.Data(:,1) = {false};
                
            else
                
                ud = get(hFig,'userdata');
                protS = ud.Protocols;
                currProtocol = ud.foreground;
                gNum = numel(protS(currProtocol).guidelines);
                
                selectedIdv = selectedIdv-2;
                type =  get(hObj,'userdata');
                selTypeC = type(selectedIdv);
                
                for pNum = 1:numel(protS)
                    for k = 1:numel(selectedIdv)
                        if strcmp(selTypeC(k),'guidelines') %guidelines
                            selNum = selectedIdv(k);
                        else                               %criteria
                            selNum = selectedIdv(k)- gNum;
                        end
                        %Toggle display on/off
                        set(protS(pNum).(selTypeC{k})(selNum),'Visible',stateC{stateV(k)+1});
                        %Expand tooltip if on
                        if strcmp(stateC{stateV+1},'On')
                            hExp = cMode.createDatatip(protS(pNum).(selTypeC{k})(selNum));
                            evt.Target = protS(pNum).(selTypeC{k})(selNum);
                            evt.Position = [evt.Target.XData(1),evt.Target.YData(1)];
                            expandDataTip(hExp,evt);
                        end
                    end
                end
                
            end
            
        end
        
        ud.Protocols = protS;
        set(hFig,'userdata',ud);
        
    end




% Edit model parameters
    function editParams(hObj,hData)
        
        ud = get(hFig,'userdata');
        tag = get(hObj,'Tag');
        
        %Get input data
        idx = hData.Indices(1);
        val = hData.EditData;
        val2num = str2num(val);
        if isempty(val2num) %Convert from string if numerical
            val2num = val;
        end
        prtcNum = ud.PrtcNum;
        modelsC = ud.Protocols(prtcNum).model;
        if isfield(ud,'ModelNum')
            modelNum = ud.ModelNum;
        end
        
        %Update parameter
        switch(tag)
            case 'strSel'
                if hData.Indices(2)==1
                    parameterS = modelsC{modelNum}.parameters;
                    inputStructC = fieldnames(parameterS.structures);
                    inputStructC = strcat('Select structure',{' '},inputStructC);
                    matchIdx = find(strcmp(inputStructC,val));
                    modelsC{modelNum}.inputStrNum = matchIdx;
                    if ~isfield(modelsC{modelNum},'strNum') || ...
                            modelsC{modelNum}.strNum(matchIdx)==0
                        hObj.Data{2} = 'Select from list';
                    end
                else
                    strListC = {'Select structure',planC{indexS.structures}.structureName};
                    matchIdx = find(strcmp(strListC,val));
                    inputStrNum = modelsC{modelNum}.inputStrNum;
                    modelsC{modelNum}.strNum(inputStrNum) = matchIdx - 1;
                    if isfield(ud.Protocols(prtcNum),'constraints')
                        criteriaS = ud.Protocols(prtcNum).constraints;
                        expectedStrName = strrep(hObj.Data{1},'Select structure ','');
                        selectedStrName = strListC{matchIdx};
                        %Update expected str name in criteria data stucture
                        if isfield(criteriaS.structures,expectedStrName)
                            expS = criteriaS.structures.(expectedStrName);
                            criteriaS.structures.(selectedStrName) = expS;
                            criteriaS.structures = rmfield(criteriaS.structures,expectedStrName);
                            ud.Protocols(prtcNum).constraints = criteriaS;
                        end
                    end
                end
            case 'doseSel'
                if hData.Indices(2)==1
                    return
                else
                    dosListC = {'Select Plan',planC{indexS.dose}.fractionGroupID};
                    matchIdx = find(strcmp(dosListC,val));
                    %modelsC{modelNum}.planNum = matchIdx - 1;
                    ud.planNum = matchIdx - 1;
                end
            case 'fieldEdit'
                modelsC{modelNum} = modelsC{modelNum};
                parName = hObj.Data{idx,1};
                modelsC{modelNum}.(parName) = val2num;
                modelsC{modelNum} = modelsC{modelNum};
                set(ud.handle.inputH(9),'Enable','On');  %Enable save
            case 'paramEdit'
                %Update modelC
                parName = hObj.Data{idx,1};
                strParam = 0;
                if isfield(modelsC{modelNum}.parameters,'structures')
                    structS = modelsC{modelNum}.parameters.structures;
                    if isstruct(structS)
                        stC = fieldnames(structS);
                        found = 0;
                        t = 0;
                        while ~found & t<numel(stC)
                            found = isfield(structS.(stC{t+1}),parName);
                            t = t+1;
                        end
                        if found
                            strParam = 1;
                            type = structS.(stC{t}).(parName).type;
                        end
                    end
                end
                if ~strParam
                    type = modelsC{modelNum}.parameters.(parName).type;
                end
                if strcmpi(type{1},'bin')
                    desc = modelsC{modelNum}.parameters.(parName).desc;
                    ctgIdx = strcmp(desc,val2num);
                    value = modelsC{modelNum}.parameters.(parName).cteg(ctgIdx);
                    modelsC{modelNum}.parameters.(parName).val = value;
                else
                    modelsC{modelNum}.parameters.(parName).val = val2num;
                end
                set(ud.handle.inputH(9),'Enable','On');  %Enable save
        end
        ud.Protocols(prtcNum).model = modelsC;
        set(hFig,'userdata',ud);
        
    end

%User-input scale factor
    function enterScale(hObj,hEvt)
        ud = get(hFig,'UserData');
        val = str2double(get(hObj,'String'));
        if ud.plotMode==3
            slider = ud.handle.modelsAxis(7);
        else
            slider = ud.handle.modelsAxis(8);
        end
        if val < get(slider,'Min') || val > get(slider,'Max')
            msgbox(sprintf('Invalid input. Please enter value between %.1f and %.1f',get(slider,'Min'),get(slider,'Max')));%Invalid input
        else
        set(slider,'Value',val);
        scaleDose(slider,[]);
        end
    end

%Display clinical criteria on selection
    function txt = expandDataTip(hObj,hEvt)
        %Get userdata
        ud = get(hFig,'Userdata');
        
        %Check if visible
        if strcmpi(get(hObj,'Visible'),'Off')
            return
        end
        
        %Get scale at limit
        if isempty(hEvt)                 %Initialize (display 1st violation)
            posV = get(hObj,'Position');
            xVal = posV(1);
            pNum = ud.PrtcNum;
            lscale = cLine.UserData.scale;
        else
            %Update (display selected limit)
            cLine = hEvt.Target;
            xVal = cLine.XData(1);
            pNum = cLine.UserData.protocol;
            lscale = cLine.UserData.scale;
        end
        
        %Get protocol info
        pName = ud.Protocols(pNum).protocol;
        numFrx = ud.Protocols(pNum).numFractions;
        totDose = ud.Protocols(pNum).totalDose;
        frxSize = totDose/numFrx;
        
        %Get scaled frx size or nfrx at limit
        if ud.plotMode==3
            %Scale frx size
            frxSize = lscale*frxSize;
        else
            %Scale nfrx
            numFrx = lscale*numFrx;
        end
        
        %Get TCP/BED at limit
        if ud.plotMode==2
            yVal = xVal;
            yDisp  = 'TCP';
        elseif ud.plotMode==3
            if ~isempty(ud.TCPCurve)
                yDisp  = 'TCP';
                xidx = ud.TCPCurve(pNum).XData == lscale;
                yVal = ud.TCPCurve(pNum).YData(xidx);
            else
                yDisp  = 'BED';
                xidx = ud.BEDCurve(pNum).XData == lscale;
                yVal = ud.BEDCurve(pNum).YData(xidx);
            end
        elseif ud.plotMode==4
            if ~isempty(ud.TCPCurve)
                yDisp  = 'TCP';
                xidx = ud.TCPCurve(pNum).XData == xVal;
                yVal = ud.TCPCurve(pNum).YData(xidx);
            else
                yDisp  = 'BED';
                xidx = ud.BEDCurve(pNum).XData == xVal;
                yVal = ud.BEDCurve(pNum).YData(xidx);
            end
        else %Plot mode:1
            yVal = xVal;
            yDisp  = 'BED';
        end
        
        
        
        %Check for all violations at same scale
        %---Criteria:---
        hCrit = ud.Protocols(pNum).criteria;
        limitM = get(hCrit,'xData');
        
        if isempty(limitM)
            %Skip
        else
            if iscell(limitM)
                limitM = cell2mat(limitM);
            end
            nCrit =  sum(limitM(:,1) == xVal);
            txt = {};
            if nCrit>0
                limitIdx = find(limitM(:,1) == xVal);
                for k = 1:numel(limitIdx)
                    lUd = hCrit(limitIdx(k)).UserData;
                    start = (k-1)*8 + 1;
                    
                    if ud.plotMode==3
                        scDisp = ['Current fraction size: ',num2str(frxSize),' Gy'];
                    else
                        scDisp = ['Current fraction no.: ',num2str(numFrx)];
                    end
                    
                    if strcmpi(yDisp,'BED')
                        last = ['Current ',yDisp,': ',num2str(yVal),' Gy'];
                    else
                        last = ['Current ',yDisp,': ',num2str(yVal)];
                    end
                    
                    txt(start : start+8) = { [' '],[num2str(k),'. Structure: ',lUd.structure],...
                        ['Criterion: ', lUd.label],...
                        ['Clinical limit: ', num2str(lUd.limit)],...
                        ['Current value: ', num2str(lUd.val)],...
                        [' '],...
                        ['Protocol: ', pName],...
                        scDisp,last};
                    
                end
            end
        end
        
        %---Guidelines:---
        hGuide = ud.Protocols(pNum).guidelines;
        limitM = get(hGuide,'xData');
        
        if isempty(limitM)
            %Skip
        else
            if iscell(limitM)
                limitM = cell2mat(limitM);
            end
            nGuide =  sum(limitM(:,1) == xVal);
            k0 = length(txt);
            if nGuide>0
                limitIdx = find(limitM(:,1) == xVal);
                %Get structures, limits
                for k = 1:numel(limitIdx)
                    lUd = hGuide(limitIdx(k)).UserData;
                    start = k0 + (k-1)*8 + 1;
                    
                    if ud.plotMode==3
                        scDisp = ['Current fraction size: ',num2str(frxSize)];
                    else
                        scDisp = ['Current fraction no.: ',num2str(numFrx)];
                    end
                    
                    if strcmpi(yDisp,'BED')
                        last = ['Current ',yDisp,': ',num2str(yVal),' Gy'];
                    else
                        last = ['Current ',yDisp,': ',num2str(yVal)];
                    end
                    
                    
                    txt(start : start+8) = {[' '],[num2str(nCrit+k),'. Structure: ',lUd.structure],...
                        ['Criterion: ', lUd.label],...
                        ['Clinical limit (guideline): ', num2str(lUd.limit)],...
                        ['Current value: ', num2str(lUd.val)],...
                        [' '],...
                        ['Protocol: ', pName],...
                        scDisp,last};
                end
            end
        end
        
        %Display
        hObj.Marker = '^';
        hObj.MarkerSize = 7;
        set(hObj,'Visible','On');
    end

% Extract model parameters & values and display in table
    function hTab = extractParams(modelS)
        
        %Delete any previous param tables
        ud = get(hFig,'userdata');
        if isfield(ud,'currentPar')
            delete(ud.currentPar);
        end
        
        %Get parameter names
        modelParS = modelS.parameters;
        genParListC = fieldnames(modelParS);
        nPars = numel(genParListC);
        reservedFieldsC = {'type','cteg','desc'};
        
        %Define table dimensions
        rowHt = 25;
        rowSep = 10;
        rowWidth = 130;
        pos = get(hFig,'Position');
        fwidth = pos(3);
        fheight = pos(3);
        left = 10;
        columnWidth ={rowWidth-1,rowWidth-1};
        posV = [.22*fwidth-2.5*left .4*fheight 2*rowWidth rowHt];
        row = 1;
        hTab = gobjects(0);
        % Create rows displaying model parameters
        for k = 1:nPars
            if strcmpi(genParListC{k},'structures')
                if isstruct(modelParS.(genParListC{k}))
                    structS = modelParS.(genParListC{k});
                    strListC = fieldnames(structS);
                    for s = 1:length(strListC)
                        strParListC = fieldnames(structS.(strListC{s}));
                        for t = 1:numel(strParListC)
                            parS = structS.(strListC{s}).(strParListC{t});
                            %parName = [strListC{s},' ',strParListC{t}];
                            parName = strParListC{t};
                            [columnFormat,dispVal] = extractVal(parS);
                            dataC = {parName,dispVal};
                            hTab(row) = uitable(hFig,'Tag','paramEdit','Position', posV + [0 -(row*(rowHt+1)) 0 0 ],...
                                'columnformat',columnFormat,'Data',dataC,'Visible','Off','FontSize',10,...
                                'columneditable',[false,true],'columnname',[],'rowname',[],...
                                'columnWidth',columnWidth,'celleditcallback',@editParams);
                            row = row+1;
                        end
                    end
                end
            else
                if ~strcmpi(genParListC{k},reservedFieldsC)
                    parName = genParListC{k};
                    [columnFormat,dispVal] = extractVal(modelParS.(genParListC{k}));
                    dataC = {parName,dispVal};
                    hTab(row) = uitable(hFig,'Tag','paramEdit','Position', posV + [0 -(row*(rowHt+1)) 0 0 ],...
                        'columnformat',columnFormat,'Data',dataC,'Visible','Off','FontSize',10,...
                        'columneditable',[false,true],'columnname',[],'rowname',[],...
                        'columnWidth',columnWidth,'celleditcallback',@editParams);
                    row = row+1;
                end
            end
        end
    end

    function [columnFormat,dispVal] = extractVal(parS)
        val = parS.val;
        switch(lower(parS.type{1}))
            case 'string'
                columnFormat = {'char','char'};
                dispVal = val;
            case'cont'
                columnFormat = {'numeric','numeric'};
                dispVal = val ;
            case 'bin'
                descV = parS.desc;
                descC = cellstr(descV);
                columnFormat = {'char',descC};
                dispVal = parS.desc{val+1};
        end
    end


% Perform fractionation correction
    function eqScaledDoseC = frxCorrect(modelParS,strNumV,numFrx,scaledDoseC)
        if strcmpi(modelParS.fractionCorrect,'yes') 
            eqScaledDoseC = cell(1,numel(strNumV));
            switch lower((modelParS.correctionType))
                case 'fsize'
                    %Convert to EQD in std fraction size
                    stdFrxSize = modelParS.stdFractionSize;
                    for s = 1:numel(strNumV)
                        scaledFrxSizeV = scaledDoseC{s}/numFrx;
                        eqScaledDoseC{s} = scaledDoseC{s} .*(scaledFrxSizeV+modelParS.abRatio)...
                            ./(stdFrxSize + modelParS.abRatio);
                    end
                case 'nfrx'
                    %Convert to standard no. fractions
                    Na = numFrx;
                    Nb = modelParS.stdNumFractions;
                    a = Na;
                    b = Na*Nb*modelParS.abRatio;
                    for s = 1:numel(strNumV)
                        scaledDoseBinsV = scaledDoseC{s};
                        c = -scaledDoseBinsV.*(b + scaledDoseBinsV*Nb);
                        eqScaledDoseC{s}= (-b + sqrt(b^2 - 4*a*c))/(2*a);
                    end 
            end
        else
            eqScaledDoseC = scaledDoseC;
        end
        
    end



%Store user inputs to userdata
    function getParams(hObj,hEvt)
        
        ud = get(hFig,'userdata');
        if ~isempty(hEvt)
            tree = hObj.getTree;
            currNode = hEvt.getCurrentNode;
        end
        
        if  ~isempty(hEvt) && currNode.getLevel==0      %Expand to list protocols
            tree.expandRow(tree.getSelectionRows);
            
            %Set default dose plan if only one is available
            planListC = {'Select dose plan',planC{indexS.dose}.fractionGroupID};
            if numel(planListC)==2 
                planIdx = 2;
                ud.planNum = 1; %Default to 1st plan
            end
            
        elseif ~isempty(hEvt) && currNode.getLevel==1   %Expand protocol node to list models
            
            %Get selected protocol no.
            protS = ud.Protocols;
            protListC = {protS.protocol};
            prtcNum = strcmp(currNode.getName,protListC);
            ud.PrtcNum = find(prtcNum);
            
            %Get dose plan input
            planListC = {'Select dose plan',planC{indexS.dose}.fractionGroupID};
            if isfield(ud,'planNum') & ~isempty(ud.planNum)
                planIdx = ud.planNum + 1;
            else
                %User selection
                planIdx = 1;
                ud.planNum = [];
            end
            
            %Table for selecting dose plan
            hTab = ud.handle.inputH(5);
            fmt = {'char' planListC};
            dosDat = {'Select dose plan',planListC{planIdx}};
            set(hTab,'ColumnFormat',fmt,'Data',dosDat,'Visible','On','Enable','On');
            ud.handle.inputH(5) = hTab;
            set(hFig,'userdata',ud);
            
            %Expand protocol node to list models
            tree.expandRow(tree.getSelectionRows);
            
            %Get default parameters (from JSON files for models)
            getParams([],[]);
            
        else
            %Allow selection of structures & parameters for each model
            protS = ud.Protocols;
            
            if ~isempty(hEvt)
                prtcol = currNode.getParent.getName;
                prtListC = {protS.protocol};
                prtcNumV = find(strcmp(prtcol,prtListC));
                ud.PrtcNum = prtcNumV;
            else
                prtcNumV = 1:length(ud.Protocols); %For initialization
            end
            
            if isfield(ud,'planNum')
                planNum = ud.planNum;
            else
                planNum = [];
            end
            
            for t = 1:length(prtcNumV)
                
                if ~isempty(planNum)
                    %Table2 : Plan selection
                    hTab2 = ud.handle.inputH(5);
                    planDispC = get(hTab2,'ColumnFormat');
                    txtDispC = get(hTab2,'Data');
                    planListC = planDispC{2};
                    set(hTab2,'Data',{txtDispC{1},planListC{planNum+1}});
                    ud.handle.inputH(5) = hTab2;
                end
                
                modelsC = protS(prtcNumV(t)).model;
                modListC = cellfun(@(x) x.name,modelsC,'un',0);
                if ~isempty(hEvt)
                    modelNumV = find(strcmp(currNode.getName,modListC));
                else
                    modelNumV = 1:length(modListC);
                end
                
                for s = 1:length(modelNumV)
                    
                    modName = modelsC{modelNumV(s)}.name;
                    
                    %Get structure input
                    if ~isstruct(modelsC{modelNumV(s)}.parameters.structures)
                        %If model has no structure-specific parameters
                        inputStructC = {modelsC{modelNumV(s)}.parameters.structures};
                    else
                        inputStructC = fieldnames(modelsC{modelNumV(s)}.parameters.structures);
                    end
                    numStruct = length(inputStructC);
                    structListC = {'Select from list',planC{indexS.structures}.structureName};
                    structDispC = cell(numel(inputStructC),1);
                    
                    if isfield(modelsC{modelNumV(s)},'strNum')
                        strIdxV = modelsC{modelNumV(s)}.strNum;
                        for r = 1:numel(inputStructC)
                            structDispC{r} = ['Select structure ',inputStructC{r}];
                        end
                    else
                        strIdxV = zeros(1,numStruct);
                        for r = 1:numel(inputStructC)
                            structDispC{r} = ['Select structure ',inputStructC{r}];
                            strMatch = strcmpi(inputStructC{r},structListC);
                            if ~any(strMatch)
                                strIdxV(r) = 0;
                            else
                                strIdxV(r) = find(strMatch)-1;
                            end
                        end
                    end
                    
                    
                    %Get parameters
                    set(hFig,'userdata',ud);
                    hPar = extractParams(modelsC{modelNumV(s)});
                    ud = get(hFig,'userdata');
                    
                    if ~isempty(hEvt)
                        %Add file properties if missing
                        fieldsC = fieldnames(modelsC{modelNumV(s)});
                        valsC = struct2cell(modelsC{modelNumV(s)});
                        filePropsC = {'modified_at','modified_by','created_at','created_by',};
                        missingFilePropsV = ~ismember(filePropsC,lower(fieldsC));
                        if any(missingFilePropsV)
                            idx = find(missingFilePropsV);
                            for r = 1:numel(idx)
                                fieldsC = [fieldsC(:);filePropsC{r}];
                                valsC = [valsC(:);{''}];
                            end
                        end
                        tab3C = {'name','type','stdFractionSize','prescribedDose','abRatio','function','created_by',...
                            'created_at','modified_by','modified_at'};
                        valsC = valsC(ismember(fieldsC,tab3C));
                        fieldsC = fieldsC(ismember(fieldsC,tab3C));
                        
                        
                        %Display parameters from .json file
                        %Table1 : Structure selection
                        hTab1 = ud.handle.inputH(4);
                        fmtC = {structDispC.',structListC};
                        if isfield(modelsC{modelNumV(s)},'inputStrNum')
                            inputStrNum = modelsC{modelNumV(s)}.inputStrNum;
                        else
                            inputStrNum = 1;
                            modelsC{modelNumV(s)}.inputStrNum = 1;
                        end
                        strDat = [structDispC{inputStrNum},structListC(strIdxV(inputStrNum)+1)];
                        set(hTab1,'ColumnFormat',fmtC,'Data',strDat,...
                            'Visible','On','Enable','On');
                        
                        %Table2
                        
                        %Table3 : Miscellaneous fields from .json file
                        hTab3 = ud.handle.inputH(8);
                        set(hTab3,'Data',[fieldsC,cellfun(@num2str,valsC,'un',0)],'Visible','On','Enable','On');
                        %Parameters
                        for r = 1:numel(hPar)
                            set(hPar(r),'Visible','On');
                        end
                        
                        %Store tables to userdata
                        ud.handle.inputH(4) = hTab1;
                        set(ud.handle.inputH(6),'Visible','On'); %Parameters header
                        set(ud.handle.inputH(7),'String',['Current model:  ',modName],'Visible','On'); %Display name of currently selected model
                        ud.handle.inputH(8) = hTab3;
                    end
                    
                    ud.currentPar = hPar;
                    modelsC{modelNumV(s)}.strNum = strIdxV;
                    
                end
                protS(prtcNumV(t)).model = modelsC;
            end
            
            if ~isempty(hEvt)
                %set current model nos
                ud.ModelNum = modelNumV;
                
                %Enable save
                set(ud.handle.inputH(9),'Enable','On');
            end
            ud.Protocols = protS;
            set(hFig,'userdata',ud);
        end
                
    end

%Listdlg for folder selection
    function [dirListC,dirIdx,selected] = listFiles(fpath,mode)
        
        dirS = dir([fpath,filesep,'*.json']);
        dirListC = {dirS(:).name};
        dirListC = dirListC(~ismember(dirListC,{'.','..'}));
        [dirIdx,selected] = listdlg('ListString',dirListC,...
            'ListSize',[300 100],'Name','Select protocols','SelectionMode',mode);
        
    end


% Compute TCP/NTCP at scaled dose
    function scaleDose(hObj,hEvent)
        
        ud = get(hFig,'userdata');
        protS = ud.Protocols;
        
        %Get selected scale
        userScale = get(hObj,'Value');
        xScale = userScale;
        
        %Get scale & clear any previous markers
        switch(ud.plotMode)
            case {1,2}
                y1PlotAxis = ud.handle.modelsAxis(2); %NTCP axis
                y2PlotAxis = [];
                maxDelFrx = round(max([protS.numFractions])/2); %rounded
            case 3
                y1PlotAxis = ud.handle.modelsAxis(3); %NTCP axis
                y2PlotAxis = ud.handle.modelsAxis(4); %TCP/BED axis
                fxSizScaleV = linspace(0.5,1.5,99);
                xIdx = abs(fxSizScaleV-userScale) < eps;
                if isempty(xIdx)
                    return %Invalid scale factor entered
                end
            case 4
                y1PlotAxis = ud.handle.modelsAxis(5); %NTCP axis
                y2PlotAxis = ud.handle.modelsAxis(6); %TCP/BED axis
                maxDelFrx = round(max([protS.numFractions])/2);
        end
        hScaled_y1 = findall(y1PlotAxis,'type','line','LineStyle','-.');
        delete(hScaled_y1);
        if ~isempty(y2PlotAxis)
            hScaled_y2 = findall(y2PlotAxis,'type','line','LineStyle','-.');
            delete(hScaled_y2);
        end
        
        %Clear readouts
        if isfield(ud,'scaleDisp')
            set(ud.scaleDisp,'String','');
        end
        if isfield(ud,'y1Disp')
            set(ud.y1Disp,'String','');
        end
        if isfield(ud,'y2Disp')
            set(ud.y2Disp,'String','');
        end
        xLmtV = get(y1PlotAxis,'xLim');
        hDisp_y1 = text(xLmtV(1),0,'','Parent',y1PlotAxis,...
            'FontSize',8,'Color',[.3 .3 .3]);
        if ~isempty(y2PlotAxis)
            hDisp_y2 = text(xLmtV(2),0,'','Parent',y2PlotAxis,...
                'FontSize',8,'Color',[.3 .3 .3]);
        end
        
        %Set color order
        colorM = [0 229 238;123 104 238;255 131 250;0 238 118;218 165 32;...
            196	196	196;0 139 0;28 134 238;238 223 204]/255;
        
        %Scale plots as selected
        modNum = 0;
        y1 = 0;
        y2 = 0;
        for l = 1:numel(ud.Protocols)
            
            nMod = length(ud.Protocols(l).model);
            if l == ud.foreground
                pColorM = [colorM,ones(size(colorM,1),1)];
            else
                wt = 0.4;
                pColorM = [colorM,repmat(wt,size(colorM,1),1)];
            end
            
            %Get plan no.
            planNum = ud.planNum;
            
            %Loop over models
            for k = 1:nMod
                modNum = modNum+1;
                
                % Get params
                modelsC = ud.Protocols(l).model;
                paramsS = modelsC{k}.parameters;
                
                % Get struct
                strNum = modelsC{k}.strNum;
                paramsS.structNum = strNum;
                
                % Get plan
                paramsS.planNum = planNum;
                paramsS.numFractions.val = ud.Protocols(l).numFractions;
                paramsS.frxSize.val = ud.Protocols(l).totalDose/ud.Protocols(l).numFractions;
                paramsS.abRatio.val = modelsC{k}.abRatio;
                
                % Get dose bins
                if isfield(modelsC{k},'dv')
                    dose0C = modelsC{k}.dv{1};
                    vol0C = modelsC{k}.dv{2};
                    
                    %Scale
                    if ud.plotMode==3
                        scdoseC = cellfun(@(x) x*userScale,dose0C,'un',0);
                        paramsS.frxSize.val = userScale*paramsS.frxSize.val;
                    else
                        nFProtocol = paramsS.numFractions.val;
                        scNumFrx = userScale + nFProtocol;
                        nfrxV = linspace(-maxDelFrx,maxDelFrx,99);
                        [~,xIdx] = min(abs(nfrxV-userScale));
                        if isempty(xIdx)
                            return %Invalid scale factor entered
                        end
                        paramsS.numFractions.val = scNumFrx;
                        scdoseC = cellfun(@(x) x*scNumFrx/nFProtocol,dose0C,'un',0);
                    end
                    %Apply fractionation correction where required
                    eqScaledDoseC = frxCorrect(modelsC{k},strNum,paramsS.numFractions.val,scdoseC);
                    
                    % Pass as vector if nStr==1
                    if numel(strNum) == 1
                        vol0C = vol0C{1};
                        eqScaledDoseC = eqScaledDoseC{1};
                    end
                    
                    % Compute probability
                    cpNew = feval(modelsC{k}.function,paramsS,eqScaledDoseC,vol0C);
                    
                    % Set plot color
                    clrIdx = mod(k,size(pColorM,1))+1;
                    
                    if strcmpi(modelsC{k}.type,'NTCP') %y1 axis
                        loc = hObj.Min;
                        hplotAx = y1PlotAxis;
                        y1 = y1+1;
                        count = y1;
                        hDisp_y1(count) = text(xLmtV(1),0,'','Parent',y1PlotAxis,...
                            'FontSize',8,'Color',[.3 .3 .3]);
                        hText = hDisp_y1(count);
                        txtPos = xLmtV(1) - 0.15*abs(xLmtV(1));
                        if ud.plotMode==1 || ud.plotMode==2
                            xScale = ud.NTCPCurve(k).XData(xIdx);
                        end
                        skip=0;
                    else %y2 axis
                        if ud.plotMode==1 || ud.plotMode==2
                            %Skip
                            skip = 1;
                        else
                            loc = hObj.Max;
                            hplotAx = y2PlotAxis;
                            y2 = y2+1;
                            count = y2;
                            hDisp_y2(count) = text(xLmtV(2),0,'','Parent',y2PlotAxis,...
                                'FontSize',8,'Color',[.3 .3 .3]);
                            hText = hDisp_y2(count);
                            txtPos = xLmtV(2)+.05;
                            skip=0;
                        end
                    end
                    
                    if ~skip %Error here: TO DO! Check!
                        plot([xScale xScale],[0 cpNew],'Color',pColorM(clrIdx,:),'LineStyle','-.',...
                            'linewidth',2,'parent',hplotAx);
                        plot([loc xScale],[cpNew cpNew],'Color',pColorM(clrIdx,:),'LineStyle','-.',...
                            'linewidth',2,'parent',hplotAx);
                        set(hText,'Position',[txtPos,cpNew],'String',sprintf('%.3f',cpNew));
                    end
                    
                end
            end
        end
        scaleVal = sprintf('%.3f',xScale);
        hXDisp = text(xScale,-.03,scaleVal,'Parent',y1PlotAxis,...
            'FontSize',8,'Color',[.3 .3 .3]);
        ud.scaleDisp = hXDisp;
        ud.y1Disp = hDisp_y1;
        if ~isempty(y2PlotAxis)
            ud.y2Disp = hDisp_y2;
        end
        
        set(hFig,'userdata',ud);
        
    end


%Set plot mode
    function setPlotMode(hObj,~)
        ud = get(hFig,'userData');
        sel = get(hObj,'Value');
        ud.plotMode = sel - 1;
        if ud.plotMode==3
             set(ud.handle.modelsAxis(11),'String','Enter scale factor');
             set(ud.handle.modelsAxis(10),'Visible','On','Enable','On');
             set(ud.handle.modelsAxis(11),'Visible','On'); 
        elseif ud.plotMode==4
             txt = sprintf('Enter\n \x0394nfrx');
             set(ud.handle.modelsAxis(11),'String',txt);
               set(ud.handle.modelsAxis(10),'Visible','On','Enable','On');
             set(ud.handle.modelsAxis(11),'Visible','On'); 
        else
            set(ud.handle.modelsAxis(10),'Visible','Off');
            set(ud.handle.modelsAxis(11),'Visible','Off');
        end
       
        set(hFig,'userData',ud);
    end


% Switch focus between plots for different protocols
    function switchFocus(hObj,~)
        ud = get(hFig,'userData');
        sel = get(hObj,'Value')-1;
        ud.foreground=sel;
        set(hFig,'userData',ud);
        ROE('PLOT_MODELS');
    end







end
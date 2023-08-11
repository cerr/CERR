function ROE(command,varargin)
  %  GUI for outcomes modeling (TCP, NTCP)
  %  This tool uses JSONlab toolbox v1.2, an open-source JSON/UBJSON encoder and
  %  decoder for MATLAB and Octave.
  %  See : http://www.mathworks.com/matlabcentral/fileexchange/33381-jsonlab--a-
  %        toolbox-to-encode-decode-json-files
  % =======================================================================================================================
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
    GUIWidth = 960;
    GUIHeight = 600;
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
    titleH(1) = axes('parent',hFig,'tag','titleFrame','units','pixels',...
    'Position',[1.5*shift posTop-shift/2 GUIWidth-2.5*shift 0.08*GUIHeight ],...
    'color',defaultColor,'ytick',[],'xtick',[],'box','on');
    titleH(2) = uicontrol(hFig,'tag','title','units','pixels',...
    'Position',[.3*GUIHeight+1 posTop+2 .6*GUIWidth 3*shift ],...
    'String','ROE: Radiotherapy Outcomes Estimator','Style','text', 'fontSize',12,...
    'FontWeight','Bold','HorizontalAlignment','center',...
    'backgroundColor',defaultColor);
    
    ud.handle.title = titleH;
    guidata(hFig,ud);
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
    figColor = [.6 .75 .75];
    posTop = GUIHeight-topMarginHeight;
    
    %% Push button for protocol selection
    inputH(1) = axes('parent',hFig,'units','pixels','Position',...
    [1.5*shift shift leftMarginWidth+.07*GUIWidth GUIHeight-topMarginHeight-...
    3*shift],'color',defaultColor,'ytick',[],'xtick',[],'box','on');
    inputH(2) = uicontrol(hFig,'tag','modelTitle','units','pixels',...
    'Position',[2.5*shift posTop-.16*GUIHeight .15*GUIWidth 2*shift],...
    'String','Protocols & models','Style','text','fontSize',9,...
    'fontWeight', 'Bold', 'BackgroundColor',defaultColor,...
    'HorizontalAlignment','center','Visible','Off');
    inputH(3) = uicontrol(hFig,'tag','modelFileSelect','units','pixels',...
    'Position',[2.5*shift posTop-.1*GUIHeight .15*GUIWidth 3*shift], 'String',...
    'Select protocols','Style','push', 'fontSize',10,...
    'FontWeight','normal','BackgroundColor',defaultColor,...
    'HorizontalAlignment','right','callback',...
    'ROE(''LOAD_MODELS'')');
    
    %% Pop-up menus to select structures & dose plans
    tablePosV = [.22*GUIWidth-2*shift posTop-.13*GUIHeight .25*GUIWidth 2.5*shift];
    colWidth = tablePosV(3)/2-1;
    inputH(4) = uitable(hFig,'Tag','strSel','Position',tablePosV-[0 3*shift 0 0],'Enable','Off',...
    'ColumnName',[],'RowName',[],'Visible','Off','backgroundColor',defaultColor,...
    'columnEditable',[true,true],'Data',{'Select structure','List of structures'},...
    'ColumnWidth',{colWidth,colWidth},'FontSize',10,'cellEditCallback',...
    @(hObj,hData)editParamsROE(hObj,hData,hFig,planC));
    inputH(5) = uitable(hFig,'Tag','doseSel','Position',tablePosV,'Enable','Off',...
    'ColumnName',[],'RowName',[],'Visible','Off','backgroundColor',defaultColor,...
    'columnEditable',[true,true],'Data',{'Select dose plan','List of plans'},...
    'ColumnWidth',{colWidth,colWidth},'FontSize',10,'cellEditCallback',...
    @(hObj,hData)editParamsROE(hObj,hData,hFig,planC));
    
    %% Tables to display & edit model parameters
    inputH(6) = uicontrol(hFig,'units','pixels','Visible','Off','fontSize',10,...
    'Position',tablePosV + [0 -.1*GUIHeight 0 0 ],'String','Model parameters',...
    'Style','text','FontWeight','Bold','HorizontalAlignment','Left',...
    'backgroundColor',defaultColor); %Title: Model parameters
    inputH(7) = uicontrol(hFig,'units','pixels','Visible','Off','String','',...
    'Position',tablePosV + [0 -.15*GUIHeight 0 0 ],'FontSize',10,'Style','text',...
    'FontWeight','Bold','HorizontalAlignment','Left','backgroundColor',defaultColor,...
    'foregroundColor',[.6 0 0]); %Model name display
    
    % AI hide JSON param display
    %inputH(8) = uitable(hFig,'Tag','fieldEdit','Position',tablePosV + ...
    %[0 -.75*GUIHeight 0 8*shift],'Enable','Off','ColumnName',{'Fields','Values'},...
    %'FontSize',10,'RowName',[],'Visible','Off','backgroundColor',defaultColor,...
    %'ColumnWidth',{round(tablePosV(3)/2),round(tablePosV(3)/2)},...
    %'columnEditable',[false,true],'backgroundcolor',[1 1 1],'cellEditCallback',...
    %@(hObj,hData)editParamsROE(hObj,hData,hFig,planC)); %Parameter tables
    
    %% Push-buttons to save, plot, display style
    inputH(9) = uicontrol(hFig,'units','pixels','Tag','saveJson','Position',...
    [.39*GUIWidth 1.5*shift .06*GUIWidth 3*shift],'backgroundColor',defaultColor,...
    'String','Save','Style','Push', 'fontSize',10,'FontWeight','normal',...
    'Enable','Off','Callback','ROE(''SAVE_MODELS'' )'); %Save
    inputH(10) = uicontrol(hFig,'units','pixels','Tag','plotButton','Position',...
    [.31*GUIWidth 1.5*shift .06*GUIWidth 3*shift],'backgroundColor',defaultColor,...
    'String','Plot','Style','Push', 'fontSize',10,'FontWeight','normal',...
    'Enable','Off','Callback','ROE(''PLOT_MODELS'' )'); %plot
    inputH(11) = uicontrol(hFig,'units','pixels','Tag','switchPlot','Position',...
    [.18*GUIWidth 1.5*shift .12*GUIWidth 3*shift],'backgroundColor',[1 1 1],...
    'String',{'--Display mode--','NTCP v.BED','NTCP v.TCP','Scale fraction size',...
    'Scale no. fractions' },'Style','popupmenu', 'fontSize',10,'FontWeight',...
    'normal','Enable','On','Callback',@(hObj,hEvt)setPlotModeROE(hObj,hEvt,hFig));
    
    %% Panel for protocol & model display
    inputH(12) = uicontrol(hFig,'Style','frame','units','pixels',...
    'Position',[shift 4*shift .16*GUIWidth .7*GUIHeight],...
    'backgroundColor',[1 1 1]);
    inputH(13) = uicontrol(hFig,'Style','popupmenu',...
    'Position',[2.5*shift GUIHeight-20*shift .15*GUIWidth 2*shift],...
    'String','Protocols','fontSize',10,'Visible','Off','Enable','Off',...
    'Callback','ROE(''LIST_MODELS'')');
    inputH(14) = uicontrol(hFig,'Style','listbox',...
    'Position',[2.5*shift 1.5*shift .15*GUIWidth .6*GUIHeight],...
    'String','','fontSize',10,'Enable','Off','Visible','Off',...
    'Callback',@(hObj,hEvt)getParamsROE(hObj,hEvt,hFig,planC));
    
    
    % Input prescribed dose
    inputH(15) = uicontrol('parent',hFig,'units','pixels','Position',...
    [.24*GUIWidth-2.5*shift posTop-.08*GUIHeight 10*shift,2*shift],...
    'Style','Text','String','Prescribed Dose','fontSize',10,...
    'backgroundColor',defaultColor);
    inputH(16) = uicontrol('parent',hFig,'units','pixels','Position',...
    [.32*GUIWidth+shift posTop-.08*GUIHeight 8*shift,2.5*shift],...
    'Style','Edit','String','','Visible','On','fontSize',10,...
    'Callback',@(hObj,hEvt)clearStoredDVHsROE(hObj,hEvt,hFig),...
    'tooltipstring','Input Rx (Gy) and press enter.');
    inputH(17) = uicontrol('parent',hFig,'units','pixels','Position',...
    [.42*GUIWidth posTop-.08*GUIHeight 2*shift,2*shift],'Style',...
    'Text','String','Gy','fontSize',10,'backgroundColor',defaultColor);
    
    
    %% Plot axes
    
    %Draw frame
    plotH(1) = axes('parent',hFig,'units','pixels','Position',...
    [leftMarginWidth+.09*GUIWidth shift GUIWidth-leftMarginWidth-.1*GUIWidth...
    GUIHeight-topMarginHeight-3*shift ],'color',defaultColor,'ytick',[],...
    'xtick',[],'box','on');
    
    %Axes
    %NTCP vs TCP/BED
    plotH(2) = axes('parent',hFig,'tag','modelsAxis','tickdir', 'out',...
    'nextplot','add','units','pixels','Position',...
    [leftMarginWidth+.12*GUIWidth .17*GUIHeight .46*GUIWidth,...
    GUIHeight-topMarginHeight-13*shift],'color',[1 1 1],...
    'XAxisLocation','bottom','YAxisLocation','left','xlim',[50 51],'ylim',[0 1],...
    'fontSize',10,'fontWeight','bold','box','on','visible','off');
    
    %NTCP vs. scaled frx size
    plotH(3) = axes('parent',hFig,'tag','modelsAxis','tickdir', 'out',...
    'nextplot','add','units','pixels','Position',get(plotH(2),'Position'),'color',[1 1 1],...
    'XAxisLocation','bottom','YAxisLocation','left','xlim',[.5 1.5],'ylim',[0 1],...
    'fontSize',10,'fontWeight','bold','box','on','visible','off');
    %TCP/BED vs. scaled frx size
    plotH(4) = axes('parent',hFig,'tag','modelsAxis2','tickdir', 'out',...
    'nextplot','add','units','pixels','Position',get(plotH(2),'Position'),...
    'color','none','XAxisLocation','bottom','YAxisLocation','right',...
    'xlim',[.5 1.5],'ylim',[0 1],'xtick',[],'fontSize',10,'fontWeight',...
    'bold','box','on','visible','off');
    
    
    %NTCP vs. scaled nfrx
    plotH(5) = axes('parent',hFig,'tag','modelsAxis','tickdir', 'out',...
    'nextplot','add','units','pixels','Position',get(plotH(2),'Position'),...
    'color',[1 1 1],'XAxisLocation','bottom','YAxisLocation','left','ylim',[0 1],...
    'fontSize',10,'fontWeight','bold','box','on','visible','off');
    %TCP/BED vs. scaled nfrx
    plotH(6) = axes('parent',hFig,'tag','modelsAxis2','tickdir', 'out',...
    'nextplot','add','units','pixels','Position',get(plotH(2),'Position'),...
    'color','none','XAxisLocation','bottom','YAxisLocation','right',...
    'ylim',[0 1],'xtick',[],'fontSize',10,'fontWeight',...
    'bold','box','on','visible','off');
    
    
    %Sliders
    %scale frx size
    plotH(7) = uicontrol('parent',hFig,'units','pixels','Position',...
    [leftMarginWidth+.12*GUIWidth 4.5*shift .47*GUIWidth, 1.8*shift],...
    'Style','Slider','Visible','Off','Tag','Scale','Min',0.5,'Max',1.5,'Value',1,...
    'SliderStep',[1/(99-1),1/(99-1)]);
    addlistener(plotH(7),'Value',@(hObj,hEvt)scaleDoseROE(hObj,hEvt,hFig));
    
    %scale nfrx
    plotH(8) = uicontrol('parent',hFig,'units','pixels','Position',...
    [leftMarginWidth+.12*GUIWidth 4.5*shift .47*GUIWidth 1.8*shift],...
    'Style','Slider','Visible','Off','Tag','Scale','Min',-15,'Max',15,'Value',0,...
    'SliderStep',[1/30 1/30]);
    addlistener(plotH(8),'Value',@(hObj,hEvt)scaleDoseROE(hObj,hEvt,hFig));
    
    %Push-button for constraints panel
    plotH(9) = uicontrol('parent',hFig,'units','pixels','Position',...
    [GUIWidth-16*shift 1.2*shift 13*shift 3*shift],...
    'Style','push','Enable','On','String','View constraints',...
    'backgroundColor',[192 205 230]./255,'fontSize',10,...
    'Callback',{@critPanelROE,'INIT'});
    
    %Input scale
    plotH(10) = uicontrol('parent',hFig,'units','pixels','Position',...
    [GUIWidth-3.5*shift 4.5*shift 2*shift 2*shift],...
    'Style','edit','Visible','Off','Enable','Off','fontSize',10,...
    'Callback',@(hObj,hEvt)enterScaleROE(hObj,hEvt,hFig));
    plotH(11) = uicontrol('parent',hFig,'units','pixels','Position',...
    [GUIWidth-7.5*shift 6.5*shift 6*shift 3*shift],'backgroundColor',defaultColor,...
    'Style','Text','Visible','Off','fontSize',8);
    
    %Turn off datacursor mode
    %cursorMode = datacursormode(hFig);
    %cursorMode.removeAllDataCursors;
    %set(cursorMode, 'Enable','Off');
    
    %% Store handles
    ud.handle.inputH = inputH;
    ud.handle.modelsAxis = plotH;
    guidata(hFig,ud);
    
  case 'LOAD_MODELS'
    ROE('REFRESH');
    ud = guidata(hFig);
    
    %Get paths to JSON files
    optS = opts4Exe(fullfile(getCERRPath,'CERRoptions.json')); 
    %NOTE: Define path to .json files for protocols, models & clinical criteria in CERROptions.json
    %optS.ROEProtocolPath = 'your/path/to/protocols';
    %optS.ROEModelPath = 'your/path/to/models';
    %optS.ROECriteriaPath = 'your/path/to/criteria';
    
%    protocolPath = eval(optS.ROEProtocolPath);
%    modelPath = eval(optS.ROEModelPath);
%    criteriaPath = eval(optS.ROECriteriaPath);
    protocolPath = optS.ROEProtocolPath;
    modelPath = optS.ROEModelPath;
    criteriaPath = optS.ROECriteriaPath;
    
    % List available protocols for user selection
    [protocolListC,protocolIdx,ok] = listFilesROE(protocolPath);
    if ~ok
      return
    end
    
    for p = 1:numel(protocolIdx)
      %Cycle through selected protocols
      [~,protocol] = fileparts(protocolListC{protocolIdx(p)});
      protocolInfoS = loadjson(fullfile(protocolPath,protocolListC{protocolIdx(p)}),'ShowProgress',1);
      %Load .json for protocol
      modelListC = fieldnames(protocolInfoS.models);
      %Get list of relevant models
      numModels = numel(modelListC);
      protocolS(p).modelFiles = '';
      for m = 1:numModels
        protocolS(p).protocol = protocolInfoS.name;
        modelFPath = fullfile(modelPath,protocolInfoS.models.(modelListC{m}).modelFile);
        %Get path to .json for model
        protocolS(p).model{m} = loadjson(modelFPath,'ShowProgress',1);
        %Load model parameters from .json file
        protocolS(p).modelFiles = [protocolS(p).modelFiles,modelFPath];
        modelName = protocolS(p).model{m}.name;
      end
      protocolS(p).numFractions = protocolInfoS.numFractions;
      protocolS(p).totalDose = protocolInfoS.totalDose;
      %Load associated clinical criteria/guidelines
      if isfield(protocolInfoS,'criteriaFile')
        critFile = fullfile(criteriaPath,protocolInfoS.criteriaFile);
        critS = loadjson(critFile,'ShowProgress',0);
        protocolS(p).constraints = critS;
      end
    end
    
    protocolDispC = {protocolS(:).protocol};
    protocolDispC = ['Protocols',protocolDispC];
    set(ud.handle.inputH(2),'Visible','On');
    set(ud.handle.inputH(12),'Visible','On');
    set(ud.handle.inputH(13),'String',protocolDispC,'Visible','On','Enable','On');
    
    %Store protocol & model parameters from JSON files to GUI userdata
    ud.Protocols = protocolS;
    guidata(hFig,ud);
    
  case 'PLOT_MODELS'
    
    %% Get plot mode
    ud = guidata(hFig);
    if ~isfield(ud,'plotMode') || isempty(ud.plotMode) || isequal(ud.plotMode,0)
      msgbox('Please select display mode','Plot models');
      return
    else
      plotMode = ud.plotMode;
    end
    
    %% Clear previous plots
    ROE('CLEAR_PLOT',hFig);
    
    ud = guidata(hFig);
    if ~isfield(ud,'planNum') || isempty(ud.planNum) || ud.planNum==0
      msgbox('Please select valid dose plan','Selection required');
      return
    end
    RxField = ud.handle.inputH(16);
    if isempty(get(RxField,'String'))
      msgbox('Please provide prescribed dose (Gy).','Missing parameter');
      return
    else
      prescribedDose = str2double(get(RxField,'String'));
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
    
    %% Define color order
    colorOrderP1M = [0 229 238;123 104 238;255 131 250;0 238 118;218 165 32;141	141	141;0 139 0;28 134 238;238 189 125]/255;
    
    colorOrderP2M = [140 215 218;200 193 235;255 188 254;158 238 198;218 188 105;196	196	196;126 226 126;108 173 238;238 223 204]/255;
    
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
    
    %% Handle missing structure input
    for p = 1:numel(protocolS)
      
      modelC = protocolS(p).model;
      
      %Identify models with no associated struct. selection
      strSelC = cellfun(@(x)x.strNum , modelC,'un',0);
      noSelV = find([strSelC{:}]==0);
      %Allow for optional inputs 
      optFlagC = checkInputStructsROE(modelC);
      numStrV = cellfun(@numel,optFlagC);
      cumStrV = cumsum(numStrV);
      optFlagV = find([optFlagC{:}]==1);
      noSelV(ismember(noSelV,optFlagV)) = [];
      %Exclude optional structures with no user input
      modelC = skipOptionalStructsROE(modelC,optFlagC,strSelC);
      
      %Allow users to input missing structures or skip associated models
      if any(noSelV)
        modList = cellfun(@(x)x.name , modelC,'un',0);
        modNumV = ismember(cumStrV,noSelV);
        modList = strjoin(modList(modNumV),',');
        %msgbox(['Please select structures required for models ' modList],'Selection required');
        dispMsg = sprintf(['No structure selected',...
        ' for ',modList,'.\n Skip model(s)?']);
        missingSel = questdlg(dispMsg,'Missing structure','Yes','No','Yes');
        if ~isempty(missingSel) && strcmp(missingSel,'Yes')
          modelC(modNumV) = [];
        else
          return
        end
      end
    end
    
    
    %% Mode-specific computations
    switch plotMode
      
    case {1,2} %NTCP vs BED/TCP
      
      maxDeltaFrx = round(max([protocolS.numFractions])/2);
      nfrxScaleV = linspace(-maxDeltaFrx,maxDeltaFrx,99);
      
      hNTCPAxis = ud.handle.modelsAxis(2);
      set(hNTCPAxis,'Visible','On');
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
        %prescribedDose = planC{indexS.dose}(plnNum).prescribedDose;
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
        if isfield(modelC{xIndx},'abRatio')
          abRatio = modelC{xIndx}.abRatio;
          paramS.abRatio.val = abRatio;
        end
        
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
          correctedScaledDoseC = frxCorrectROE(modelC{xIndx},structNumV,newNumFrx,scaledDoseBinsC);
          
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
            testDoseC = frxCorrectROE(modelC{xIndx},structNumV,numFrxProtocol,doseBinsC);
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
      set(hNTCPAxis,'Visible','On');
      grid(hNTCPAxis,'On');
      hTCPAxis = ud.handle.modelsAxis(4);
      set(hTCPAxis,'Visible','On');
      
      typesC = cellfun(@(x) x.type,protocolS(1).model,'un',0);
      if any(strcmpi(typesC,'BED'))
        set(hTCPAxis,'yLim',[0 200]);
        hLaby = ylabel(hTCPAxis,'BED (Gy)');
      else
        hLaby = ylabel(hTCPAxis,'TCP');
      end
      yLimV = get(hTCPAxis,'yLim');
      yPos = (yLimV(1)+yLimV(2))/2;
      set(hLaby,'Position',[1.5,yPos,0])

      hSlider = ud.handle.modelsAxis(7);
      xlab = 'Dose scale factor';
      
      numModelC = arrayfun(@(x)numel(x.model),protocolS,'un',0);
      numModelsV = [numModelC{:}];
      
      xScaleV = linspace(0.5,1.5,99);
      
    case 4 %vs. scaled nfrx
      
      
      hNTCPAxis = ud.handle.modelsAxis(5);
      set(hNTCPAxis,'Visible','On');
      grid(hNTCPAxis,'On');
      hTCPAxis = ud.handle.modelsAxis(6);
      set(hTCPAxis,'Visible','On');
      
      typesC = cellfun(@(x) x.type,protocolS(1).model,'un',0);
      if any(strcmpi(typesC,'BED'))
        set(hTCPAxis,'yLim',[0 200]);
        hLaby = ylabel(hTCPAxis,'BED (Gy)');
      else
        hLaby = ylabel(hTCPAxis,'TCP');
      end
      yLimV = get(hTCPAxis,'yLim');
      yPos = (yLimV(1)+yLimV(2))/2;
      set(hLaby,'Position',[1.5,yPos,0])
      
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
        %plotColorM = [colorOrderM,ones(size(colorOrderM,1),1)];
        %transparency not supported
        plotColorM = colorOrderP1M;
        lineStyle = '-';
      else
        %alpha = 0.5; %not supported
        plotColorM = colorOrderP2M;
        
        lineStyleC = {'--',':','-.'};
        lineStyle = lineStyleC{p};
      end
      
      %Scale planned dose array
      plnNum = ud.planNum;
      numFrxProtocol = protocolS(p).numFractions;
      protDose = protocolS(p).totalDose;
      dpfProtocol = protDose/numFrxProtocol;
      %prescribedDose = planC{indexS.dose}(plnNum).prescribedDose;
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
        if isfield(modelC{modIdxV(j)},'abRatio')
          abRatio = modelC{modIdxV(j)}.abRatio;
          paramS.abRatio.val = abRatio;
        end
        
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
            correctedScaledDoseC = frxCorrectROE(modelC{modIdxV(j)},structNumV,numFrxProtocol,scaledDoseBinsC);
            
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
              testDoseC = frxCorrectROE(modelC{modIdxV(j)},structNumV,numFrxProtocol,doseBinsC);
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
            correctedScaledDoseC = frxCorrectROE(modelC{j},structNumV,newNumFrx,scaledDoseBinsC);
            
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
              testDoseC = frxCorrectROE(modelC{j},structNumV,numFrxProtocol,doseBinsC);
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
        
            dispName = [ud.Protocols(p).protocol,': ',modelC{modIdxV(j)}.name];
            set(ud.NTCPCurve(ntcp),'DisplayName',dispName);
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
            
            dispName = [ud.Protocols(p).protocol,': ',modelC{j}.name];
            set(ud.NTCPCurve(ntcp),'DisplayName',dispName);
            hCurr = hNTCPAxis;
          elseif strcmp(modelC{j}.type,'TCP')
            tcp = tcp + 1;
            ud.TCPCurve = [ud.TCPCurve plot(hTCPAxis,xScaleV,scaledCPv,'linewidth',3,...
            'Color',plotColorM(colorIdx,:),'lineStyle',lineStyle)];
        
            dispName = [ud.Protocols(p).protocol,': ',modelC{j}.name];
            set(ud.TCPCurve(tcp),'DisplayName',dispName);
            hCurr = hTCPAxis;
          elseif strcmp(modelC{j}.type,'BED')
            bed = bed + 1;
            ud.BEDCurve = [ud.BEDCurve plot(hTCPAxis,xScaleV,scaledCPv,'linewidth',3,...
            'Color',plotColorM(colorIdx,:),'lineStyle',lineStyle)];
            dispName = [ud.Protocols(p).protocol,': ',modelC{j}.name];
            set(ud.BEDCurve(bed),'DisplayName',dispName);
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
            if isfield(critS.structures.(structC{m}),'abRatio')
              abRatio = critS.structures.(structC{m}).abRatio;
            else
              abRatio = [];
            end
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
                xV = get(ud.NTCPCurve(cProtocolStart(p)+cIdx),'XData');
                
                
                %Identify where limit is exceeded
                ntcpV = get(ud.NTCPCurve(cProtocolStart(p)+cIdx),'YData');
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
                    clr = [255 142 142]./255;
                    eclr = [114 76 76]./255;
                    addMarker = scatter(hNTCPAxis,cXv(cCount),...
                    cValV(cCount),60,'MarkerFaceColor',clr,...
                    'MarkerEdgeColor','k');
                    %addMarker.MarkerFaceAlpha = .3; %Transparency not supported
                    %addMarker.MarkerEdgeAlpha = .3; %Transparency not supported
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
                xV = get(ud.NTCPCurve(cProtocolStart(p)+1),'XData');
                
                %Idenitfy dose/volume limits
                cCount = cCount + 1;
                %nFrx = planC{indexS.dose}(plnNum).numFractions;
                [cScaleV(cCount),cValV(cCount)] = calcLimitROE(doseBinV,volHistV,strCritS.(criteriaC{n}),...
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
                'Color',[1 0 0],'LineStyle',':','Tag','criteria',...
                'Visible','Off'); 
                %'Color' transparency [1 0 0 alpha] not supported
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
                  xV = get(ud.NTCPCurve(gProtocolStart(p)+gIdx),'XData');
                  
                  %Identify where guideline is exceeded
                  ntcpV = get(ud.NTCPCurve(gProtocolStart(p)+gIdx),'YData');
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
                    if p==ud.foreground
                      clr = [239 197 57]./255;
                      ud.gMarker = [ud.cMarker,plot(hNTCPAxis,gXv(gCount),...
                      gValV(gCount),'o','MarkerSize',8,'MarkerFaceColor',...
                      clr,'MarkerEdgeColor','k')];
                    else
                      clr = [240 216 138]./255;
                      eclr = [127 114 72]./255;
                      addMarker = scatter(hNTCPAxis,gXv(gCount),...
                      gValV(gCount),60,'MarkerFaceColor',clr,...
                      'MarkerEdgeColor','k');
                      %addMarker.MarkerFaceAlpha = .3; %Transparency not supported
                      %addMarker.MarkerEdgeAlpha = .3; %Transparency not supported
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
                  xV = get(ud.NTCPCurve(gProtocolStart(p)+1),'XData');
                  %Idenitfy dose/volume limits
                  gCount = gCount + 1;
                  %nFrx = planC{indexS.dose}(plnNum).numFractions;
                  [gScaleV(gCount),gValV(gCount)] = calcLimitROE(doseBinV,volHistV,strGuideS.(guidelinesC{n}),...
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
    hLaby = ylabel(hNTCPAxis,'NTCP');
    set(hLaby,'Position',[0.47 0.5 -1])
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
    NTCPLegendC = arrayfun(@(x)get(x,'DisplayName'),ud.NTCPCurve,'un',0);
    
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
          BEDlegendC = arrayfun(@(x)get(x,'DisplayName'),ud.BEDCurve,'un',0);
          hax = [ud.NTCPCurve,ud.BEDCurve,constraintS.criteria(end),constraintS.guidelines(end)];
          key = [NTCPLegendC,BEDlegendC,'Clinical criteria','Clinical guidelines'];
        else
          BEDlegendC = arrayfun(@(x)get(x,'DisplayName'),ud.BEDCurve,'un',0);
          hax = [ud.NTCPCurve,ud.BEDCurve,constraintS.criteria(end)];
          key = [NTCPLegendC,BEDlegendC,'Clinical criteria'];
        end
      end
      legend(hax,key,'Location','northwest','Color','none','FontName',...
      'Arial','FontWeight','normal','FontSize',12,'AutoUpdate','off');
      
    else
      legend(ud.NTCPCurve,NTCPLegendC,...
      'Location','northwest','Color','none','FontName','Arial',...
      'FontWeight','normal','FontSize',12,'AutoUpdate','off');
    end
    
    %Store userdata
    ud.Protocols = protocolS;
    guidata(hFig,ud);
    
    %Display current dose/probability
    scaleDoseROE(hSlider,[],hFig);
    
    %Enable user-entered scale entry
    set(ud.handle.modelsAxis(10),'enable','On');
    
    %Get datacursor mode
    if ~isempty([protocolS.criteria])
      %cursorMode = datacursormode(hFig);
      %set(cursorMode,'Enable','On');
      
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
        
        cFirstX = get(hcFirst(1),'XData');
        gFirstX = get(hgFirst(1),'XData');
        if isempty(hcFirst) && isempty(hgFirst)
          %Skip
        elseif(~isempty(hcFirst) && isempty(hgFirst)) || cFirstX(1)<= gFirstX(1)
          %firstcViolation = [false(1:i1-1),firstcViolation];
          dttag = 'criteria';
          dispSelCriteriaROE([],[],hFig,dttag,firstcViolation,p);
          %hDatatip = cursorMode.createDatatip(hcFirst(1));
          %hDatatip.Marker = '^';
          %hDatatip.MarkerSize=7;
          %set(hDatatip,'Visible','On','OrientationMode','Manual',...
          %'UpdateFcn',@expandDataTip,'Tag',dttag);
        else
          %firstgViolation = [false(1:j1-1),firstgViolation];
          dttag = 'guidelines';
          dispSelCriteriaROE([],[],hFig,dttag,firstgViolation,p);
          %hDatatip = cursorMode.createDatatip(hgFirst(1));
          %hDatatip.Marker = '^';
          %hDatatip.MarkerSize=7;
          %set(hDatatip,'Visible','On','OrientationMode','Manual',...
          %'UpdateFcn',@expandDataTip,'Tag',dttag);
        end
        
      end
      
      %Set datacursor update function
      %set(cursorMode, 'Enable','On','SnapToDataVertex','off',...
      %'UpdateFcn',@expandDataTip);
      
    end
    
    
  case 'CLEAR_PLOT'
    ud = guidata(hFig);
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
      labObj = get(ud.handle.modelsAxis(ax),'children');
      if ~isempty(labObj)
        legend(ud.handle.modelsAxis(ax),'off')
      end
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
    %cursorMode = datacursormode(hFig);
    %cursorMode.removeAllDataCursors;
    %set(cursorMode, 'Enable','Off');
    
    %turn slider display off
    set(ud.handle.modelsAxis(7),'Visible','Off');
    set(ud.handle.modelsAxis(8),'Visible','Off');
    set(ud.handle.modelsAxis(10),'enable','Off');
    guidata(hFig,ud);
    
  case 'LIST_MODELS'
    %Get selected protocols
    ud = guidata(hFig);
    ud.handle.editModels = [];
    protocolS = ud.Protocols;
    currProtocol = get(gcbo,'Value') - 1;
    ud.PrtcNum = currProtocol;
    
    %Check models for required fields ('function' and 'parameter')
    modelC = protocolS(currProtocol).model;
    numModels = length(modelC);
    
    for i = 1:numModels
      
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
    
    modelListC = cellfun(@(x)x.name,protocolS(currProtocol).model,'un',0);
    set(ud.handle.inputH(10),'Enable','On'); %Plot button on
    set(ud.handle.inputH(14),'String',modelListC,'Visible','On','Enable','On');
    guidata(hFig,ud);
    getParamsROE(ud.handle.inputH(13),'INIT',hFig,planC);
    
  case 'SAVE_MODELS'
    ud = guidata(hFig);
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
    guidata(hFig,ud)
    
  case 'CLOSEREQUEST'
    
    closereq
    
  end
  end
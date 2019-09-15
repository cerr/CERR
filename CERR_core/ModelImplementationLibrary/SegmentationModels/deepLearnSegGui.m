function deepLearnSegGui(command,varargin)
% function deepLearnSegGui(command,varargin)
%
% GUI to choose and call deep-learning segmentation models.
%
% APA, 9/11/2019


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

% Get GUI fig handle
hFig = findobj('Tag','DLSegFig');

if ~isempty(hFig)
    ud = get(hFig,'userdata');
end

% Define GUI size, margins, position, color & title
leftMarginWidth = 300;
topMarginHeight = 60;
stateS.leftMarginWidth = leftMarginWidth;
stateS.topMarginHeight = topMarginHeight;
screenSizeV = get( 0, 'Screensize' );
GUIWidth = 800;
GUIHeight = 450;
shift = 10;
position = [(screenSizeV(3)-GUIWidth)/2,(screenSizeV(4)-GUIHeight)/2,GUIWidth,GUIHeight];
posTop = GUIHeight-topMarginHeight;
defaultColor = [0.8 0.9 0.9];
figColor = [.6 .75 .75];


switch upper(command)
    
    case 'INIT'
        %Initialize main GUI figure
        
        % Define GUI size, margins, position, color & title
        leftMarginWidth = 300;
        topMarginHeight = 60;
        stateS.leftMarginWidth = leftMarginWidth;
        stateS.topMarginHeight = topMarginHeight;
        screenSizeV = get( 0, 'Screensize' );
        GUIWidth = 800;
        GUIHeight = 450;
        shift = 10;
        position = [(screenSizeV(3)-GUIWidth)/2,(screenSizeV(4)-GUIHeight)/2,GUIWidth,GUIHeight];
        str1 = 'Deep-learning segmentation';
        defaultColor = [0.8 0.9 0.9];
        figColor = [.6 .75 .75];
        
        if isempty(hFig)
            
            % initialize main GUI figure
            hFig = figure('tag','DLSegFig','name',str1,...
                'numbertitle','off','position',position,...
                'CloseRequestFcn', 'deepLearnSegGui(''closeRequest'')',...
                'menubar','none','resize','off','color',figColor);
        else
            figure(findobj('tag','DLSegFig'))
            return
        end
        
        
        %Create title handles
        posTop = GUIHeight-topMarginHeight;
        titleH(1) = uicontrol(hFig,'tag','titleFrame','units','pixels',...
            'Position',[shift posTop-shift/2 GUIWidth-2*shift 0.08*GUIHeight ],'Style',...
            'frame','backgroundColor',defaultColor);
        titleH(2) = uicontrol(hFig,'tag','title','units','pixels',...
            'Position',[.3*GUIHeight+1 posTop-2 .6*GUIWidth 3*shift ],...
            'String','Deep-learning segmentation models','Style','text', 'fontSize',12,...
            'FontWeight','Bold','HorizontalAlignment','center',...
            'backgroundColor',defaultColor);
        
        ud.handle.title = titleH;
        set(hFig,'userdata',ud);
        deepLearnSegGui('refresh',hFig);
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
        
        % Build the list of models from ...\ModelImplementationLibrary\SegmentationModels\ModelConfigurations
        configDir = fullfile(getCERRPath,'ModelImplementationLibrary','SegmentationModels','ModelConfigurations');
        dirS = dir([configDir,filesep,'*.json']);
        configFileC = ['====== Select ======',{dirS(:).name}];

        
        %% Push button for protocol selection
        inputHandleS.titleFrame = uicontrol(hFig,'tag','titleFrame','units','pixels',...
            'Position',[shift shift leftMarginWidth+.12*GUIWidth GUIHeight-topMarginHeight-2*shift ],...
            'Style','frame','backgroundColor',defaultColor);
        inputHandleS.modelTitle = uicontrol(hFig,'tag','modelTitle','units','pixels',...
            'Position',[2*shift posTop-.16*GUIHeight .15*GUIWidth 2*shift],...
            'String','Model','Style','text',...
            'fontSize',9, 'fontWeight', 'Bold', 'BackgroundColor',defaultColor,...
            'HorizontalAlignment','right');
        inputHandleS.modelPopup = uicontrol(hFig,'tag','modelPopup','units','pixels',...
            'Position',[2*shift+.1*GUIWidth+65 posTop-.16*GUIHeight .26*GUIWidth 2.5*shift],...
            'String',configFileC,'Style','popupmenu',...
            'value',1,'fontSize',9, 'fontWeight', 'Bold', 'BackgroundColor',defaultColor,...
            'HorizontalAlignment','left','callback',...
            'deepLearnSegGui(''MODEL_SELECTED'')');
        inputHandleS.containerTitle = uicontrol(hFig,'tag','containerTitle','units','pixels',...
            'Position',[2*shift posTop-.25*GUIHeight .15*GUIWidth 2*shift],...
            'String','Container location','Style','text',...
            'fontSize',9, 'fontWeight', 'Bold', 'BackgroundColor',defaultColor,...
            'HorizontalAlignment','right');
        inputHandleS.containerPush = uicontrol(hFig,'tag','containerPush','units','pixels',...
            'Position',[2*shift+.1*GUIWidth+65 posTop-.25*GUIHeight .26*GUIWidth 2.5*shift], 'String','Browse','Style','push',...
            'fontSize',9, 'fontWeight', 'Bold', 'BackgroundColor',defaultColor,...
            'HorizontalAlignment','left','callback',...
            'deepLearnSegGui(''CONTAINER_SELECTED'')');
        inputHandleS.sessionTitle = uicontrol(hFig,'tag','sessionTitle','units','pixels',...
            'Position',[2*shift posTop-.35*GUIHeight .15*GUIWidth 2*shift],...
            'String','Session directory','Style','text',...
            'fontSize',9, 'fontWeight', 'Bold', 'BackgroundColor',defaultColor,...
            'HorizontalAlignment','right');
        inputHandleS.sessionPush = uicontrol(hFig,'tag','sessionPush','units','pixels',...
            'Position',[2*shift+.1*GUIWidth+65 posTop-.35*GUIHeight .26*GUIWidth 2.5*shift],...
            'String','Browse','Style','push',...
            'fontSize',9, 'fontWeight', 'Bold', 'BackgroundColor',defaultColor,...
            'HorizontalAlignment','left','callback',...
            'deepLearnSegGui(''SESSION_SELECTED'')');
        inputHandleS.modelConfigTitle = uicontrol(hFig,'tag','modelConfigTitle','units','pixels',...
            'Position',[2*shift posTop-.45*GUIHeight .15*GUIWidth 2*shift],...
            'String','Model configuration','Style','text',...
            'fontSize',9, 'fontWeight', 'Bold', 'BackgroundColor',defaultColor,...
            'HorizontalAlignment','right');
        inputHandleS.modelFileSelect = uicontrol(hFig,'tag','modelFileSelect','units','pixels',...
            'Position',[2*shift+.1*GUIWidth+65 posTop-.45*GUIHeight .05*GUIWidth 2.5*shift],...
            'String', 'View','Style','toggle', 'fontSize',10,...
            'FontWeight','normal','BackgroundColor',defaultColor,...
            'HorizontalAlignment','right','callback',...
            'deepLearnSegGui(''SHOW_JSON'',''MODEL_CONFIG'')');
        inputHandleS.sshTitle = uicontrol(hFig,'tag','sshTitle','units','pixels',...
            'Position',[2*shift posTop-.57*GUIHeight .15*GUIWidth 2*shift+20],...
            'String','SSH Connection (optional)','Style','text',...
            'fontSize',9, 'fontWeight', 'Bold', 'BackgroundColor',defaultColor,...
            'HorizontalAlignment','right');
        inputHandleS.sshFileSelect = uicontrol(hFig,'tag','sshFileSelect','units','pixels',...
            'Position',[2*shift+.1*GUIWidth+65 posTop-.55*GUIHeight .05*GUIWidth 2.5*shift],...
            'String','View','Style','toggle', 'fontSize',10,...
            'FontWeight','normal','BackgroundColor',defaultColor,...
            'HorizontalAlignment','right','callback',...
            'deepLearnSegGui(''SHOW_JSON'',''SSH'')');
        inputHandleS.runSegPush = uicontrol(hFig,'tag','runSegPush','units','pixels',...
            'Position',[2*shift+200 posTop-.75*GUIHeight .2*GUIWidth 3*shift], 'String',...
            'Run Segmentation','Style','push', 'fontSize',10,...
            'FontWeight','normal','BackgroundColor',defaultColor,...
            'HorizontalAlignment','right','callback',...
            'deepLearnSegGui(''RUN_SEGMENTATION'')');
        
%         %% Pop-up menus to select structures & dose plans
%         tablePosV = [.22*GUIWidth-2.5*shift posTop-.1*GUIHeight .22*GUIWidth 2.4*shift];
%         colWidth = tablePosV(3)/2-1;
%         inputH(4) = uitable(hFig,'Tag','strSel','Position',tablePosV-[0 2.5*shift 0 0],'Enable','Off',...
%             'cellEditCallback',@editParams,'ColumnName',[],'RowName',[],'Visible','Off',...
%             'backgroundColor',defaultColor,'columnEditable',[true,true],'Data',...
%             {'Select structure','List of structures'},'ColumnWidth',{colWidth,colWidth},'FontSize',10);
%         inputH(5) = uitable(hFig,'Tag','doseSel','Position',tablePosV,'Enable','Off',...
%             'cellEditCallback',@editParams,'ColumnName',[],'RowName',[],'Visible','Off',...
%             'backgroundColor',defaultColor,'columnEditable',[true,true],'Data',...
%             {'Select dose plan','List of plans'},'ColumnWidth',{colWidth,colWidth},'FontSize',10);
%         
%         %% Tables to display & edit model parameters
%         inputH(6) = uicontrol(hFig,'units','pixels','Visible','Off','fontSize',10,...
%             'Position',tablePosV + [0 -.1*GUIHeight 0 0 ],'String','Model parameters','Style','text',...
%             'FontWeight','Bold','HorizontalAlignment','Left','backgroundColor',defaultColor); %Title: Model parameters
%         inputH(7) = uicontrol(hFig,'units','pixels','Visible','Off','String','',...
%             'Position',tablePosV + [0 -.15*GUIHeight 0 0 ],'FontSize',10,'Style','text',...
%             'FontWeight','Bold','HorizontalAlignment','Left','backgroundColor',defaultColor,...
%             'foregroundColor',[.6 0 0]); %Model name display
%         inputH(8) = uitable(hFig,'Tag','fieldEdit','Position',tablePosV + [0 -.75*GUIHeight 0 8*shift],'Enable','Off',...
%             'cellEditCallback',@editParams,'ColumnName',{'Fields','Values'},'FontSize',10,...
%             'RowName',[],'Visible','Off','backgroundColor',defaultColor,...
%             'ColumnWidth',{round(tablePosV(3)/2),round(tablePosV(3)/2)},...
%             'columnEditable',[false,true],'backgroundcolor',[1 1 1]); %Parameter tables
%         
%         %% Push-buttons to save, plot, display style
%         inputH(9) = uicontrol(hFig,'units','pixels','Tag','saveJson','Position',[.36*GUIWidth 1.5*shift .06*GUIWidth 3*shift],'backgroundColor',defaultColor,...
%             'String','Save','Style','Push', 'fontSize',10,'FontWeight','normal','Enable','Off','Callback','deepLearnSegGui(''SAVE_MODELS'' )'); %Save
%         inputH(10) = uicontrol(hFig,'units','pixels','Tag','plotButton','Position',[.29*GUIWidth 1.5*shift .06*GUIWidth 3*shift],'backgroundColor',defaultColor,...
%             'String','Plot','Style','Push', 'fontSize',10,'FontWeight','normal','Enable','Off','Callback','deepLearnSegGui(''PLOT_MODELS'' )'); %plot
%         inputH(11) = uicontrol(hFig,'units','pixels','Tag','switchPlot','Position',[.18*GUIWidth .1*shift .1*GUIWidth 4*shift],'backgroundColor',[1 1 1],...
%             'String',{'--Display mode--','NTCP v.BED','NTCP v.TCP','Scale fraction size', 'Scale no. fractions' },'Style','popup', 'fontSize',10,'FontWeight','normal','Enable','On','Callback',@setPlotMode);
%         
%         
%         
%         
%         %Push-button for constraints panel
%         plotH(9) = uicontrol('parent',hFig,'units','pixels','Position',...
%             [GUIWidth-17*shift 1.5*shift 15*shift 3*shift],...
%             'Style','push','Enable','On','String','Save',...
%             'backgroundColor',[192 205 230]./255,'fontSize',10,...
%             'Callback',{@critPanel,'INIT'});
%         
       
        
        %Turn off datacursor mode
        cursorMode = datacursormode(hFig);
        cursorMode.removeAllDataCursors;
        set(cursorMode, 'Enable','Off');
        
        %% Store handles
        ud.inputHandleS = inputHandleS;
        ud.modelConfigDir = configDir;
        set(hFig,'userdata',ud);
        
                
    case 'CLOSEREQUEST'
        
        closereq
        
    case 'MODEL_SELECTED'
        ud.modelIndex = get(ud.inputHandleS.modelPopup,'value');
        modelC = get(ud.inputHandleS.modelPopup,'string');
        ud.modelConfigFile = fullfile(ud.modelConfigDir,modelC{ud.modelIndex});
        ud.modelConfigS = loadjson(ud.modelConfigFile,'ShowProgress',1);
        set(hFig,'userdata',ud);
        
    case 'CONTAINER_SELECTED'
        [containerFile,containerPath] = uigetfile();
        ud.containerPath = fullfile(containerPath,containerFile);
        set(ud.inputHandleS.containerPush,'string',containerFile);
        set(hFig,'userdata',ud);        
        
    case 'SESSION_SELECTED'
        ud.sessionDir = uigetdir();
        [~,sessDir] = fileparts(ud.sessionDir);
        set(ud.inputHandleS.sessionPush,'string',sessDir);
        set(hFig,'userdata',ud);
        
    case 'SHOW_JSON'
        cropS = ud.modelConfigS.crop;
        
        jsonTitle = uicontrol(hFig','units','pixels',...
            'Position',[4*shift+380 posTop-.1*GUIHeight .2*GUIWidth+200 3*shift],...
            'String','Region of interest selection','Style','text',...
            'fontSize',14, 'fontWeight', 'Bold', 'BackgroundColor',defaultColor,...
            'HorizontalAlignment','center');
        
        for i = 1:length(cropS)
            cropMethod = cropS(i).method;
            cropOperator = cropS(i).operator;
            displayOffset = 0;
            % Operator
            if i > 1
                cropHandleS(i).operator = uicontrol(hFig','units','pixels',...
                    'Position',[4*shift+400 posTop-.2*GUIHeight-(i-1)*displayOffset .2*GUIWidth+100 3*shift],...
                    'String',cropOperator,'Style','text',...
                    'fontSize',12, 'fontWeight', 'Bold', 'BackgroundColor',defaultColor,...
                    'HorizontalAlignment','center');
                displayOffset = displayOffset + 3*shift;
            end
            % Method
            cropHandleS(i).method = uicontrol(hFig','units','pixels',...
                'Position',[4*shift+400 posTop-.2*GUIHeight-(i-1)*displayOffset .2*GUIWidth+100 3*shift],...
                'String',cropMethod,'Style','text',...
                'fontSize',12, 'fontWeight', 'Bold', 'BackgroundColor',defaultColor,...
                'HorizontalAlignment','left');
            displayOffset = displayOffset + 3*shift;
            % Parameters
            paramC = [fieldnames(cropS(i).params), struct2cell(cropS(i).params)];
            colWidth = .2*GUIWidth+150;
            colWidth = colWidth / 2;
            cropHandleS(i).parameters = uitable(hFig,'Tag','fieldEdit',...
                'units','pixels',...
                'Position',[4*shift+400 posTop-0.35*GUIHeight-(i-1)*displayOffset .2*GUIWidth+150 3*shift+40],...
                'Enable','on',...
                'cellEditCallback',@editParams,'ColumnName',{'Fields','Values'},'FontSize',10,...
                'RowName',[],'Visible','on','backgroundColor',defaultColor,...
                'ColumnWidth',{colWidth,colWidth},...
                'columnEditable',[false,true],'backgroundcolor',[1 1 1],...
                'data',paramC); %Parameter tables
            %'ColumnWidth',{round(tablePosV(3)/2),round(tablePosV(3)/2)},.
            displayOffset = displayOffset + 3*shift + 40;
        end
        ud.jsonHandleS.cropHandleS = cropHandleS;
        ud.jsonHandleS.title = jsonTitle;
        set(hFig,'userdata',ud);          

end



% 
% %% Load JSON file
% protocolInfoS = loadjson(fullfile(protocolPath,protocolListC{protocolIdx(p)}),'ShowProgress',1);
% %Load .json for protocol
% modelListC = fields(protocolInfoS.models);                     %Get list of relevant models
% numModels = numel(modelListC);
% protocolS(p).modelFiles = [];
% uProt = uitreenode('v0',protocol,protocolInfoS.name,[],false); %Create nodes for protocols
% for m = 1:numModels
%     protocolS(p).protocol = protocolInfoS.name;
%     modelFPath = fullfile(modelPath,protocolInfoS.models.(modelListC{m}).modelFile);
%     %Get path to .json for model
%     protocolS(p).model{m} = loadjson(modelFPath,'ShowProgress',1);
%     %Load model parameters from .json file
%     protocolS(p).modelFiles = [protocolS(p).modelFiles,modelFPath];
%     modelName = protocolS(p).model{m}.name;
%     uProt.add(uitreenode('v0', modelName,modelName, [], true));%Create nodes for models
% end
% protocolS(p).numFractions = protocolInfoS.numFractions;
% protocolS(p).totalDose = protocolInfoS.totalDose;
% root.add(uProt);                                               %Add protocol to tree
% 
% 
% %% Save JSON file
% fprintf('\nSaving changes to %s ...',outFile{m});
% savejson('',modelConfigS,'filename',outFile{m});
% 
% 

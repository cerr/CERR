function deepLearnSegGui(command,varargin)
% function deepLearnSegGui(command,varargin)
%
% GUI for deep-learning segmentation models.
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
%hFig = findobj('Tag','DLSegFig');
hFig = stateS.handle.deepLearnSegFig;

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
            stateS.handle.deepLearnSegFig = hFig;
            
        else
            % figure(findobj('tag','DLSegFig'))
            figure(hFig)
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
        
        ud = get(hFig,'userdata');
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
        
        
        % frame title
        inputHandleS.titleFrame = uicontrol(hFig,'tag','titleFrame','units','pixels',...
            'Position',[shift shift leftMarginWidth+.12*GUIWidth GUIHeight-topMarginHeight-2*shift ],...
            'Style','frame','backgroundColor',defaultColor);
        
        % model title
        inputHandleS.modelTitle = uicontrol(hFig,'tag','modelTitle','units','pixels',...
            'Position',[1.2*shift posTop-.16*GUIHeight .18*GUIWidth 2.5*shift],...
            'String','Model','Style','text',...
            'fontSize',9, 'fontWeight', 'Bold', 'BackgroundColor',defaultColor,...
            'HorizontalAlignment','right');        
        % model popup
        inputHandleS.modelPopup = uicontrol(hFig,'tag','modelPopup','units','pixels',...
            'Position',[2*shift+.1*GUIWidth+65 posTop-.16*GUIHeight .26*GUIWidth 2.5*shift],...
            'String',configFileC,'Style','popupmenu',...
            'value',1,'fontSize',9, 'fontWeight', 'Bold', 'BackgroundColor',defaultColor,...
            'HorizontalAlignment','left','callback',...
            'deepLearnSegGui(''MODEL_SELECTED'')');
        
        % container title
        inputHandleS.containerTitle = uicontrol(hFig,'tag','containerTitle','units','pixels',...
            'Position',[1.2*shift posTop-.25*GUIHeight .18*GUIWidth 2.5*shift],...
            'String','Container location','Style','text',...
            'fontSize',9, 'fontWeight', 'Bold', 'BackgroundColor',defaultColor,...
            'HorizontalAlignment','right');
        % container push
        inputHandleS.containerPush = uicontrol(hFig,'tag','containerPush','units','pixels',...
            'Position',[2*shift+.1*GUIWidth+65 posTop-.25*GUIHeight .26*GUIWidth 2.5*shift], 'String','Browse','Style','push',...
            'fontSize',9, 'fontWeight', 'Bold', 'BackgroundColor',defaultColor,...
            'HorizontalAlignment','left','callback',...
            'deepLearnSegGui(''CONTAINER_SELECTED'')');
        
        % session title
        inputHandleS.sessionTitle = uicontrol(hFig,'tag','sessionTitle','units','pixels',...
            'Position',[1.2*shift posTop-.35*GUIHeight .18*GUIWidth 2.5*shift],...
            'String','Session directory','Style','text',...
            'fontSize',9, 'fontWeight', 'Bold', 'BackgroundColor',defaultColor,...
            'HorizontalAlignment','right');
        % session push
        inputHandleS.sessionPush = uicontrol(hFig,'tag','sessionPush','units','pixels',...
            'Position',[2*shift+.1*GUIWidth+65 posTop-.35*GUIHeight .26*GUIWidth 2.5*shift],...
            'String','Browse','Style','push',...
            'fontSize',9, 'fontWeight', 'Bold', 'BackgroundColor',defaultColor,...
            'HorizontalAlignment','left','callback',...
            'deepLearnSegGui(''SESSION_SELECTED'')');
        
        % model config title
        inputHandleS.modelConfigTitle = uicontrol(hFig,'tag','modelConfigTitle','units','pixels',...
            'Position',[1.2*shift posTop-.45*GUIHeight .18*GUIWidth 2.5*shift],...
            'String','Region Of Interest','Style','text',...
            'fontSize',9, 'fontWeight', 'Bold', 'BackgroundColor',defaultColor,...
            'HorizontalAlignment','right');
        % model config json show
        inputHandleS.modelFileSelect = uicontrol(hFig,'tag','modelFileSelect','units','pixels',...
            'Position',[2*shift+.1*GUIWidth+65 posTop-.45*GUIHeight .05*GUIWidth 2.5*shift],...
            'String', 'View','Style','toggle', 'fontSize',10,...
            'FontWeight','normal','BackgroundColor',defaultColor,...
            'HorizontalAlignment','right','callback',...
            'deepLearnSegGui(''SHOW_JSON'',''MODEL_CONFIG'')');
        
        % batch size title
        inputHandleS.batchTitle = uicontrol(hFig,'tag','batchSizeTitle','units','pixels',...
            'Position',[1.2*shift posTop-.55*GUIHeight .18*GUIWidth 2.5*shift],...
            'String','Batch size','Style','text',...
            'fontSize',9, 'fontWeight', 'Bold', 'BackgroundColor',defaultColor,...
            'HorizontalAlignment','right');
        % batch size edit        
        inputHandleS.batchSizeEdit = uicontrol(hFig,'tag','batchSizeEdit','units','pixels',...
            'Position',[2*shift+.1*GUIWidth+65 posTop-.55*GUIHeight .05*GUIWidth 2.5*shift],...
            'String','','Style','edit', 'fontSize',10,...
            'FontWeight','bold',...
            'HorizontalAlignment','center','callback',...
            'deepLearnSegGui(''BATCH_SIZE_CHANGED'')');
        
        % SSH options title
        inputHandleS.sshTitle = uicontrol(hFig,'tag','sshTitle','units','pixels',...
            'Position',[1.2*shift posTop-.67*GUIHeight .18*GUIWidth 2*shift+20],...
            'String','SSH Connection (optional)','Style','text',...
            'fontSize',9, 'fontWeight', 'Bold', 'BackgroundColor',defaultColor,...
            'HorizontalAlignment','right');
        % SSH options json show
        inputHandleS.sshFileSelect = uicontrol(hFig,'tag','sshFileSelect','units','pixels',...
            'Position',[2*shift+.1*GUIWidth+65 posTop-.65*GUIHeight .05*GUIWidth 2.5*shift],...
            'String','View','Style','toggle', 'fontSize',10,...
            'FontWeight','normal','BackgroundColor',defaultColor,...
            'HorizontalAlignment','right','callback',...
            'deepLearnSegGui(''SHOW_JSON'',''SSH'')');
        
        % Run segmentation
        inputHandleS.runSegPush = uicontrol(hFig,'tag','runSegPush','units','pixels',...
            'Position',[2*shift+200 posTop-.75*GUIHeight .2*GUIWidth 3*shift], 'String',...
            'Run Segmentation','Style','push', 'fontSize',10,...
            'FontWeight','normal','BackgroundColor',defaultColor,...
            'HorizontalAlignment','right','callback',...
            'deepLearnSegGui(''RUN_SEGMENTATION'')');
        
        %Push-button for saving json
        jsonSaveConfigH = uicontrol('parent',hFig,'units','pixels','Position',...
            [GUIWidth-17*shift 1.5*shift 15*shift 3*shift],...
            'Style','push','Enable','On','String','Save',...
            'backgroundColor',[192 205 230]./255,'fontSize',10,...
            'visible','off','Callback','deepLearnSegGui(''SAVE_JSON'')');        
        
        %Turn off datacursor mode
        cursorMode = datacursormode(hFig);
        cursorMode.removeAllDataCursors;
        set(cursorMode, 'Enable','Off');
        
        %% Store handles
        ud = get(hFig,'userdata');
        ud.inputHandleS = inputHandleS;
        ud.jsonHandleS.saveConfig = jsonSaveConfigH;
        ud.modelConfigDir = configDir;
        set(hFig,'userdata',ud);
        
        
    case 'CLOSEREQUEST'
        stateS.handle.deepLearnSegFig = [];
        closereq
        
    case 'MODEL_SELECTED'
        ud = get(hFig,'userdata');
        
        %Clear previously displayed objects
        if isfield(ud.jsonHandleS,'cropHandleS')
            for n = 1:length(ud.jsonHandleS.cropHandleS)
                delete(ud.jsonHandleS.cropHandleS(n).method);
            end
            
            for n = 1:length(ud.jsonHandleS.cropHandleS)
                if isfield(ud.jsonHandleS.cropHandleS(n),'operator')
                    delete(ud.jsonHandleS.cropHandleS(n).operator);
                end
            end
            
            for n = 1:length(ud.jsonHandleS.cropHandleS)
                delete(ud.jsonHandleS.cropHandleS(n).parameters);
            end
            
            ud.jsonHandleS.cropHandleS = [];
            delete(ud.jsonHandleS.title);
            delete(ud.jsonHandleS.frame);
            ud.cropS = [];
        end
        set(ud.jsonHandleS.saveConfig,'visible','off')

        ud.modelIndex = get(ud.inputHandleS.modelPopup,'value');
        modelC = get(ud.inputHandleS.modelPopup,'string');
        ud.modelConfigFile = fullfile(ud.modelConfigDir,modelC{ud.modelIndex});
        ud.modelConfigS = loadjson(ud.modelConfigFile,'ShowProgress',1);
        if isfield(ud.modelConfigS,'batchSize')
            set(ud.inputHandleS.batchSizeEdit,'value',ud.modelConfigS.batchSize);
        end
        set(hFig,'userdata',ud);
        
    case 'CONTAINER_SELECTED'
        ud = get(hFig,'userdata');
        [containerFile,containerPath] = uigetfile('*.sif');
        ud.containerPath = fullfile(containerPath,containerFile);
        set(ud.inputHandleS.containerPush,'string',containerFile);
        set(hFig,'userdata',ud);
        
    case 'SESSION_SELECTED'
        ud = get(hFig,'userdata');
        ud.sessionDir = uigetdir();
        [~,sessDir] = fileparts(ud.sessionDir);
        set(ud.inputHandleS.sessionPush,'string',sessDir);
        set(hFig,'userdata',ud);
        
    case 'BATCH_SIZE_CHANGED'
        ud = get(hFig,'userdata');
        batchSize = str2double(get(ud.inputHandleS.batchSizeEdit,'string'));
        if ~isempty(batchSize)
            if floor(batchSize)==batchSize
                deepLearnSegGui('SAVE_JSON','BATCH SIZE')
                ud.modelConfigS.batchSize = batchSize;
            end            
        end
        
    case 'SHOW_JSON'
        ud = get(hFig,'userdata');
        cropS = ud.modelConfigS.crop;
        
        jsonTitle = uicontrol(hFig','units','pixels',...
            'Position',[4*shift+380 posTop-.1*GUIHeight .2*GUIWidth+200 3*shift],...
            'String','Region of interest selection','Style','text',...
            'fontSize',12, 'fontWeight', 'Bold', 'BackgroundColor',defaultColor,...
            'HorizontalAlignment','center');
        
        jsonFrame = uicontrol(hFig,'units','pixels',...
            'Position',[GUIWidth/2+shift shift leftMarginWidth+.1*GUIWidth GUIHeight-topMarginHeight-2*shift ],...,...
            'Style','frame','backgroundColor',defaultColor);
        
        %Get list of available structures
        indexS = planC{end};
        structListC = {planC{indexS.structures}.structureName};
        
        %Display user-selectable fields
        indToShowV = 1:length(cropS);
        displayOffset = 0;
        
        for i = 1:length(indToShowV)
            
            %Get crop methods and operators
            ind = indToShowV(i);
            cropMethod = cropS(ind).method;
            cropOperator = cropS(ind).operator;
            
            if ~isempty(cropOperator)
                cropHandleS(i).operator = uicontrol(hFig','units','pixels',...
                    'Position',[4*shift+400 posTop-.15*GUIHeight-displayOffset 100 3*shift],...
                    'String',['( ',cropOperator,' )'],'Style','text',...
                    'fontSize',10,'fontWeight', 'Bold', 'BackgroundColor',defaultColor,...
                    'HorizontalAlignment','left');
                displayOffset = displayOffset + 3*shift;
            end
            cropHandleS(i).method = uicontrol(hFig','units','pixels',...
                'Position',[4*shift+400 posTop-.15*GUIHeight-displayOffset 100 3*shift],...
                'String',cropMethod,'Style','text',...
                'fontSize',10,'fontWeight', 'Bold', 'BackgroundColor',defaultColor,...
                'HorizontalAlignment','left');
            
            cropUdS.index = ind;

            % Get user-input parameters
            %             cropHandleS(i).parameters = uitable(hFig,'Tag','fieldEdit',...
            %                 'units','pixels',...
            %                 'Position',[4*shift+400 posTop-0.35*GUIHeight-displayOffset .2*GUIWidth+150 3*shift+40],...
            %                 'Enable','on',...
            %                 'cellEditCallback','deepLearnSegGui(''EDIT_JSON'')','ColumnName',{'Fields','Values'},'FontSize',10,...
            %                 'RowName',[],'Visible','on','backgroundColor',defaultColor,...
            %                 'ColumnWidth',{colWidth,colWidth},...
            %                 'columnEditable',[false,true],'backgroundcolor',[1 1 1],...
            %                 'data',paramC,'userdata',cropUdS);
            
            %Display pop-up list for selection
            %paramC
            posV = get(cropHandleS(i).method,'Position');
            paramPosV = posV;
            paramPosV(1) = posV(1)+posV(3)+shift;
            paramPosV(2) = posV(2);%+shift/2;
            paramPosV(3) = paramPosV(3) + 50;
            cropHandleS(i).parameters = uicontrol(hFig,'Position',...
                paramPosV,'style','popup','string',...
                ['Select',structListC],'callback',...
                'deepLearnSegGui(''EDIT_JSON'')','userdata',cropUdS);
            
            strNum = getMatchingIndex(cropS(i).params.structureName,structListC,'EXACT');
            if ~isempty(strNum)
                set(cropHandleS(i).parameters,'Value',strNum+1);
            end
            
            
            displayOffset = displayOffset + 3*shift;
            
        end
        
        set(ud.jsonHandleS.saveConfig,'visible','on')
        ud.jsonHandleS.cropHandleS = cropHandleS;
        ud.jsonHandleS.title = jsonTitle;
        ud.jsonHandleS.frame = jsonFrame;
        ud.cropS = cropS;
        set(ud.jsonHandleS.saveConfig,...
            'callback','deepLearnSegGui(''SAVE_JSON'',''CROP'')') % change as per file type
        set(hFig,'userdata',ud);
        
    case 'EDIT_JSON'
        ud = get(hFig,'userdata');
        hObj = gcbo;
        
        cropUdS = get(hObj,'userdata');
        ind = cropUdS.index;
        
        indexS = planC{end};
        strC = {planC{indexS.structures}.structureName};
        strIdx = get(hObj,'value')-1;
        
        if strIdx>0
        strName = strC{strIdx};
        ud.cropS(ind).params.structureName = strName;
        set(hFig,'userdata',ud);
        end
        
    case 'SAVE_JSON'
        ud = get(hFig,'userdata');
        saveOption = varargin{1};
        switch upper(saveOption)
            case 'BATCH SIZE'
                batchSize = str2double(get(ud.inputHandleS.batchSizeEdit,'string'));
                ud.modelConfigS.batchSize = batchSize;
            case 'CROP'
                ud.modelConfigS.crop = ud.cropS;
        end
        fprintf('\nSaving changes to %s ...',ud.modelConfigFile);
        %savejson('',ud.modelConfigS,'filename',ud.modelConfigFile); %
        %uncomment for production
        
    case 'RUN_SEGMENTATION'
        ud = get(hFig,'userdata');
        clientSessionPath = ud.sessionDir;
        [~,fname] = fileparts(ud.modelConfigFile);
        algorithm = fname(1:end-7); % remove trailing _config
        sshConfigFile = [];
        containerPath = ud.containerPath;
        batchSize = str2double(get(ud.inputHandleS.batchSizeEdit,'string'));
        planC = runSegForPlanC(planC,clientSessionPath,algorithm,sshConfigFile,containerPath,batchSize);
        
end



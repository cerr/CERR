function status = checkInputStrROE(hFig,planC)
% function checkInputStrROE(hFig,planC)
% Display interface for structure selection/verification. 
% AI 08/11/22 

ud = guidata(hFig);
protocolS = ud.Protocols;
status = 0;

if isfield(ud.handle,'strCheckH') && isgraphics(ud.handle.strCheckH)

    hStrCheckFig = ud.handle.strCheckH;
    figure(hStrCheckFig);

else

    indexS = planC{end};
    strC = {planC{indexS.structures}.structureName};

    modelListC = {};
    reqStrC = {};
    selStrC = {};

    p = 1;
    modelsC = protocolS(p).model;
    for m = 1:length(modelsC)
        modelName = modelsC{m}.name;
        if ~isstruct(modelsC{m}.parameters.structures)
            %If model has no structure-specific parameters
            inputStructC = {modelsC{m}.parameters.structures};
        else
            inputStructC = fieldnames(modelsC{m}.parameters.structures);
        end
        modelListC = [modelListC,repmat({modelName},[1,...
            length(inputStructC)])];
        reqStrC = [reqStrC,inputStructC{:}];
        strIdxV = modelsC{m}.strNum;
        if all(strIdxV)
            selStrC = [selStrC,strC(strIdxV)];
        else
            numMissing = ~strIdxV;
            missingC = repmat({'Select structure'},[1,length(numMissing)]);
            selStrC = [selStrC,missingC];
        end
    end
    %end

    height = 400;
    width = 600;
    posV = get(hFig,'Position');
    color = get(hFig,'Color');
    strPosV = [posV(3)/2-width/2,posV(4)/2-height/2,width,height];

    hStrCheckFig = dialog('Name','Verify structure selection','Position',...
        strPosV,'Units','Pixels','Color',color);

    hControl(1) = uitable('Parent',hStrCheckFig,'Data',...
        [modelListC.',reqStrC.',selStrC.'],'ColumnEditable',[false true true],...
        'ColumnFormat',{'char','char',strC},'Units','Normalized','Position',...
        [0.03,0.1,0.94,0.88],'ColumnWidth',{192,170,200},'RowName',{},...
        'FontSize',10,'ColumnName',{'Model','Required structure',...
        'Selected structure'},'CellEditCallback',@(hObj,hEvt)getStrNum(hObj,...
        hEvt,hFig));
    hControl(2) = uicontrol('Parent',hStrCheckFig,'Style','Push','String','Done',...
        'Units','Normalized','Callback',@(hObj,hEvt)wrapUpFn(hObj,hEvt,hFig),...
        'Position',[0.88,0.01,0.1,0.07]);

    ud.handle.strCheckH = hStrCheckFig;
    waitfor(hStrCheckFig);
    status = 1;
    guidata(hFig,ud);
end

%% Callback functions
    function getStrNum(hObj,hEvt,hFig)

        idxV = hEvt.Indices;
        newData = hEvt.NewData;
        dataC = get(hObj,'Data');
        fmtC = get(hObj,'ColumnFormat');
        selStrNum = find(strcmp(fmtC{3},newData));

        modName = dataC(idxV(1),1);
        strName = dataC(idxV(1),2);

        userdata = guidata(hFig);
        protS = userdata.Protocols;

        for nProt = 1:length(protS)

            modelC = protS(nProt).model;
            modelNamesC = cellfun(@(x)x.name,modelC,'un',0);
            modelIdx = strcmp(modelNamesC,modName);
            if ~isstruct(modelC{modelIdx}.parameters.structures)
                %If model has no structure-specific parameters
                inputStrC = {modelC{modelIdx}.parameters.structures};
            else
                inputStrC = fieldnames(...
                    modelC{modelIdx}.parameters.structures);
            end
            strNumV = modelC{modelIdx}.strNum;
            matchIdx = strcmp(inputStrC,strName);
            modelC{modelIdx}.strNum(matchIdx) = selStrNum;
            protS(nProt).model = modelC;
        end

        userdata.Protocols = protS;
        guidata(hFig,userdata);
        status = 1;

    end


    function wrapUpFn(hObj,hEvt,hFig)

        userdata = guidata(hFig);
        protS = userdata.Protocols;

        for nProt = 1:length(protS)

            modelC = protS(nProt).model;

            %Display selected structures
            set(ud.handle.tab1H(3),'Enable','On');

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
                %msgbox(['Please select structures required for models '...
                % modList],'Selection required');
                dispMsg = sprintf(['No structure selected',...
                    ' for ',modList,'.\n Skip model(s)?']);
                missingSel = questdlg(['\fontsize{11}',dispMsg],...
                    'Missing structure','Yes','No',struct('Interpreter',...
                    'tex','Default','Yes'));
                if ~isempty(missingSel) && strcmp(missingSel,'Yes')
                    modelC(modNumV) = [];
                    protS(nProt).model = modelC;
                else
                    return
                end
            end
        end

        userdata.Protocols = protS;

        userdata.structsChecked = 1;
        userdata.handle.strCheckH = [];
        guidata(hFig,userdata);
        status = 1;
        closereq;
    end

end
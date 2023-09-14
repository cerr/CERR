function getParamsROE(hObj,hEvt,hFig,planC)
% Store ROE inputs to figure userdata

% AI 05/12/21

ud = guidata(hFig);
if ~isempty(hEvt)
    tree = hObj.getTree;
    currNode = hEvt.getCurrentNode;
end
indexS = planC{end};

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
        planIdx = ud.planNum -  1;
    else
        %User selection
        planIdx = 1;
        ud.planNum = [];
    end


    %Table for selecting dose plan
    hTab = ud.handle.tab1H(4);
    fmt = {'char' planListC};
    dosDat = {'Select dose plan',planListC{planIdx}};
    set(hTab,'ColumnFormat',fmt,'Data',dosDat,'Visible','On','Enable','On');
    ud.handle.tab1H(4) = hTab;
    guidata(hFig,ud);

    %Expand protocol node to list models
    tree.expandRow(tree.getSelectionRows);

    %Get default parameters (from JSON files for models)
    getParamsROE([],[],hFig,planC);

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
            hTab2 = ud.handle.tab1H(4);
            planDispC = get(hTab2,'ColumnFormat');
            txtDispC = get(hTab2,'Data');
            planListC = planDispC{2};
            set(hTab2,'Data',{txtDispC{1},planListC{planNum+1}});
            ud.handle.tab1H(4) = hTab2;
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
            guidata(hFig,ud);
            hPar = extractParamsROE(hFig,modelsC{modelNumV(s)},planC);
            ud = guidata(hFig);

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
                hTab1 = ud.handle.tab1H(3);
                fmtC = {structDispC.',structListC};

                if isfield(modelsC{modelNumV(s)},'inputStrNum')
                    inputStrNum = modelsC{modelNumV(s)}.inputStrNum;
                else
                    inputStrNum = 1;
                    modelsC{modelNumV(s)}.inputStrNum = inputStrNum;
                end
                strDat = {structDispC{inputStrNum},...
                    structListC{strIdxV(inputStrNum)+1}};
                set(hTab1,'ColumnFormat',fmtC,'Data',strDat,'Visible','On',...
                    'Enable','On');

                %Table2

                %Table3 : Miscellaneous fields from .json file (decomissioned)
                %hTab3 = ud.handle.tab1H(7);
                %set(hTab3,'Data',[fieldsC,cellfun(@num2str,valsC,'un',0)],...
                %    'Visible','On','Enable','On');

                %Parameters
                for r = 1:numel(hPar)
                    set(hPar(r),'Visible','On');
                end

                %Store tables to userdata
                ud.handle.tab1H(3) = hTab1;
                set(ud.handle.tab1H(5),'Visible','On'); %Parameters header
                set(ud.handle.tab1H(6),'String',['Current model:  ',modName],'Visible','On'); %Display name of currently selected model
                %ud.handle.tab1H(7) = hTab3; %decomissioned
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
        set(ud.handle.tab1H(8),'Enable','On');
    end
    ud.Protocols = protS;
    guidata(hFig,ud);
end

end